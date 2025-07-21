// lib/models/tapus           .dart
import 'package:memory_pins_app/models/map_coordinates.dart';

class Tapus {
  final String id;
  final String name;
  final String avatarUrl;
  final String
      centerPinImageUrl; // The image for this specific Tapu pin on the main map
  final MapCoordinates
      centerCoordinates; // The coordinates of this Tapu on the main map
  final int totalPins; // Total number of associated attachments
  final List<String> emojis; // Selected emojis from Create Tapu Screen
  final String location; // Location name (e.g., "New York, NY")
  final String? userId; // User ID who created this Tapu

  Tapus({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.centerPinImageUrl,
    required this.centerCoordinates,
    required this.totalPins,
    this.emojis = const [], // Default to empty list
    this.location = '', // Default to empty string
    this.userId, // Optional user ID
  });

  factory Tapus.fromJson(Map<String, dynamic> json) {
    return Tapus(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
      centerPinImageUrl: json['centerPinImageUrl'] as String,
      centerCoordinates: MapCoordinates.fromJson(json['centerCoordinates']),
      totalPins: json['totalPins'] as int,
      emojis: List<String>.from(json['emojis'] ?? []),
      location: json['location'] as String,
      userId: json['userId'] as String?, // Add userId from JSON
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'centerPinImageUrl': centerPinImageUrl,
        'centerCoordinates': centerCoordinates.toJson(),
        'totalPins': totalPins,
        'emojis': emojis,
        'location': location,
        'userId': userId, // Include userId in JSON
      };
}
