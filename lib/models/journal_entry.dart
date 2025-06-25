class JournalEntry {
  final String id;
  final String userId;
  final String type; // 'text' or 'audio'
  final String? textNote;
  final String? audioPath;
  final DateTime createdAt;
  final String? title;
  final String? audioNotePath;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.type,
    this.textNote,
    this.audioPath,
    required this.createdAt,
    this.title,
    this.audioNotePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'textNote': textNote,
      'audioPath': audioPath,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'audioNotePath': audioNotePath,
    };
  }

  factory JournalEntry.fromMap(String id, Map<String, dynamic> map) {
    return JournalEntry(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'text',
      textNote: map['textNote'],
      audioPath: map['audioPath'],
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      title: map['title'],
      audioNotePath: map['audioNotePath'],
    );
  }
}
