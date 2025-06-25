class TapuCreate {
  final String id;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String moodIconUrl; // Placeholder for mood icon
  final String title;

  TapuCreate({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.moodIconUrl,
    this.title = 'Pin',
  });
}