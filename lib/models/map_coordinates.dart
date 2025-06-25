// lib/models/map_coordinates.dart
class MapCoordinates {
  final double latitude;
  final double longitude;

  MapCoordinates({required this.latitude, required this.longitude});

  factory MapCoordinates.fromJson(Map<String, dynamic> json) {
    return MapCoordinates(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}