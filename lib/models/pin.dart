class Pin {
  final String location;
  final String? flagEmoji; // Using emoji for simplicity, could be asset path
  final String title;
  final String? emoji; // Emoji for the pin title
  final String id;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String moodIconUrl; // Placeholder for mood icon
  final String? description; // Description/message for others (optional)
  final String? userId; // User ID who created the pin
  final String? userName; // User name who created the pin

  final int photoCount;
  final int audioCount;
  final List<String> imageUrls; // List of URLs for preview images
  final List<String> audioUrls; // List of URLs for audio files
  final int viewsCount;
  final int playsCount;
  final DateTime? createdAt; // Add timestamp for filtering

  Pin({
    required this.location,
    required this.flagEmoji,
    required this.title,
    required this.emoji,
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.moodIconUrl,
    this.description, // Made optional
    this.userId, // User ID who created the pin
    this.userName, // User name who created the pin
    required this.photoCount,
    required this.audioCount,
    required this.imageUrls,
    required this.audioUrls,
    required this.viewsCount,
    required this.playsCount,
    this.createdAt, // Make it optional
  });

  // Copy with method for creating modified copies
  Pin copyWith({
    String? location,
    String? flagEmoji,
    String? title,
    String? emoji,
    String? id,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? moodIconUrl,
    String? description,
    String? userId,
    String? userName,
    int? photoCount,
    int? audioCount,
    List<String>? imageUrls,
    List<String>? audioUrls,
    int? viewsCount,
    int? playsCount,
    DateTime? createdAt,
  }) {
    return Pin(
      location: location ?? this.location,
      flagEmoji: flagEmoji ?? this.flagEmoji,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      moodIconUrl: moodIconUrl ?? this.moodIconUrl,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      photoCount: photoCount ?? this.photoCount,
      audioCount: audioCount ?? this.audioCount,
      imageUrls: imageUrls ?? this.imageUrls,
      audioUrls: audioUrls ?? this.audioUrls,
      viewsCount: viewsCount ?? this.viewsCount,
      playsCount: playsCount ?? this.playsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Pin.fromJson(Map<String, dynamic> json) {
    return Pin(
      location: json['location'],
      flagEmoji: json['flagEmoji'],
      title: json['title'],
      emoji: json['emoji'],
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      imageUrl: json['imageUrl'],
      moodIconUrl: json['moodIconUrl'],
      description: json['description'], // Already handles null
      userId: json['userId'], // User ID who created the pin
      userName: json['userName'], // User name who created the pin
      photoCount: json['photoCount'],
      audioCount: json['audioCount'],
      imageUrls: json['imageUrls'] ?? [],
      audioUrls: json['audioUrls'] ?? [],
      viewsCount: json['viewsCount'],
      playsCount: json['playsCount'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'flagEmoji': flagEmoji,
      'title': title,
      'emoji': emoji,
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'moodIconUrl': moodIconUrl,
      'description': description,
      'userId': userId,
      'userName': userName,
      'photoCount': photoCount,
      'audioCount': audioCount,
      'imageUrls': imageUrls,
      'audioUrls': audioUrls,
      'viewsCount': viewsCount,
      'playsCount': playsCount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
