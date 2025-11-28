package handlers

import (
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/pocketbase/pocketbase/core"
	"github.com/pocketbase/pocketbase/tools/types"
)

func formatDateTime(dt types.DateTime) interface{} {
	if dt.IsZero() {
		return nil
	}
	return dt.Time().Local().Format(time.RFC3339)
}

type NoteRequest struct {
	Title   string `json:"title"`
	Content string `json:"content"`
	Date    string `json:"date"`
}

func GetNotes(re *core.RequestEvent, app core.App) error {
	log.Printf("GetNotes: Starting to fetch notes")

	collection, err := app.FindCollectionByNameOrId("notes")
	if err != nil {
		log.Printf("GetNotes: Failed to find collection 'notes': %v", err)
		return re.JSON(500, map[string]string{"error": "Collection not found"})
	}

	log.Printf("GetNotes: Found collection 'notes', ID: %s", collection.Id)
	log.Printf("GetNotes: Collection fields: %+v", collection.Fields)

	records, err := app.FindRecordsByFilter(collection, "1=1", "-date", 0, 0)
	if err != nil {
		log.Printf("GetNotes: FindRecordsByFilter failed - Error: %v", err)
		log.Printf("GetNotes: Query details - Collection: %s, Filter: '1=1', Sort: '-date'", collection.Name)
		return re.JSON(500, map[string]string{"error": "Failed to fetch notes", "details": err.Error()})
	}

	log.Printf("GetNotes: Successfully fetched %d records", len(records))

	notes := make([]map[string]interface{}, 0)
	for _, record := range records {
		notes = append(notes, map[string]interface{}{
			"id":         record.Id,
			"title":      record.GetString("title"),
			"content":    record.GetString("content"),
			"date":       record.GetString("date"),
			"created_at": formatDateTime(record.GetDateTime("created")),
			"updated_at": formatDateTime(record.GetDateTime("updated")),
		})
	}

	return re.JSON(200, notes)
}

func GetNote(re *core.RequestEvent, app core.App) error {
	id := re.Request.PathValue("id")

	collection, err := app.FindCollectionByNameOrId("notes")
	if err != nil {
		return re.JSON(500, map[string]string{"error": "Collection not found"})
	}

	record, err := app.FindRecordById(collection, id)
	if err != nil {
		return re.JSON(404, map[string]string{"error": "Note not found"})
	}

	note := map[string]interface{}{
		"id":         record.Id,
		"title":      record.GetString("title"),
		"content":    record.GetString("content"),
		"date":       record.GetString("date"),
		"created_at": formatDateTime(record.GetDateTime("created")),
		"updated_at": formatDateTime(record.GetDateTime("updated")),
	}

	return re.JSON(200, note)
}

func CreateNote(re *core.RequestEvent, app core.App) error {
	var noteReq NoteRequest
	if err := json.NewDecoder(re.Request.Body).Decode(&noteReq); err != nil {
		return re.JSON(400, map[string]string{"error": "Invalid JSON"})
	}

	collection, err := app.FindCollectionByNameOrId("notes")
	if err != nil {
		return re.JSON(500, map[string]string{"error": "Collection not found"})
	}

	record := core.NewRecord(collection)
	record.Set("title", noteReq.Title)
	record.Set("content", noteReq.Content)

	if noteReq.Date == "" {
		record.Set("date", time.Now().Format("2006-01-02"))
	} else {
		record.Set("date", noteReq.Date)
	}

	if err := app.Save(record); err != nil {
		return re.JSON(500, map[string]string{"error": "Failed to create note"})
	}

	note := map[string]interface{}{
		"id":         record.Id,
		"title":      record.GetString("title"),
		"content":    record.GetString("content"),
		"date":       record.GetString("date"),
		"created_at": formatDateTime(record.GetDateTime("created")),
		"updated_at": formatDateTime(record.GetDateTime("updated")),
	}

	return re.JSON(201, note)
}

func UpdateNote(re *core.RequestEvent, app core.App) error {
	id := re.Request.PathValue("id")

	var noteReq NoteRequest
	if err := json.NewDecoder(re.Request.Body).Decode(&noteReq); err != nil {
		return re.JSON(400, map[string]string{"error": "Invalid JSON"})
	}

	collection, err := app.FindCollectionByNameOrId("notes")
	if err != nil {
		return re.JSON(500, map[string]string{"error": "Collection not found"})
	}

	record, err := app.FindRecordById(collection, id)
	if err != nil {
		return re.JSON(404, map[string]string{"error": "Note not found"})
	}

	record.Set("title", noteReq.Title)
	record.Set("content", noteReq.Content)
	record.Set("date", noteReq.Date)

	if err := app.Save(record); err != nil {
		return re.JSON(500, map[string]string{"error": "Failed to update note"})
	}

	note := map[string]interface{}{
		"id":         record.Id,
		"title":      record.GetString("title"),
		"content":    record.GetString("content"),
		"date":       record.GetString("date"),
		"created_at": formatDateTime(record.GetDateTime("created")),
		"updated_at": formatDateTime(record.GetDateTime("updated")),
	}

	return re.JSON(200, note)
}

func DeleteNote(re *core.RequestEvent, app core.App) error {
	id := re.Request.PathValue("id")

	collection, err := app.FindCollectionByNameOrId("notes")
	if err != nil {
		return re.JSON(500, map[string]string{"error": "Collection not found"})
	}

	record, err := app.FindRecordById(collection, id)
	if err != nil {
		return re.JSON(404, map[string]string{"error": "Note not found"})
	}

	if err := app.Delete(record); err != nil {
		return re.JSON(500, map[string]string{"error": "Failed to delete note"})
	}

	return re.NoContent(204)
}

func GetNotesByDate(re *core.RequestEvent, app core.App) error {
	dateStr := re.Request.PathValue("date")

	_, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		return re.JSON(400, map[string]string{"error": "Invalid date format. Use YYYY-MM-DD"})
	}

	collection, err := app.FindCollectionByNameOrId("notes")
	if err != nil {
		return re.JSON(500, map[string]string{"error": "Collection not found"})
	}

	filter := fmt.Sprintf("date ~ '%s'", dateStr)
	records, err := app.FindRecordsByFilter(collection, filter, "-created", 0, 0)
	if err != nil {
		return re.JSON(500, map[string]string{"error": "Failed to fetch notes"})
	}

	notes := make([]map[string]interface{}, 0)
	for _, record := range records {
		notes = append(notes, map[string]interface{}{
			"id":         record.Id,
			"title":      record.GetString("title"),
			"content":    record.GetString("content"),
			"date":       record.GetString("date"),
			"created_at": formatDateTime(record.GetDateTime("created")),
			"updated_at": formatDateTime(record.GetDateTime("updated")),
		})
	}

	return re.JSON(200, notes)
}

func SearchNotes(re *core.RequestEvent, app core.App) error {
	query := re.Request.URL.Query().Get("q")
	if query == "" {
		return re.JSON(400, map[string]string{"error": "Search query is required"})
	}

	collection, err := app.FindCollectionByNameOrId("notes")
	if err != nil {
		return re.JSON(500, map[string]string{"error": "Collection not found"})
	}

	escapedQuery := strings.ReplaceAll(query, "'", "''")
	filter := fmt.Sprintf("title ~ '%s' || content ~ '%s'", escapedQuery, escapedQuery)
	records, err := app.FindRecordsByFilter(collection, filter, "-date", 0, 0)
	if err != nil {
		return re.JSON(500, map[string]string{"error": "Failed to search notes"})
	}

	notes := make([]map[string]interface{}, 0)
	for _, record := range records {
		notes = append(notes, map[string]interface{}{
			"id":         record.Id,
			"title":      record.GetString("title"),
			"content":    record.GetString("content"),
			"date":       record.GetString("date"),
			"created_at": formatDateTime(record.GetDateTime("created")),
			"updated_at": formatDateTime(record.GetDateTime("updated")),
		})
	}

	return re.JSON(200, notes)
}