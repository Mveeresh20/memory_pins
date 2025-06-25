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

  final int photoCount;
  final int audioCount;
  final List<String> imageUrls; // List of URLs for preview images
  final int viewsCount;
  final int playsCount;



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
  
    required this.photoCount,
    required this.audioCount,
    required this.imageUrls,
    required this.viewsCount,
    required this.playsCount,

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
        photoCount: json['photoCount'],
        audioCount: json['audioCount'],
        imageUrls: json['imageUrls'],
        viewsCount: json['viewsCount'],
        playsCount: json['playsCount'],
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
        'photoCount': photoCount,
        'audioCount': audioCount,
        'imageUrls': imageUrls,
        'viewsCount': viewsCount,
        'playsCount': playsCount,
    };
  }
}