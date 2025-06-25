// lib/models/tapu_attachment.dart
import 'package:memory_pins_app/models/map_coordinates.dart';

class TapuAttachment {
  final String id;
  final String tapuId; // NEW: To link it to its parent Tapu
  final String title;
  final String? emoji;
  final String imageUrl; // The main circular image for the attachment pin
  final MapCoordinates coordinates; // Coordinates of this attachment pin on the *detail map*
  final int attachmentCount; // Sub-count of things within this attachment (e.g., photos)
  final int audioCount;
  final List<String> previewImageUrls; // Small square images at the bottom
  final int viewsCount;
  final String? profileImageUrlPin;

  TapuAttachment({
    required this.id,
    required this.tapuId, // Initialize new field
    required this.title,
    this.emoji,
    required this.imageUrl,
    required this.coordinates,
    required this.attachmentCount,
    required this.audioCount,
    required this.previewImageUrls,
    required this.viewsCount,
    this.profileImageUrlPin,
  });

  factory TapuAttachment.fromJson(Map<String, dynamic> json) {
    return TapuAttachment(
      id: json['id'] as String,
      tapuId: json['tapuId'] as String, // Parse new field
      title: json['title'] as String,
      emoji: json['emoji'] as String?,
      imageUrl: json['imageUrl'] as String,
      coordinates: MapCoordinates.fromJson(json['coordinates']),
      attachmentCount: json['attachmentCount'] as int,
      audioCount: json['audioCount'] as int,
      previewImageUrls: List<String>.from(json['previewImageUrls'] as List),
      viewsCount: json['viewsCount'] as int,
      profileImageUrlPin: json['profileImageUrlPin'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tapuId': tapuId, // Serialize new field
    'title': title,
    'emoji': emoji,
    'imageUrl': imageUrl,
    'coordinates': coordinates.toJson(),
    'attachmentCount': attachmentCount,
    'audioCount': audioCount,
    'previewImageUrls': previewImageUrls,
    'viewsCount': viewsCount,
    'profileImageUrlPin': profileImageUrlPin,
  };
}