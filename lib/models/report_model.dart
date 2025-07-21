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

// New model for tracking hidden content
class HiddenContentModel {
  final String id;
  final String userId; // User who should not see this content
  final String? hiddenPinId; // Specific pin to hide (for reports)
  final String? hiddenTapuId; // Specific tapu to hide (for reports)
  final String? hiddenUserId; // User whose content to hide (for blocks)
  final String reason; // 'reported' or 'blocked'
  final DateTime hiddenAt;
  final String?
      reportId; // Reference to the report if this was hidden due to reporting

  HiddenContentModel({
    required this.id,
    required this.userId,
    this.hiddenPinId,
    this.hiddenTapuId,
    this.hiddenUserId,
    required this.reason,
    required this.hiddenAt,
    this.reportId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'hiddenPinId': hiddenPinId,
      'hiddenTapuId': hiddenTapuId,
      'hiddenUserId': hiddenUserId,
      'reason': reason,
      'hiddenAt': hiddenAt.toIso8601String(),
      'reportId': reportId,
    };
  }

  factory HiddenContentModel.fromMap(Map<String, dynamic> map) {
    return HiddenContentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      hiddenPinId: map['hiddenPinId'],
      hiddenTapuId: map['hiddenTapuId'],
      hiddenUserId: map['hiddenUserId'],
      reason: map['reason'] ?? '',
      hiddenAt: DateTime.parse(map['hiddenAt']),
      reportId: map['reportId'],
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
