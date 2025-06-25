// lib/models/home_tapu_card_data.dart
// ఈ ఫైల్ లో ఎటువంటి మార్పు ఉండదు.
import 'package:memory_pins_app/models/map_coordinates.dart'; // Assuming you might use this elsewhere, though not directly in the home card's immediate display

class HomeTapuCardData {
  final String id;
  final String locationName;
  final String tapuName;
  final String mainImageUrl;
  final String ownerAvatarUrl;
  final List<String> emojis; // List of emoji URLs
  final int pinCount; // Or attachmentCount
  final int imageCount;
  final int imageCount_text; // For the "X Images" text based on screenshots
  final int audioCount;
  final int viewsCount;
  final int playsCount;
  final List<String> previewImageUrls;
   final List<String> reactionEmojis;

  HomeTapuCardData({
    required this.id,
    required this.locationName,
    required this.tapuName,
    required this.mainImageUrl,
    required this.ownerAvatarUrl,
    required this.emojis,
    required this.pinCount,
    required this.imageCount,
    required this.imageCount_text,
    required this.audioCount,
    required this.viewsCount,
    required this.playsCount,
    required this.previewImageUrls,
    required this.reactionEmojis,
  });

  // Optional: fromJson factory constructor if you load this data from JSON
  factory HomeTapuCardData.fromJson(Map<String, dynamic> json) {
    return HomeTapuCardData(
      id: json['id'] as String,
      locationName: json['locationName'] as String,
      tapuName: json['tapuName'] as String,
      mainImageUrl: json['mainImageUrl'] as String,
      ownerAvatarUrl: json['ownerAvatarUrl'] as String,
      emojis: List<String>.from(json['emojis'] as List),
      pinCount: json['pinCount'] as int,
      imageCount: json['imageCount'] as int,
      imageCount_text: json['imageCount_text'] as int,
      audioCount: json['audioCount'] as int,
      viewsCount: json['viewsCount'] as int,
      playsCount: json['playsCount'] as int,
      previewImageUrls: List<String>.from(json['previewImageUrls'] as List),
      reactionEmojis: List<String>.from(json['reactionEmojis'] as List),
    );
  }

  // Optional: toJson method
  Map<String, dynamic> toJson() => {
    'id': id,
    'locationName': locationName,
    'tapuName': tapuName,
    'mainImageUrl': mainImageUrl,
    'ownerAvatarUrl': ownerAvatarUrl,
    'emojis': emojis,
    'pinCount': pinCount,
    'imageCount': imageCount,
    'imageCount_text': imageCount_text,
    'audioCount': audioCount,
    'viewsCount': viewsCount,
    'playsCount': playsCount,
    'previewImageUrls': previewImageUrls,
    'reactionEmojis': reactionEmojis,
  };
}