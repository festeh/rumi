import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/note.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8080/api',
  );
  
  static Future<List<Note>> getNotes() async {
    final url = '$baseUrl/notes';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        try {
          final List<dynamic> jsonList = json.decode(response.body);
          return jsonList.map((json) => Note.fromJson(json)).toList();
        } catch (e) {
          throw Exception('Failed to parse notes data from server. Response: ${response.body}');
        }
      } else {
        String errorMessage = 'Failed to load notes from $url\n';
        errorMessage += 'HTTP ${response.statusCode}: ${_getStatusMessage(response.statusCode)}\n';
        if (response.body.isNotEmpty) {
          errorMessage += 'Server response: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      throw Exception('Network error: Cannot connect to server at $url\n'
          'Please check:\n'
          '• Internet connection\n'
          '• Server is running\n'
          '• Backend URL is correct\n'
          'Details: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP error while connecting to $url\nDetails: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Invalid response format from $url\nDetails: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error while loading notes from $url\nDetails: $e');
    }
  }

  static Future<Note> getNote(String id) async {
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

  static Future<void> deleteNote(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/notes/$id'));

    if (response.statusCode != 204) {
      throw Exception('Failed to delete note');
    }
  }

  static Future<List<Note>> getNotesByDate(DateTime date) async {
    final dateString = date.toIso8601String().substring(0, 10);
    final url = '$baseUrl/notes/date/$dateString';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        try {
          final List<dynamic> jsonList = json.decode(response.body);
          return jsonList.map((json) => Note.fromJson(json)).toList();
        } catch (e) {
          throw Exception('Failed to parse notes data for date $dateString. Response: ${response.body}');
        }
      } else {
        String errorMessage = 'Failed to load notes for date $dateString from $url\n';
        errorMessage += 'HTTP ${response.statusCode}: ${_getStatusMessage(response.statusCode)}\n';
        if (response.body.isNotEmpty) {
          errorMessage += 'Server response: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      throw Exception('Network error: Cannot connect to server at $url\n'
          'Please check:\n'
          '• Internet connection\n'
          '• Server is running\n'
          '• Backend URL is correct\n'
          'Details: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP error while connecting to $url\nDetails: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Invalid response format from $url\nDetails: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error while loading notes for date $dateString from $url\nDetails: $e');
    }
  }

  static Future<List<Note>> searchNotes(String query) async {
    final url = '$baseUrl/search?q=${Uri.encodeComponent(query)}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        try {
          final List<dynamic> jsonList = json.decode(response.body);
          return jsonList.map((json) => Note.fromJson(json)).toList();
        } catch (e) {
          throw Exception('Failed to parse search results for "$query". Response: ${response.body}');
        }
      } else {
        String errorMessage = 'Failed to search notes for "$query" from $url\n';
        errorMessage += 'HTTP ${response.statusCode}: ${_getStatusMessage(response.statusCode)}\n';
        if (response.body.isNotEmpty) {
          errorMessage += 'Server response: ${response.body}';
        }
        throw Exception(errorMessage);
      }
    } on SocketException catch (e) {
      throw Exception('Network error: Cannot connect to server at $url\n'
          'Please check:\n'
          '• Internet connection\n'
          '• Server is running\n'
          '• Backend URL is correct\n'
          'Details: ${e.message}');
    } on HttpException catch (e) {
      throw Exception('HTTP error while searching at $url\nDetails: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Invalid response format from $url\nDetails: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error while searching for "$query" at $url\nDetails: $e');
    }
  }

  static String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad Request - Invalid request format';
      case 401:
        return 'Unauthorized - Authentication required';
      case 403:
        return 'Forbidden - Access denied';
      case 404:
        return 'Not Found - Endpoint does not exist';
      case 500:
        return 'Internal Server Error - Server malfunction';
      case 502:
        return 'Bad Gateway - Server gateway error';
      case 503:
        return 'Service Unavailable - Server temporarily down';
      case 504:
        return 'Gateway Timeout - Server response timeout';
      default:
        return 'Unexpected server response';
    }
  }
}