import 'package:memory_pins_app/models/tapus.dart';

class Tapu {
  final String id;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String moodIconUrl;
  final String title;
  final String location;
  final String description;
  final String mood;
  final List<String> photoUrls;
  final int totalPins;
  final int views;
  final int plays;

  Tapu({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.moodIconUrl,
    this.title = 'Tapu',
    this.location = 'Unknown Location',
    this.description = '',
    this.mood = '',
    this.photoUrls = const [],
    this.totalPins = 0,
    this.views = 0,
    this.plays = 0,
  });

  factory Tapu.fromTapus(Tapus tapus) {
    return Tapu(
      id: tapus.id,
      latitude: tapus.centerCoordinates.latitude,
      longitude: tapus.centerCoordinates.longitude,
      imageUrl: tapus.centerPinImageUrl,
      moodIconUrl: tapus.avatarUrl,
      title: tapus.name,
      location: 'Unknown Location',
      description: '',
      mood: '',
      photoUrls: tapus.emojis, // Use the emojis from Tapus
      totalPins: tapus.totalPins,
      views: 0,
      plays: 0,
    );
  }

  factory Tapu.fromMap(Map<String, dynamic> map) {
    return Tapu(
      id: map['tapuId'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      moodIconUrl: map['moodIconUrl'] ?? '',
      title: map['title'] ?? '',
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      mood: map['mood'] ?? '',
      photoUrls: List<String>.from(map['emojis'] ??
          map['photoUrls'] ??
          []), // Use emojis if available, fallback to photoUrls
      totalPins: map['totalPins'] ?? 0,
      views: map['views'] ?? 0,
      plays: map['plays'] ?? 0,
    );
  }
}
