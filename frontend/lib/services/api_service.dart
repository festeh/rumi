import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/note.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080/api';
  
  static Future<List<Note>> getNotes() async {
    final response = await http.get(Uri.parse('$baseUrl/notes'));
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Note.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notes');
    }
  }

  static Future<Note> getNote(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/notes/$id'));
    
    if (response.statusCode == 200) {
      return Note.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load note');
    }
  }

  static Future<Note> createNote(Note note) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notes'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(note.toJson()),
    );
    
    if (response.statusCode == 201) {
      return Note.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create note');
    }
  }

  static Future<Note> updateNote(Note note) async {
    final response = await http.put(
      Uri.parse('$baseUrl/notes/${note.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(note.toJson()),
    );
    
    if (response.statusCode == 200) {
      return Note.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update note');
    }
  }

  static Future<void> deleteNote(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/notes/$id'));
    
    if (response.statusCode != 204) {
      throw Exception('Failed to delete note');
    }
  }

  static Future<List<Note>> getNotesByDate(DateTime date) async {
    final dateString = date.toIso8601String().substring(0, 10);
    final response = await http.get(Uri.parse('$baseUrl/notes/date/$dateString'));
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Note.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notes for date');
    }
  }

  static Future<List<Note>> searchNotes(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/search?q=${Uri.encodeComponent(query)}')
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Note.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search notes');
    }
  }
}