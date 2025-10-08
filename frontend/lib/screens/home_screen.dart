import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notes_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/date_picker_widget.dart';
import 'note_editor_screen.dart';
import '../models/note.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Note>? _searchResults;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().loadNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
      });
      return;
    }

    final results = await context.read<NotesProvider>().searchNotes(query);
    setState(() {
      _searchResults = results;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search Bar with Calendar Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onChanged: _performSearch,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.today),
                  onPressed: () {
                    context.read<NotesProvider>().setSelectedDate(DateTime.now());
                  },
                  tooltip: 'Go to Today',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
          
          // Date Picker (only show when not searching)
          if (_searchResults == null) const DatePickerWidget(),
          
          // Notes List
          Expanded(
            child: Consumer<NotesProvider>(
              builder: (context, notesProvider, child) {
                if (notesProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (notesProvider.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connection Problem',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: SelectableText(
                              '${notesProvider.errorMessage}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  notesProvider.clearError();
                                  notesProvider.loadNotes();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {
                                  notesProvider.clearError();
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Dismiss'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Choose which notes to display
                List<Note> notesToShow;
                String title;

                if (_searchResults != null) {
                  notesToShow = _searchResults!;
                  title = 'Search Results (${_searchResults!.length})';
                } else {
                  notesToShow = notesProvider.notesForSelectedDate;
                  final selectedDate = notesProvider.selectedDate;
                  final isToday = _isToday(selectedDate);
                  title = isToday
                      ? 'Today\'s Notes (${notesToShow.length})'
                      : '${DateFormat('MMM dd, yyyy').format(selectedDate)} (${notesToShow.length})';
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: notesToShow.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _searchResults != null 
                                        ? Icons.search_off 
                                        : Icons.note_add,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchResults != null
                                        ? 'No notes found'
                                        : 'No notes for this date',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_searchResults == null)
                                    Text(
                                      'Tap the + button to create your first note',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                if (_searchResults == null) {
                                  await notesProvider.loadNotesForDate(
                                    notesProvider.selectedDate
                                  );
                                }
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                itemCount: notesToShow.length,
                                itemBuilder: (context, index) {
                                  return NoteCard(
                                    note: notesToShow[index],
                                    onTap: () => _openNoteEditor(notesToShow[index]),
                                    onDelete: () => _deleteNote(notesToShow[index]),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewNote,
        label: const Text('New Note'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  void _createNewNote() {
    final selectedDate = context.read<NotesProvider>().selectedDate;
    final newNote = Note(
      title: '',
      content: '',
      date: selectedDate,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: newNote),
      ),
    );
  }

  void _openNoteEditor(Note note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(note: note),
      ),
    );
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: Text('Are you sure you want to delete "${note.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (note.id != null) {
                  context.read<NotesProvider>().deleteNote(note.id!);
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}