import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memory_pins_app/models/report_model.dart';

class ReportService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get current user info for debugging
  Map<String, dynamic> getCurrentUserInfo() {
    final user = _auth.currentUser;
    return {
      'uid': user?.uid,
      'email': user?.email,
      'displayName': user?.displayName,
      'isAnonymous': user?.isAnonymous,
      'emailVerified': user?.emailVerified,
    };
  }

  // Test method to simulate different user scenarios
  Future<Map<String, dynamic>> testUserScenarios() async {
    try {
      final currentUser = currentUserId;
      final hiddenContent = await getHiddenContent();

      // Get all pins to see their creators
      final pinsSnapshot = await _database.child('pins').get();
      final Map<String, String> pinCreators = {};

      if (pinsSnapshot.exists) {
        final Map<dynamic, dynamic> pinsData =
            pinsSnapshot.value as Map<dynamic, dynamic>;
        for (final entry in pinsData.entries) {
          final pinId = entry.key as String;
          final pinData = Map<String, dynamic>.from(entry.value as Map);
          pinCreators[pinId] = pinData['userId'] ?? 'unknown';
        }
      }

      return {
        'currentUserId': currentUser,
        'hiddenContentCount': hiddenContent.length,
        'hiddenPins': hiddenContent
            .where((c) => c.hiddenPinId != null)
            .map((c) => c.hiddenPinId!)
            .toList(),
        'hiddenUsers': hiddenContent
            .where((c) => c.hiddenUserId != null)
            .map((c) => c.hiddenUserId!)
            .toList(),
        'pinCreators': pinCreators,
      };
    } catch (e) {
      print('Error testing user scenarios: $e');
      return {};
    }
  }

  // Report a user
  Future<bool> reportUser({
    required String reportedUserId,
    required String reason,
    required String description,
  }) async {
    try {
      if (currentUserId == null) return false;

      final report = ReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reporterUserId: currentUserId!,
        reportedUserId: reportedUserId,
        reason: reason,
        description: description,
        reportedAt: DateTime.now(),
        status: 'pending',
      );

      await _database.child('reports').child(report.id).set(report.toMap());
      return true;
    } catch (e) {
      print('Error reporting user: $e');
      return false;
    }
  }

  // Report a pin - hides that specific pin for the reporter
  Future<bool> reportPin({
    required String reportedUserId,
    required String reportedPinId,
    required String reason,
    required String description,
  }) async {
    try {
      if (currentUserId == null) return false;

      final reportId = DateTime.now().millisecondsSinceEpoch.toString();

      final report = ReportModel(
        id: reportId,
        reporterUserId: currentUserId!,
        reportedUserId: reportedUserId,
        reportedPinId: reportedPinId,
        reason: reason,
        description: description,
        reportedAt: DateTime.now(),
        status: 'pending',
      );

      // Save the report
      await _database.child('reports').child(report.id).set(report.toMap());

      // Hide this specific pin for the reporter
      final hiddenContent = HiddenContentModel(
        id: '${currentUserId}_pin_${reportedPinId}',
        userId: currentUserId!,
        hiddenPinId: reportedPinId,
        reason: 'reported',
        hiddenAt: DateTime.now(),
        reportId: reportId,
      );

      print('Creating hidden content entry for PIN:');
      print('  ID: ${hiddenContent.id}');
      print('  User ID: ${hiddenContent.userId}');
      print('  Hidden Pin ID: ${hiddenContent.hiddenPinId}');
      print('  Reason: ${hiddenContent.reason}');

      await _database
          .child('hidden_content')
          .child(hiddenContent.id)
          .set(hiddenContent.toMap());
      return true;
    } catch (e) {
      print('Error reporting pin: $e');
      return false;
    }
  }

  // Report a tapu - hides that specific tapu for the reporter
  Future<bool> reportTapu({
    required String reportedUserId,
    required String reportedTapuId,
    required String reason,
    required String description,
  }) async {
    try {
      if (currentUserId == null) return false;

      final reportId = DateTime.now().millisecondsSinceEpoch.toString();

      final report = ReportModel(
        id: reportId,
        reporterUserId: currentUserId!,
        reportedUserId: reportedUserId,
        reportedTapuId: reportedTapuId,
        reason: reason,
        description: description,
        reportedAt: DateTime.now(),
        status: 'pending',
      );

      // Save the report
      await _database.child('reports').child(report.id).set(report.toMap());

      // Hide this specific tapu for the reporter
      final hiddenContent = HiddenContentModel(
        id: '${currentUserId}_tapu_${reportedTapuId}',
        userId: currentUserId!,
        hiddenTapuId: reportedTapuId,
        reason: 'reported',
        hiddenAt: DateTime.now(),
        reportId: reportId,
      );

      await _database
          .child('hidden_content')
          .child(hiddenContent.id)
          .set(hiddenContent.toMap());
      return true;
    } catch (e) {
      print('Error reporting tapu: $e');
      return false;
    }
  }

  // Block a user - hides all content from that user for the blocker
  Future<bool> blockUser({
    required String blockedUserId,
    String? reason,
  }) async {
    try {
      if (currentUserId == null) return false;

      final block = BlockModel(
        id: '${currentUserId}_${blockedUserId}',
        blockerUserId: currentUserId!,
        blockedUserId: blockedUserId,
        blockedAt: DateTime.now(),
        reason: reason,
      );

      // Save the block
      await _database.child('blocks').child(block.id).set(block.toMap());

      // Hide all content from the blocked user for the blocker
      final hiddenContent = HiddenContentModel(
        id: '${currentUserId}_user_${blockedUserId}',
        userId: currentUserId!,
        hiddenUserId: blockedUserId,
        reason: 'blocked',
        hiddenAt: DateTime.now(),
      );

      print('Creating hidden content entry for BLOCKED USER:');
      print('  ID: ${hiddenContent.id}');
      print('  User ID: ${hiddenContent.userId}');
      print('  Hidden User ID: ${hiddenContent.hiddenUserId}');
      print('  Reason: ${hiddenContent.reason}');

      await _database
          .child('hidden_content')
          .child(hiddenContent.id)
          .set(hiddenContent.toMap());
      return true;
    } catch (e) {
      print('Error blocking user: $e');
      return false;
    }
  }

  // Unblock a user - shows all content from that user again
  Future<bool> unblockUser({
    required String blockedUserId,
  }) async {
    try {
      if (currentUserId == null) return false;

      final blockId = '${currentUserId}_${blockedUserId}';
      await _database.child('blocks').child(blockId).remove();

      // Remove the hidden content entry for this user
      final hiddenContentId = '${currentUserId}_user_${blockedUserId}';
      await _database.child('hidden_content').child(hiddenContentId).remove();

      return true;
    } catch (e) {
      print('Error unblocking user: $e');
      return false;
    }
  }

  // Check if current user has blocked another user
  Future<bool> isUserBlocked({
    required String blockedUserId,
  }) async {
    try {
      if (currentUserId == null) return false;

      final blockId = '${currentUserId}_${blockedUserId}';
      final snapshot = await _database.child('blocks').child(blockId).get();
      return snapshot.exists;
    } catch (e) {
      print('Error checking if user is blocked: $e');
      return false;
    }
  }

  // Check if current user is blocked by another user
  Future<bool> isBlockedByUser({
    required String blockerUserId,
  }) async {
    try {
      if (currentUserId == null) return false;

      final blockId = '${blockerUserId}_${currentUserId}';
      final snapshot = await _database.child('blocks').child(blockId).get();
      return snapshot.exists;
    } catch (e) {
      print('Error checking if blocked by user: $e');
      return false;
    }
  }

  // Get list of users blocked by current user
  Future<List<String>> getBlockedUsers() async {
    try {
      if (currentUserId == null) return [];

      final snapshot = await _database
          .child('blocks')
          .orderByChild('blockerUserId')
          .equalTo(currentUserId)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.values
            .map((block) => block['blockedUserId'] as String)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting blocked users: $e');
      return [];
    }
  }

  // Get list of users who blocked current user
  Future<List<String>> getUsersWhoBlockedMe() async {
    try {
      if (currentUserId == null) return [];

      final snapshot = await _database
          .child('blocks')
          .orderByChild('blockedUserId')
          .equalTo(currentUserId)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.values
            .map((block) => block['blockerUserId'] as String)
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting users who blocked me: $e');
      return [];
    }
  }

  // Get all hidden content for current user
  Future<List<HiddenContentModel>> getHiddenContent() async {
    try {
      if (currentUserId == null) return [];

      final snapshot = await _database
          .child('hidden_content')
          .orderByChild('userId')
          .equalTo(currentUserId)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        return data.values
            .map((content) =>
                HiddenContentModel.fromMap(Map<String, dynamic>.from(content)))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting hidden content: $e');
      return [];
    }
  }

  // Check if a specific pin should be hidden for current user
  Future<bool> isPinHidden(String pinId) async {
    try {
      if (currentUserId == null) return false;

      // Check if this specific pin is hidden
      final hiddenPinId = '${currentUserId}_pin_$pinId';
      final snapshot =
          await _database.child('hidden_content').child(hiddenPinId).get();
      if (snapshot.exists) return true;

      // Check if pin creator is blocked
      final pinSnapshot = await _database.child('pins').child(pinId).get();
      if (pinSnapshot.exists) {
        final pinData = Map<String, dynamic>.from(pinSnapshot.value as Map);
        final pinCreatorId = pinData['userId'] as String?;
        if (pinCreatorId != null) {
          final isBlocked = await isUserBlocked(blockedUserId: pinCreatorId);
          if (isBlocked) return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking if pin is hidden: $e');
      return false;
    }
  }

  // Check if a specific tapu should be hidden for current user
  Future<bool> isTapuHidden(String tapuId) async {
    try {
      if (currentUserId == null) return false;

      // Check if this specific tapu is hidden
      final hiddenTapuId = '${currentUserId}_tapu_$tapuId';
      final snapshot =
          await _database.child('hidden_content').child(hiddenTapuId).get();
      if (snapshot.exists) return true;

      // Check if tapu creator is blocked
      final tapuSnapshot = await _database.child('tapus').child(tapuId).get();
      if (tapuSnapshot.exists) {
        final tapuData = Map<String, dynamic>.from(tapuSnapshot.value as Map);
        final tapuCreatorId = tapuData['userId'] as String?;
        if (tapuCreatorId != null) {
          final isBlocked = await isUserBlocked(blockedUserId: tapuCreatorId);
          if (isBlocked) return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking if tapu is hidden: $e');
      return false;
    }
  }

  // Check if content from a specific user should be hidden for current user
  Future<bool> isUserContentHidden(String contentUserId) async {
    try {
      if (currentUserId == null) return false;

      // Check if this user is blocked
      final isBlocked = await isUserBlocked(blockedUserId: contentUserId);
      if (isBlocked) return true;

      // Check if current user is blocked by this user
      final isBlockedBy = await isBlockedByUser(blockerUserId: contentUserId);
      if (isBlockedBy) return true;

      return false;
    } catch (e) {
      print('Error checking if user content is hidden: $e');
      return false;
    }
  }

  // Remove hidden content (for unblocking or admin actions)
  Future<bool> removeHiddenContent(String hiddenContentId) async {
    try {
      await _database.child('hidden_content').child(hiddenContentId).remove();
      return true;
    } catch (e) {
      print('Error removing hidden content: $e');
      return false;
    }
  }

  // Clear all hidden content for current user (for testing)
  Future<bool> clearAllHiddenContent() async {
    try {
      if (currentUserId == null) return false;

      print('Clearing all hidden content for user: $currentUserId');

      final snapshot = await _database
          .child('hidden_content')
          .orderByChild('userId')
          .equalTo(currentUserId)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;
        print('Found ${data.length} hidden content entries to clear');

        for (final key in data.keys) {
          print('Removing hidden content: $key');
          await _database.child('hidden_content').child(key).remove();
        }

        print('All hidden content cleared successfully');
      } else {
        print('No hidden content found to clear');
      }
      return true;
    } catch (e) {
      print('Error clearing hidden content: $e');
      return false;
    }
  }

  // Clear only reported pins (keep blocked users)
  Future<bool> clearReportedPins() async {
    try {
      if (currentUserId == null) return false;

      print('Clearing only reported pins for user: $currentUserId');

      final snapshot = await _database
          .child('hidden_content')
          .orderByChild('userId')
          .equalTo(currentUserId)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;

        for (final key in data.keys) {
          final content = data[key];
          if (content['reason'] == 'reported' &&
              content['hiddenPinId'] != null) {
            print('Removing reported pin: ${content['hiddenPinId']}');
            await _database.child('hidden_content').child(key).remove();
          }
        }

        print('Reported pins cleared successfully');
      }
      return true;
    } catch (e) {
      print('Error clearing reported pins: $e');
      return false;
    }
  }

  // Clear only blocked users (keep reported pins)
  Future<bool> clearBlockedUsers() async {
    try {
      if (currentUserId == null) return false;

      print('Clearing only blocked users for user: $currentUserId');

      final snapshot = await _database
          .child('hidden_content')
          .orderByChild('userId')
          .equalTo(currentUserId)
          .get();

      if (snapshot.exists) {
        final Map<dynamic, dynamic> data =
            snapshot.value as Map<dynamic, dynamic>;

        for (final key in data.keys) {
          final content = data[key];
          if (content['reason'] == 'blocked' &&
              content['hiddenUserId'] != null) {
            print('Removing blocked user: ${content['hiddenUserId']}');
            await _database.child('hidden_content').child(key).remove();
          }
        }

        print('Blocked users cleared successfully');
      }
      return true;
    } catch (e) {
      print('Error clearing blocked users: $e');
      return false;
    }
  }

  // Get current hidden content summary
  Future<Map<String, dynamic>> getHiddenContentSummary() async {
    try {
      if (currentUserId == null) return {};

      final hiddenContent = await getHiddenContent();

      final reportedPins = <String>[];
      final blockedUsers = <String>[];

      for (final content in hiddenContent) {
        if (content.reason == 'reported' && content.hiddenPinId != null) {
          reportedPins.add(content.hiddenPinId!);
        }
        if (content.reason == 'blocked' && content.hiddenUserId != null) {
          blockedUsers.add(content.hiddenUserId!);
        }
      }

      return {
        'reportedPins': reportedPins,
        'blockedUsers': blockedUsers,
        'totalHiddenContent': hiddenContent.length,
      };
    } catch (e) {
      print('Error getting hidden content summary: $e');
      return {};
    }
  }
}
