import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:memory_pins_app/services/aws_service.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AWSService _awsService = AWSService();

  bool _isRecording = false;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;

  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;

  /// Start recording audio
  Future<void> startRecording() async {
    try {
      // Check permissions
      if (!await _audioRecorder.hasPermission()) {
        throw Exception('Microphone permission not granted');
      }

      // Get temporary directory for recording
      final tempDir = await getTemporaryDirectory();
      final fileName = 'AUDIO_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _currentRecordingPath = '${tempDir.path}/$fileName';

      // Start recording
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingDuration = Duration.zero;

      // Start duration timer
      _startDurationTimer();

      print('Started recording at: $_currentRecordingPath');
    } catch (e) {
      print('Error starting recording: $e');
      rethrow;
    }
  }

  /// Stop recording audio
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        return null;
      }

      // Stop recording
      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path != null && path.isNotEmpty) {
        _currentRecordingPath = path;
        print('Stopped recording at: $_currentRecordingPath');

        // Upload to AWS
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          final uploadedUrl = await _awsService.uploadAudio(file);
          print('Audio uploaded successfully: $uploadedUrl');
          return uploadedUrl;
        }
      }

      return null;
    } catch (e) {
      print('Error stopping recording: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;

        // Delete the temporary file
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error canceling recording: $e');
    }
  }

  /// Upload audio file from path
  Future<String?> uploadAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final uploadedUrl = await _awsService.uploadAudio(file);
        print('Audio file uploaded successfully: $uploadedUrl');
        return uploadedUrl;
      }
      return null;
    } catch (e) {
      print('Error uploading audio file: $e');
      rethrow;
    }
  }

  /// Upload audio from bytes (for voice recording)
  Future<String?> uploadAudioFromBytes(
      Uint8List audioBytes, String fileName) async {
    try {
      final uploadedUrl =
          await _awsService.uploadAudioFromBytes(audioBytes, fileName);
      print('Audio bytes uploaded successfully: $uploadedUrl');
      return uploadedUrl;
    } catch (e) {
      print('Error uploading audio bytes: $e');
      rethrow;
    }
  }

  /// Get current recording amplitude (for visualization)
  Future<double> getAmplitude() async {
    if (_isRecording) {
      final amplitude = await _audioRecorder.getAmplitude();
      return amplitude.current;
    }
    return 0.0;
  }

  /// Start duration timer
  void _startDurationTimer() {
    // This would be implemented with a Timer to track recording duration
    // For now, we'll use a simple approach
  }

  /// Dispose resources
  void dispose() {
    _audioRecorder.dispose();
  }
}
