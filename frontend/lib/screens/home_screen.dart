import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/notes_provider.dart';
import '../services/audio_service.dart';
import '../services/asr_settings_provider.dart';
import '../widgets/note_card.dart';
import '../widgets/date_picker_widget.dart';
import '../theme/tokens.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';
import '../models/note.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AudioService _audioService = AudioService();
  List<Note>? _searchResults;
  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _recordingPath;

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
    _audioService.dispose();
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar with Calendar and Settings Buttons
            Padding(
            padding: EdgeInsets.all(Spacing.lg),
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
                    ),
                    onChanged: _performSearch,
                  ),
                ),
                SizedBox(width: Spacing.sm),
                IconButton(
                  icon: const Icon(Icons.today),
                  onPressed: () {
                    context.read<NotesProvider>().setSelectedDate(DateTime.now());
                  },
                  tooltip: 'Go to Today',
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                  ),
                ),
                SizedBox(width: Spacing.xs),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  tooltip: 'Settings',
                ),
              ],
            ),
          ),
          
          // Date Picker (only show when not searching)
          if (_searchResults == null) const DatePickerWidget(),
          if (_searchResults == null) SizedBox(height: Spacing.lg),
          if (_searchResults == null) Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

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
                      padding: EdgeInsets.all(Spacing.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: IconSizes.xxxl,
                            color: colorScheme.error,
                          ),
                          SizedBox(height: Spacing.lg),
                          Text(
                            'Connection Problem',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: Spacing.md),
                          Container(
                            padding: EdgeInsets.all(Spacing.md),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(Radii.md),
                              border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                            ),
                            child: SelectableText(
                              '${notesProvider.errorMessage}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          SizedBox(height: Spacing.xl),
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
                              SizedBox(width: Spacing.md),
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
                final notesToShow = _searchResults ?? notesProvider.notesForSelectedDate;

                return notesToShow.isEmpty
                    ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _searchResults != null
                                        ? Icons.search_off
                                        : Icons.note_add,
                                    size: IconSizes.xxxl,
                                    color: colorScheme.outline,
                                  ),
                                  SizedBox(height: Spacing.lg),
                                  Text(
                                    _searchResults != null
                                        ? 'No notes found'
                                        : 'No notes for this date',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                  SizedBox(height: Spacing.sm),
                                  if (_searchResults == null)
                                    Text(
                                      'Tap the + button to create your first note',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.outline,
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
                                padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
                                itemCount: notesToShow.length,
                                itemBuilder: (context, index) {
                                  return NoteCard(
                                    note: notesToShow[index],
                                    onTap: () => _openNoteEditor(notesToShow[index]),
                                    onDelete: () => _deleteNote(notesToShow[index]),
                                  );
                                },
                              ),
                            );
              },
            ),
          ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(left: Spacing.xxxl),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: _isTranscribing ? null : _toggleRecording,
              heroTag: 'mic_button',
              backgroundColor: _isRecording
                  ? colorScheme.error
                  : (_isTranscribing
                      ? colorScheme.outline
                      : colorScheme.secondary),
              child: _isTranscribing
                  ? SizedBox(
                      width: IconSizes.lg,
                      height: IconSizes.lg,
                      child: CircularProgressIndicator(
                        color: colorScheme.onSecondary,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(_isRecording ? Icons.stop : Icons.mic),
            ),
            SizedBox(width: Spacing.lg),
            FloatingActionButton(
              onPressed: _createNewNote,
              heroTag: 'new_note_button',
              child: const Icon(Icons.add),
            ),
          ],
        ),
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

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
      });

      try {
        final path = await _audioService.stopRecording();
        if (path != null && path.isNotEmpty) {
          // Transcribe the audio with selected language
          final languageCode = context.read<ASRSettingsProvider>().language.code;
          final transcribedText = await _audioService.transcribeAudio(
            path,
            languageCode: languageCode,
          );

          // Create and save the note immediately
          final selectedDate = context.read<NotesProvider>().selectedDate;
          final newNote = Note(
            title: '',
            content: transcribedText,
            date: selectedDate,
          );

          final savedNote = await context.read<NotesProvider>().createNote(newNote);

          setState(() {
            _isTranscribing = false;
          });

          // Open the already-saved note in the editor
          if (mounted && savedNote != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditorScreen(note: savedNote),
              ),
            );
          }
        } else {
          setState(() {
            _isTranscribing = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recording failed')),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isTranscribing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    } else {
      // Start recording
      try {
        final path = await _audioService.startRecording();
        if (path != null) {
          setState(() {
            _isRecording = true;
            _recordingPath = path;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to start recording')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}