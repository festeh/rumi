import { getDb } from "$lib/db/connection";
import { createLogger } from "$lib/utils/logger";
import { fetchChanges } from "./client";
import { conflicts, type SyncConflict } from "./status";

const log = createLogger("SyncPull");

export interface PullResult {
  serverTime: string;
  changedNodeIds: Set<string>;
}

export async function pull(): Promise<PullResult | null> {
  const db = await getDb();

  // Get last sync timestamp
  const meta = await db.select<{ value: string }[]>(
    "SELECT value FROM sync_meta WHERE key = 'last_sync_at'",
  );
  const since = meta.length > 0 ? meta[0].value : undefined;

  log.info("pulling changes", { since: since ?? "full sync" });

  const changes = await fetchChanges(since);

  if (changes.nodes.length === 0 && changes.content.length === 0) {
    log.debug("no changes from server");
    await upsertSyncMeta(db, "last_sync_at", changes.server_time);
    return { serverTime: changes.server_time, changedNodeIds: new Set() };
  }

  log.info("applying changes", {
    nodes: changes.nodes.length,
    content: changes.content.length,
  });

  // Topological sort: parents before children (FK constraint)
  const nodeMap = new Map(changes.nodes.map((n) => [n.id, n]));
  const sortedNodes: typeof changes.nodes = [];
  const visited = new Set<string>();

  function visit(node: (typeof changes.nodes)[0]) {
    if (visited.has(node.id)) return;
    visited.add(node.id);
    if (node.parent_id && nodeMap.has(node.parent_id)) {
      visit(nodeMap.get(node.parent_id)!);
    }
    sortedNodes.push(node);
  }
  for (const node of changes.nodes) visit(node);

  // Apply node changes — upsert, but skip locally dirty rows
  const newConflicts: SyncConflict[] = [];

  for (const node of sortedNodes) {
    const local = await db.select<
      { is_dirty: number; deleted_at: string | null }[]
    >("SELECT is_dirty, deleted_at FROM fs_nodes WHERE id = $1", [node.id]);

    if (local.length > 0 && local[0].is_dirty === 1) {
      // Conflict: deleted on server but edited locally
      if (node.deleted_at && !local[0].deleted_at) {
        const localContent = await db.select<{ body: string }[]>(
          "SELECT body FROM fs_content WHERE node_id = $1",
          [node.id],
        );
        log.warn("conflict: deleted on server, edited locally", {
          id: node.id,
          path: node.path,
        });
        newConflicts.push({
          nodeId: node.id,
          nodeName: node.name,
          nodePath: node.path,
          type: "deleted_on_server",
          localBody: localContent[0]?.body ?? "",
        });
      } else {
        log.debug("skipping dirty node", { id: node.id, path: node.path });
      }
      continue;
    }

    if (local.length === 0) {
      // Insert new node from server
      await db.execute(
        `INSERT INTO fs_nodes (id, parent_id, type, name, path, sort_order, created_at, updated_at, deleted_at, is_dirty)
				 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 0)`,
        [
          node.id,
          node.parent_id,
          node.type,
          node.name,
          node.path,
          node.sort_order,
          node.created_at,
          node.updated_at,
          node.deleted_at,
        ],
      );
    } else {
      // Update existing node from server
      await db.execute(
        `UPDATE fs_nodes
				 SET parent_id = $1, type = $2, name = $3, path = $4, sort_order = $5,
					 created_at = $6, updated_at = $7, deleted_at = $8
				 WHERE id = $9`,
        [
          node.parent_id,
          node.type,
          node.name,
          node.path,
          node.sort_order,
          node.created_at,
          node.updated_at,
          node.deleted_at,
          node.id,
        ],
      );
    }
  }

  if (newConflicts.length > 0) {
    conflicts.update((existing) => [...existing, ...newConflicts]);
  }

  // Apply content changes — upsert, but skip locally dirty rows
  const changedNodeIds = new Set<string>();

  for (const content of changes.content) {
    const local = await db.select<{ is_dirty: number; body: string }[]>(
      "SELECT is_dirty, body FROM fs_content WHERE node_id = $1",
      [content.node_id],
    );

    if (local.length > 0 && local[0].is_dirty === 1) {
      log.debug("skipping dirty content", { node_id: content.node_id });
      continue;
    }

    if (local.length === 0) {
      await db.execute(
        `INSERT INTO fs_content (node_id, body, updated_at, is_dirty)
				 VALUES ($1, $2, $3, 0)`,
        [content.node_id, content.body, content.updated_at],
      );
      changedNodeIds.add(content.node_id);
    } else {
      // Skip echo-back: server returning bytes we already have triggers a
      // cascade (tree reload + openFile) that disrupts the on-screen keyboard
      // mid-edit on Android.
      if (local[0].body === content.body) continue;
      await db.execute(
        `UPDATE fs_content SET body = $1, updated_at = $2 WHERE node_id = $3`,
        [content.body, content.updated_at, content.node_id],
      );
      changedNodeIds.add(content.node_id);
    }
  }

  await upsertSyncMeta(db, "last_sync_at", changes.server_time);

  log.info("pull complete", {
    server_time: changes.server_time,
    changed: changedNodeIds.size,
  });
  return { serverTime: changes.server_time, changedNodeIds };
}

async function upsertSyncMeta(
  db: Awaited<ReturnType<typeof getDb>>,
  key: string,
  value: string,
): Promise<void> {
  await db.execute(
    `INSERT INTO sync_meta (key, value) VALUES ($1, $2)
		 ON CONFLICT(key) DO UPDATE SET value = $2`,
    [key, value],
  );
}
