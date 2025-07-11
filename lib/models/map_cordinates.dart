// models/map_pin_data.dart

import 'package:flutter/material.dart'; // For Color or ImageProvider if directly used

// Represents a location on the map
class MapCordinates {
  final double latitude;
  final double longitude;

  MapCordinates({required this.latitude, required this.longitude});

  factory MapCordinates.fromJson(Map<String, dynamic> json) {
    return MapCordinates(
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
    );
  }
  Map<String, dynamic> toJson() => {'latitude': latitude, 'longitude': longitude};
}

// Represents a user avatar on the map
class UserAvatar {
  final String imageUrl;
  final MapCordinates coordinates;

  UserAvatar({required this.imageUrl, required this.coordinates});

  factory UserAvatar.fromJson(Map<String, dynamic> json) {
    return UserAvatar(
      imageUrl: json['imageUrl'] as String,
      coordinates: MapCordinates.fromJson(json['coordinates']),
    );
  }
  Map<String, dynamic> toJson() => {
    'imageUrl': imageUrl,
    'coordinates': coordinates.toJson(),
  };
}

// Represents a generic map item (could be a pin, a place, etc.)
class MapItem {
  final String id; // Unique ID for the item
  final String iconUrl; // URL for the pin graphic (e.g., tent/palm trees)
  final MapCordinates coordinates;
  final String? associatedDetailId; // Optional: ID linking to a MapDetailCardData

  MapItem({
    required this.id,
    required this.iconUrl,
    required this.coordinates,
    this.associatedDetailId,
  });

  factory MapItem.fromJson(Map<String, dynamic> json) {
    return MapItem(
      id: json['id'] as String,
      iconUrl: json['iconUrl'] as String,
      coordinates: MapCordinates.fromJson(json['coordinates']),
      associatedDetailId: json['associatedDetailId'] as String?,
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'iconUrl': iconUrl,
    'coordinates': coordinates.toJson(),
    'associatedDetailId': associatedDetailId,
  };
}


// Represents the data for the bottom details card
class MapDetailCardData {
  final double distance;
  final String distanceUnit;
  final String title;
  final int pinCount;
  final int imageCount;
  final int audioCount;
  final List<String> reactionEmojis;
  final int viewsCount;
  final int playsCount;

  MapDetailCardData({
    required this.distance,
    required this.distanceUnit,
    required this.title,
    required this.pinCount,
    required this.imageCount,
    required this.audioCount,
    required this.reactionEmojis,
    required this.viewsCount,
    required this.playsCount,
  });

  factory MapDetailCardData.fromJson(Map<String, dynamic> json) {
    return MapDetailCardData(
      distance: (json['distance'] as num).toDouble(),
      distanceUnit: json['distanceUnit'] as String,
      title: json['title'] as String,
      pinCount: json['pinCount'] as int,
      imageCount: json['imageCount'] as int,
      audioCount: json['audioCount'] as int,
      reactionEmojis: List<String>.from(json['reactionEmojis'] as List),
      viewsCount: json['viewsCount'] as int,
      playsCount: json['playsCount'] as int,
    );
  }
  Map<String, dynamic> toJson() => {
    'distance': distance,
    'distanceUnit': distanceUnit,
    'title': title,
    'pinCount': pinCount,
    'imageCount': imageCount,
    'audioCount': audioCount,
    'reactionEmojis': reactionEmojis,
    'viewsCount': viewsCount,
    'playsCount': playsCount,
  };
}

// Main data model for the entire screen state
class MapScreenData {
  final String currentMapName; // e.g., "Tapu's"
  final String zoomLevelText; // e.g., "52 x 52"final width = MediaQuery.of(context).size.width;
  final List<UserAvatar> userAvatars;
  final List<MapItem> mapItems;
  final List<MapDetailCardData> detailCards;
   // All possible detail cards

  MapScreenData({
    required this.currentMapName,
    required this.zoomLevelText,
    required this.userAvatars,
    required this.mapItems,
    required this.detailCards,
  });

  factory MapScreenData.fromJson(Map<String, dynamic> json) {
    return MapScreenData(
      currentMapName: json['currentMapName'] as String,
      zoomLevelText: json['zoomLevelText'] as String,
      userAvatars: (json['userAvatars'] as List)
          .map((i) => UserAvatar.fromJson(i))
          .toList(),
      mapItems: (json['mapItems'] as List)
          .map((i) => MapItem.fromJson(i))
          .toList(),
      detailCards: (json['detailCards'] as List)
          .map((i) => MapDetailCardData.fromJson(i))
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => {
    'currentMapName': currentMapName,
    'zoomLevelText': zoomLevelText,
    'userAvatars': userAvatars.map((e) => e.toJson()).toList(),
    'mapItems': mapItems.map((e) => e.toJson()).toList(),
    'detailCards': detailCards.map((e) => e.toJson()).toList(),
  };
}