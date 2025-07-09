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
    required this.photoCount,
    required this.audioCount,
    required this.imageUrls,
    required this.audioUrls,
    required this.viewsCount,
    required this.playsCount,
    this.createdAt, // Make it optional
  });

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
