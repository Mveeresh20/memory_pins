import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memory_pins_app/models/report_model.dart';

class ReportService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

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

  // Report a pin
  Future<bool> reportPin({
    required String reportedUserId,
    required String reportedPinId,
    required String reason,
    required String description,
  }) async {
    try {
      if (currentUserId == null) return false;

      final report = ReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reporterUserId: currentUserId!,
        reportedUserId: reportedUserId,
        reportedPinId: reportedPinId,
        reason: reason,
        description: description,
        reportedAt: DateTime.now(),
        status: 'pending',
      );

      await _database.child('reports').child(report.id).set(report.toMap());

      return true;
    } catch (e) {
      print('Error reporting pin: $e');
      return false;
    }
  }

  // Report a tapu
  Future<bool> reportTapu({
    required String reportedUserId,
    required String reportedTapuId,
    required String reason,
    required String description,
  }) async {
    try {
      if (currentUserId == null) return false;

      final report = ReportModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reporterUserId: currentUserId!,
        reportedUserId: reportedUserId,
        reportedTapuId: reportedTapuId,
        reason: reason,
        description: description,
        reportedAt: DateTime.now(),
        status: 'pending',
      );

      await _database.child('reports').child(report.id).set(report.toMap());

      return true;
    } catch (e) {
      print('Error reporting tapu: $e');
      return false;
    }
  }

  // Block a user
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

      await _database.child('blocks').child(block.id).set(block.toMap());

      return true;
    } catch (e) {
      print('Error blocking user: $e');
      return false;
    }
  }

  // Unblock a user
  Future<bool> unblockUser({
    required String blockedUserId,
  }) async {
    try {
      if (currentUserId == null) return false;

      final blockId = '${currentUserId}_${blockedUserId}';
      await _database.child('blocks').child(blockId).remove();

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

  // Check if content should be hidden due to blocking
  Future<bool> shouldHideContent({
    required String contentUserId,
  }) async {
    try {
      if (currentUserId == null) return false;

      // Check if current user blocked the content creator
      final isBlocked = await isUserBlocked(blockedUserId: contentUserId);
      if (isBlocked) return true;

      // Check if content creator blocked current user
      final isBlockedBy = await isBlockedByUser(blockerUserId: contentUserId);
      if (isBlockedBy) return true;

      return false;
    } catch (e) {
      print('Error checking if content should be hidden: $e');
      return false;
    }
  }
}
