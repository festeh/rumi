import 'package:flutter/material.dart';
import '../models/note.dart';
import 'api_service.dart';

class NotesProvider extends ChangeNotifier {
  List<Note> _notes = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  List<Note> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  List<Note> get todayNotes {
    final today = DateTime.now();
    return _notes.where((note) {
      return note.date.year == today.year &&
             note.date.month == today.month &&
             note.date.day == today.day;
    }).toList();
  }

  List<Note> get notesForSelectedDate {
    return _notes.where((note) {
      return note.date.year == _selectedDate.year &&
             note.date.month == _selectedDate.month &&
             note.date.day == _selectedDate.day;
    }).toList();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> loadNotes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notes = await ApiService.getNotes();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadNotesForDate(DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final notesForDate = await ApiService.getNotesByDate(date);
      // Update the notes list with the fetched notes for the date
      _notes.removeWhere((note) => 
        note.date.year == date.year &&
        note.date.month == date.month &&
        note.date.day == date.day
      );
      _notes.addAll(notesForDate);
      _notes.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createNote(Note note) async {
    try {
      final newNote = await ApiService.createNote(note);
      _notes.add(newNote);
      _notes.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      final updatedNote = await ApiService.updateNote(note);
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = updatedNote;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await ApiService.deleteNote(id);
      _notes.removeWhere((note) => note.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<List<Note>> searchNotes(String query) async {
    try {
      return await ApiService.searchNotes(query);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}