import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:memory_pins_app/models/journal_entry.dart';
import 'package:memory_pins_app/services/audio_picker_util.dart';
import 'package:memory_pins_app/services/progress_ervice.dart';


class JournalService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String TABLE_NAME = 'w12_journal_entries';
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPickerUtil _audioPickerUtil = AudioPickerUtil();
  final ProgressService _progressService = ProgressService();

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Save text note
  Future<void> saveTextNote(String text, {String? title}) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    // Validate text is not empty
    if (text.trim().isEmpty) {
      throw Exception('Text note cannot be empty');
    }

    try {
      final entry = JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: _currentUserId!,
        type: 'text',
        textNote: text,
        createdAt: DateTime.now(),
        title: title,
      );

      await _database.child(TABLE_NAME).child(entry.id).set(entry.toMap());

      // Update progress
      await _progressService.updateActivityProgress(
        'journal',
        activityTitle: title ?? 'Journal Entry',
        activityId: entry.id,
      );
    } catch (e) {
      throw Exception('Failed to save text note: $e');
    }
  }

  // Save audio note with S3 upload
  Future<void> saveAudioNoteWithUpload(
    String localAudioPath,
    BuildContext context, {
    String? title,
    required Function(String) onUploadSuccess,
    required Function(String) onUploadFailure,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Upload audio to S3
      await _audioPickerUtil.uploadAudioToS3(
        localAudioPath,
        context,
        (String uploadedPath) async {
          // After successful upload, save the entry to Firebase
          final entry = JournalEntry(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: _currentUserId!,
            type: 'audio',
            audioPath: uploadedPath,
            createdAt: DateTime.now(),
            title: title,
          );

          await _database.child(TABLE_NAME).child(entry.id).set(entry.toMap());

          // Update progress
          await _progressService.updateActivityProgress(
            'journal',
            activityTitle: title ?? 'Audio Journal',
            activityId: entry.id,
          );

          onUploadSuccess(uploadedPath);
        },
        onUploadFailure,
      );
    } catch (e) {
      onUploadFailure('Failed to save audio note: $e');
    }
  }

  // Get audio URL for playback
  String getAudioUrl(String audioPath) {
    return _audioPickerUtil.getUrlForUploadedAudio(audioPath);
  }

  // Fetch all user's journal entries
  Future<List<JournalEntry>> fetchUserEntries() async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _database
          .child(TABLE_NAME)
          .orderByChild('userId')
          .equalTo(_currentUserId)
          .get();

      if (snapshot.exists) {
        List<JournalEntry> entries = [];
        Map<dynamic, dynamic> values = snapshot.value as Map;
        values.forEach((key, value) {
          entries
              .add(JournalEntry.fromMap(key, Map<String, dynamic>.from(value)));
        });
        // Sort by creation date, newest first
        entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return entries;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch journal entries: $e');
    }
  }

  // Fetch user's text notes only
  Future<List<JournalEntry>> fetchUserTextNotes() async {
    final entries = await fetchUserEntries();
    return entries.where((entry) => entry.type == 'text').toList();
  }

  // Fetch user's audio notes only
  Future<List<JournalEntry>> fetchUserAudioNotes() async {
    final entries = await fetchUserEntries();
    return entries.where((entry) => entry.type == 'audio').toList();
  }

  // Delete a journal entry
  Future<void> deleteEntry(String entryId) async {
    try {
      await _database.child(TABLE_NAME).child(entryId).remove();
    } catch (e) {
      throw Exception('Failed to delete journal entry: $e');
    }
  }

  // Update a journal entry
  Future<void> updateEntry(JournalEntry entry) async {
    if (_currentUserId == null || entry.userId != _currentUserId) {
      throw Exception('Unauthorized to update this entry');
    }

    try {
      await _database.child(TABLE_NAME).child(entry.id).update(entry.toMap());
    } catch (e) {
      throw Exception('Failed to update journal entry: $e');
    }
  }

}
