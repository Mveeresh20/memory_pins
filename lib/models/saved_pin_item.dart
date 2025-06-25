// models/pin_item.dart

import 'package:memory_pins_app/presentation/Widgets/saved_pin_card.dart';

class SavedPinItem {
  final String location;
  final String? flagEmoji; // Using emoji for simplicity, could be asset path
  final String title;
  final String? emoji; // Emoji for the pin title
  final int photoCount;
  final int audioCount;
  final List<String> imageUrls; // List of URLs for preview images
  final int viewsCount;
  final int playsCount;

  SavedPinItem({
    required this.location,
    this.flagEmoji,
  required this.title,
    this.emoji,
    required this.photoCount,
    required this.audioCount,
    required this.imageUrls,
    required this.viewsCount,
    required this.playsCount,
  });

  // Example factory constructor for converting from a JSON-like map (e.g., from an API)
  factory SavedPinItem.fromJson(Map<String, dynamic> json) {
    return SavedPinItem(
      location: json['location'] as String,
      flagEmoji: json['flagEmoji'] as String?,
      title: json['title'] as String,
      emoji: json['emoji'] as String?,
      photoCount: json['photoCount'] as int,
      audioCount: json['audioCount'] as int,
      imageUrls: List<String>.from(json['imageUrls'] as List),
      viewsCount: json['viewsCount'] as int,
      playsCount: json['playsCount'] as int,
    );
  }

  // Example method to convert to JSON-like map
  Map<String, dynamic> toJson() {
    return {
      'location': location,
      'flagEmoji': flagEmoji,
      'title': title,
      'emoji': emoji,
      'photoCount': photoCount,
      'audioCount': audioCount,
      'imageUrls': imageUrls,
      'viewsCount': viewsCount,
      'playsCount': playsCount,
    };
  }
}