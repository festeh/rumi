import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class AudioService {
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://localhost:8090',
  );

  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<bool> requestPermissions() async {
    if (!kIsWeb && Platform.isLinux) {
      return true;
    }
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String?> startRecording() async {
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }

    if (await _audioRecorder.hasPermission()) {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: filePath,
      );

      return filePath;
    }
    return null;
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }

  Future<bool> isRecording() async {
    return await _audioRecorder.isRecording();
  }

  Future<String> transcribeAudio(String filePath) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$backendUrl/speak'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('audio', filePath),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        return jsonResponse['text'] ?? jsonResponse['transcribed_text'] ?? 'No transcription available';
      } else {
        throw Exception('Transcription failed: HTTP ${streamedResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Error transcribing audio: $e');
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
