import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';
import '../services/notes_provider.dart';
import '../services/audio_service.dart';
import '../services/asr_settings_provider.dart';
import '../theme/tokens.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note note;

  const NoteEditorScreen({super.key, required this.note});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();
  final _audioService = AudioService();

  bool _hasChanges = false;
  bool _isSaving = false;
  bool _isRecording = false;
  bool _isTranscribing = false;
  DateTime _selectedDate = DateTime.now();

  // Store original values to detect actual changes
  late String _originalTitle;
  late String _originalContent;

  @override
  void initState() {
    super.initState();

    // Store original values
    _originalTitle = widget.note.title;
    _originalContent = widget.note.content;

    _titleController.text = _originalTitle;
    _contentController.text = _originalContent;
    _selectedDate = widget.note.date;

    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);

    // Auto-focus on content field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _contentFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _audioService.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasChanges = _titleController.text != _originalTitle ||
                       _contentController.text != _originalContent;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  void _onTextChanged() {
    _checkForChanges();
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final updatedNote = widget.note.copyWith(
      title: _titleController.text.trim(),
      content: _contentController.text,
      date: _selectedDate,
    );

    try {
      if (widget.note.id == null) {
        await context.read<NotesProvider>().createNote(updatedNote);
      } else {
        await context.read<NotesProvider>().updateNote(updatedNote);
      }
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving note: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) {
      return true;
    }

    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('Do you want to save your changes before leaving?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                _saveNote();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _handleEscape() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    final shouldPop = await _onWillPop();
    if (shouldPop && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording and transcribe
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
      });

      try {
        final filePath = await _audioService.stopRecording();
        if (filePath != null) {
          final languageCode = context.read<ASRSettingsProvider>().language.code;
          final transcription = await _audioService.transcribeAudio(
            filePath,
            languageCode: languageCode,
          );

          // Insert transcription at cursor position or append to content
          final currentText = _contentController.text;
          final selection = _contentController.selection;
          final newText = currentText.replaceRange(
            selection.start,
            selection.end,
            transcription,
          );

          _contentController.text = newText;
          _contentController.selection = TextSelection.collapsed(
            offset: selection.start + transcription.length,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isTranscribing = false;
          });
        }
      }
    } else {
      // Start recording
      try {
        await _audioService.startRecording();
        setState(() {
          _isRecording = true;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error starting recording: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
          _handleEscape();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
        appBar: AppBar(
          title: Text(widget.note.id == null ? 'New Note' : 'Edit Note'),
          actions: [
            if (_isTranscribing)
              Padding(
                padding: EdgeInsets.all(Spacing.lg),
                child: SizedBox(
                  width: IconSizes.md,
                  height: IconSizes.md,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: _isRecording ? colorScheme.error : null,
                ),
                onPressed: _toggleRecording,
                tooltip: _isRecording ? 'Stop Recording' : 'Start Recording',
              ),
            if (_isSaving)
              Padding(
                padding: EdgeInsets.all(Spacing.lg),
                child: SizedBox(
                  width: IconSizes.md,
                  height: IconSizes.md,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _hasChanges ? _saveNote : null,
                child: const Text('Save'),
              ),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date selector
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(Radii.md),
                child: Container(
                  padding: EdgeInsets.all(Spacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: colorScheme.primary,
                      ),
                      SizedBox(width: Spacing.md),
                      Text(
                        DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_drop_down,
                        color: colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: Spacing.lg),

              // Title field
              TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Note title...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _contentFocusNode.requestFocus(),
              ),

              const Divider(),

              // Content field
              Expanded(
                child: TextField(
                  controller: _contentController,
                  focusNode: _contentFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Start writing your note...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: null,
                  expands: true,
                  textCapitalization: TextCapitalization.sentences,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _hasChanges
            ? Container(
                padding: EdgeInsets.all(Spacing.lg),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: IconSizes.sm,
                      color: colorScheme.primary,
                    ),
                    SizedBox(width: Spacing.sm),
                    Text(
                      'Unsaved changes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saveNote,
                      child: const Text('Save Now'),
                    ),
                  ],
                ),
              )
            : null,
        ),
      ),
    );
  }
}