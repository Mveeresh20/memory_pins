import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/journal_entry.dart';

 

class ProgressService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final String TABLE_NAME = 'w12_user_progress';
  final String RECENT_ACTIVITIES_TABLE = 'w12_recent_activities';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Activity types and their weights
  static const Map<String, double> activityWeights = {
    'journal': 1.0, // 30% weight
    'meditation': 1.0, // 25% weight
    'reading': 1.0, // 15% weight
    'listening': 1.0, // 15% weight
    'writing': 1.0, // 15% weight
  };

  // Maximum counts for 100% completion
  static const Map<String, int> maxActivityCounts = {
    'journal': 100,
    'meditation': 100,
    'reading': 100,
    'listening': 100,
    'writing': 20, // 20 letters for 100% writing progress
  };

  // Update progress when an activity is completed
  Future<void> updateActivityProgress(String activityType,
      {String? activityTitle, String? activityId}) async {
    if (_currentUserId == null) return;

    try {
      final progressRef = _database.child(TABLE_NAME).child(_currentUserId!);
      final recentActivitiesRef =
          _database.child(RECENT_ACTIVITIES_TABLE).child(_currentUserId!);

      // Get current progress
      final progressSnapshot = await progressRef.get();
      Map<String, dynamic> currentProgress = {};
      if (progressSnapshot.exists) {
        currentProgress =
            Map<String, dynamic>.from(progressSnapshot.value as Map);
      }

      // Initialize activity count if not exists
      currentProgress[activityType] = (currentProgress[activityType] ?? 0) + 1;

      // Calculate total progress
      double totalProgress = 0;
      activityWeights.forEach((activity, weight) {
        final count = currentProgress[activity] ?? 0;
        final maxCount = maxActivityCounts[activity] ?? 100;
        // Calculate progress based on max count for each activity type
        totalProgress += (count / maxCount) * weight;
      });

      // Update total progress
      currentProgress['totalProgress'] = totalProgress.clamp(0.0, 1.0);

      // Save updated progress
      await progressRef.set(currentProgress);

      // Update recent activities
      final recentActivity = {
        'type': activityType,
        'title': activityTitle ?? 'Untitled Activity',
        'id': activityId,
        'timestamp': ServerValue.timestamp,
      };

      // Add to recent activities (limit to last 10)
      await recentActivitiesRef.push().set(recentActivity);

      // Keep only last 10 activities
      final recentSnapshot = await recentActivitiesRef.get();
      if (recentSnapshot.exists) {
        final Map<dynamic, dynamic> activities = recentSnapshot.value as Map;
        if (activities.length > 10) {
          final sortedKeys = activities.keys.toList()
            ..sort((a, b) => activities[b]['timestamp']
                .compareTo(activities[a]['timestamp']));
          for (int i = 10; i < sortedKeys.length; i++) {
            await recentActivitiesRef.child(sortedKeys[i]).remove();
          }
        }
      }
    } catch (e) {
      print('Error updating progress: $e');
    }
  }

  // Get user's progress
  Future<Map<String, dynamic>> getUserProgress() async {
    if (_currentUserId == null) {
      return {
        'totalProgress': 0.0,
        'journal': 0,
        'meditation': 0,
        'reading': 0,
        'listening': 0,
        'writing': 0,
      };
    }

    try {
      final snapshot =
          await _database.child(TABLE_NAME).child(_currentUserId!).get();

      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('Error fetching progress: $e');
    }

    return {
      'totalProgress': 0.0,
      'journal': 0,
      'meditation': 0,
      'reading': 0,
      'listening': 0,
      'writing': 0,
    };
  }

  // Get recent activities
  Future<List<Map<String, dynamic>>> getRecentActivities() async {
    if (_currentUserId == null) return [];

    try {
      final snapshot = await _database
          .child(RECENT_ACTIVITIES_TABLE)
          .child(_currentUserId!)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> activities = snapshot.value as Map;
        return activities.entries
            .map((entry) => Map<String, dynamic>.from(entry.value))
            .toList()
          ..sort(
              (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      }
    } catch (e) {
      print('Error fetching recent activities: $e');
    }

    return [];
  }

  // Calculate activity-specific progress
  double calculateActivityProgress(String activityType, int count) {
    final maxCount = maxActivityCounts[activityType] ?? 100;
    return (count / maxCount).clamp(0.0, 1.0);
  }

  // Get growth stage based on total progress
  String getGrowthStage(double progress) {
    if (progress < 0.33) return '🌱'; // Seedling
    if (progress < 0.66) return '🌿'; // Growing
    return '🌳'; // Mature
  }

  // Get growth stage description
  String getGrowthStageDescription(String stage) {
    switch (stage) {
      case '🌱':
        return 'Seedling Stage - Just starting your healing journey';
      case '🌿':
        return 'Growing Stage - Making steady progress';
      case '🌳':
        return 'Mature Stage - Strong and resilient';
      default:
        return 'Starting your journey';
    }
  }
}
