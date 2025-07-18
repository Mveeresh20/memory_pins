class ReportModel {
  final String id;
  final String reporterUserId;
  final String reportedUserId;
  final String? reportedPinId;
  final String? reportedTapuId;
  final String reason;
  final String description;
  final DateTime reportedAt;
  final String status; // 'pending', 'reviewed', 'resolved', 'dismissed'
  final String? adminNotes;

  ReportModel({
    required this.id,
    required this.reporterUserId,
    required this.reportedUserId,
    this.reportedPinId,
    this.reportedTapuId,
    required this.reason,
    required this.description,
    required this.reportedAt,
    required this.status,
    this.adminNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reporterUserId': reporterUserId,
      'reportedUserId': reportedUserId,
      'reportedPinId': reportedPinId,
      'reportedTapuId': reportedTapuId,
      'reason': reason,
      'description': description,
      'reportedAt': reportedAt.toIso8601String(),
      'status': status,
      'adminNotes': adminNotes,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map) {
    return ReportModel(
      id: map['id'] ?? '',
      reporterUserId: map['reporterUserId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reportedPinId: map['reportedPinId'],
      reportedTapuId: map['reportedTapuId'],
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      reportedAt: DateTime.parse(map['reportedAt']),
      status: map['status'] ?? 'pending',
      adminNotes: map['adminNotes'],
    );
  }
}

class BlockModel {
  final String id;
  final String blockerUserId;
  final String blockedUserId;
  final DateTime blockedAt;
  final String? reason;

  BlockModel({
    required this.id,
    required this.blockerUserId,
    required this.blockedUserId,
    required this.blockedAt,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'blockerUserId': blockerUserId,
      'blockedUserId': blockedUserId,
      'blockedAt': blockedAt.toIso8601String(),
      'reason': reason,
    };
  }

  factory BlockModel.fromMap(Map<String, dynamic> map) {
    return BlockModel(
      id: map['id'] ?? '',
      blockerUserId: map['blockerUserId'] ?? '',
      blockedUserId: map['blockedUserId'] ?? '',
      blockedAt: DateTime.parse(map['blockedAt']),
      reason: map['reason'],
    );
  }
}

// Report reasons for different content types
class ReportReasons {
  static const List<String> userReasons = [
    'Harassment or bullying',
    'Inappropriate behavior',
    'Spam or fake account',
    'Impersonation',
    'Other',
  ];

  static const List<String> contentReasons = [
    'Inappropriate content',
    'Violence or harm',
    'Spam or misleading',
    'Copyright violation',
    'Privacy violation',
    'Other',
  ];
}
