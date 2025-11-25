import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class AudioService {
  static const String transcriptionUrl = String.fromEnvironment('TRANSCRIPTION_URL');
  static const int sampleRate = 16000;

  static void validateConfig() {
    if (transcriptionUrl.isEmpty) {
      throw StateError(
        'TRANSCRIPTION_URL not set. '
        'Build with: --dart-define=TRANSCRIPTION_URL=<url> '
        'or use: just run-linux',
      );
    }
  }

  final AudioRecorder _audioRecorder = AudioRecorder();

  bool get _isLinux => !kIsWeb && Platform.isLinux;
  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  Future<bool> requestPermissions() async {
    if (_isLinux) {
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
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Platform-specific format
      final RecordConfig config;
      final String filePath;

      if (_isAndroid) {
        // Android: Record directly as PCM S16LE
        filePath = '${directory.path}/audio_$timestamp.pcm';
        config = const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
        );
      } else {
        // Linux/other: Record as WAV (will convert to PCM before sending)
        filePath = '${directory.path}/audio_$timestamp.wav';
        config = const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: sampleRate,
          numChannels: 1,
        );
      }

      await _audioRecorder.start(config, path: filePath);
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

  /// Convert WAV file to raw PCM S16LE by stripping the 44-byte header
  Future<Uint8List> _wavToPcm(String wavPath) async {
    final file = File(wavPath);
    final bytes = await file.readAsBytes();

    // WAV header is typically 44 bytes
    // Skip the header and return raw PCM data
    if (bytes.length > 44) {
      return Uint8List.fromList(bytes.sublist(44));
    }
    return bytes;
  }

  Future<String> transcribeAudio(String filePath, {String languageCode = ''}) async {
    try {
      final url = '$transcriptionUrl/speak';
      print('🎤 [AudioService] Starting transcription...');
      print('🎤 [AudioService] Transcription URL: $url');
      print('🎤 [AudioService] Audio file path: $filePath');
      print('🎤 [AudioService] Language code: ${languageCode.isEmpty ? "auto" : languageCode}');

      // Check if file exists
      final file = File(filePath);
      final fileExists = await file.exists();
      final fileSize = fileExists ? await file.length() : 0;
      print('🎤 [AudioService] File exists: $fileExists');
      print('🎤 [AudioService] File size: $fileSize bytes');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(url),
      );

      // Prepare audio data based on platform
      if (_isLinux && filePath.endsWith('.wav')) {
        // Linux: Convert WAV to PCM before sending
        print('🎤 [AudioService] Converting WAV to PCM...');
        final pcmData = await _wavToPcm(filePath);
        print('🎤 [AudioService] PCM data size: ${pcmData.length} bytes');

        request.files.add(
          http.MultipartFile.fromBytes(
            'audio',
            pcmData,
            filename: 'audio.pcm',
          ),
        );
      } else {
        // Android: Send PCM directly
        request.files.add(
          await http.MultipartFile.fromPath('audio', filePath),
        );
      }

      // Add file format field
      request.fields['file_format'] = 'pcm_s16le_16';

      // Add language code if specified (not auto)
      if (languageCode.isNotEmpty) {
        request.fields['language_code'] = languageCode;
      }

      print('🎤 [AudioService] Sending request to $url...');
      print('🎤 [AudioService] Request fields: ${request.fields}');

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      print('🎤 [AudioService] Response status: ${streamedResponse.statusCode}');
      print('🎤 [AudioService] Response headers: ${streamedResponse.headers}');
      print('🎤 [AudioService] Response body: $responseBody');

      if (streamedResponse.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final transcribedText = jsonResponse['text'] ?? jsonResponse['transcribed_text'] ?? 'No transcription available';
        print('🎤 [AudioService] Transcription successful: $transcribedText');
        return transcribedText;
      } else {
        final errorMsg = 'Transcription failed: HTTP ${streamedResponse.statusCode}\nURL: $url\nResponse: $responseBody';
        print('❌ [AudioService] $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ [AudioService] Exception during transcription: $e');
      throw Exception('Error transcribing audio: $e');
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
