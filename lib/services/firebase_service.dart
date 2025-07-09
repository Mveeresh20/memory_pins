import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/models/tapu.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/models/map_coordinates.dart';
import 'package:geolocator/geolocator.dart';

class FirebaseService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Database references
  DatabaseReference get _pinsRef => _database.ref('pins');
  DatabaseReference get _tapusRef => _database.ref('tapus');
  DatabaseReference get _usersRef => _database.ref('users');
  DatabaseReference get _savedPinsRef => _database.ref('saved_pins');

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Helper to safely convert int/double/null to double
  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 0.0;
  }

  // ========== PIN OPERATIONS ==========

  /// Create a new pin
  Future<String> createPin({
    required String title,
    required String description,
    required String mood,
    required double latitude,
    required double longitude,
    required String location,
    required List<String> photoUrls,
    required List<String> audioUrls,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final pinId = _pinsRef.push().key!;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      print('Storing pin data in Firebase:');
      print('Pin ID: $pinId');
      print('User ID: $userId');
      print('Title: $title');
      print('Description: $description');
      print('Mood: $mood');
      print('Mood Icon URL: $mood');
      print('Photo URLs: $photoUrls');
      print('Audio URLs: $audioUrls');
      print('Location: $location');
      print('Latitude: $latitude');
      print('Longitude: $longitude');

      final pinData = {
        'pinId': pinId,
        'userId': userId,
        'title': title,
        'description': description,
        'mood': mood, // This is the mood icon URL
        'moodIconUrl': mood, // Store the mood icon URL properly
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        'photoUrls': photoUrls,
        'audioUrls': audioUrls,
        'timestamp': timestamp,
        'views': 0,
        'plays': 0,
        'isPublic': true,
        'savedByUsers': [],
      };

      await _pinsRef.child(pinId).set(pinData);
      print('Pin data stored successfully in Firebase');

      // Update user's created pins
      await _usersRef.child(userId).child('createdPinIds').push().set(pinId);

      return pinId;
    } catch (e) {
      throw Exception('Failed to create pin: $e');
    }
  }

  /// Get nearby pins within specified radius
  Future<List<Pin>> getNearbyPins({
    required double userLatitude,
    required double userLongitude,
    required double radiusInKm,
  }) async {
    try {
      // Always fetch pins within 30KM to support both nearby (0-5KM) and far (5-30KM) filters
      final fetchRadius = 30.0; // Fetch up to 30KM

      final snapshot = await _pinsRef.get();
      if (!snapshot.exists) return [];

      final List<Pin> nearbyPins = [];

      for (final child in snapshot.children) {
        final pinData = child.value as Map<dynamic, dynamic>;

        // Skip private pins
        if (pinData['isPublic'] == false) continue;

        final pinLat = _toDouble(pinData['latitude']);
        final pinLng = _toDouble(pinData['longitude']);

        // Calculate distance
        final distance = Geolocator.distanceBetween(
              userLatitude,
              userLongitude,
              pinLat,
              pinLng,
            ) /
            1000; // Convert to kilometers

        // Fetch pins within 30KM (will be filtered by PinProvider based on selected range)
        if (distance <= fetchRadius) {
          final pin = Pin(
            location: pinData['location'] ?? '',
            flagEmoji: pinData['mood'] ?? '📍',
            title: pinData['title'] ?? '',
            emoji: pinData['mood'] ?? '📍',
            id: pinData['pinId'] ?? child.key ?? '',
            latitude: pinLat,
            longitude: pinLng,
            imageUrl:
                (pinData['photoUrls'] as List<dynamic>?)?.isNotEmpty == true
                    ? pinData['photoUrls'][0]
                    : '',
            moodIconUrl: pinData['moodIconUrl'] ??
                pinData['mood'] ??
                '📍', // Use moodIconUrl first, fallback to mood
            photoCount: (pinData['photoUrls'] as List<dynamic>?)?.length ?? 0,
            audioCount: (pinData['audioUrls'] as List<dynamic>?)?.length ?? 0,
            imageUrls: List<String>.from(pinData['photoUrls'] ?? []),
            viewsCount: pinData['views'] ?? 0,
            playsCount: pinData['plays'] ?? 0,
            description: pinData['description'] ?? '',
            audioUrls: List<String>.from(pinData['audioUrls'] ?? []),
            createdAt: pinData['timestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch(pinData['timestamp'])
                : null,
          );
          nearbyPins.add(pin);
        }
      }

      return nearbyPins;
    } catch (e) {
      print('Error getting nearby pins: $e');
      return [];
    }
  }

  /// Get user's own pins
  Future<List<Pin>> getUserPins({String? userId}) async {
    try {
      final targetUserId = userId ?? currentUserId;
      if (targetUserId == null) {
        print('User not authenticated');
        return [];
      }
      final snapshot = await _pinsRef.get();
      if (!snapshot.exists) return [];
      final List<Pin> userPins = [];
      for (final child in snapshot.children) {
        final pinData = child.value as Map<dynamic, dynamic>;
        if (pinData['userId'] != targetUserId) continue;

        print('Retrieved pin data from Firebase:');
        print('Pin ID: ${pinData['pinId']}');
        print('Title: ${pinData['title']}');
        print('Mood: ${pinData['mood']}');
        print('Mood Icon URL: ${pinData['moodIconUrl']}');
        print('Photo URLs: ${pinData['photoUrls']}');
        print(
            'Image URL (first photo): ${(pinData['photoUrls'] as List<dynamic>?)?.isNotEmpty == true ? pinData['photoUrls'][0] : 'No photos'}');

        final pinLat = _toDouble(pinData['latitude']);
        final pinLng = _toDouble(pinData['longitude']);
        final pin = Pin(
          location: pinData['location'] ?? '',
          flagEmoji: pinData['mood'] ?? '📍',
          title: pinData['title'] ?? '',
          emoji: pinData['mood'] ?? '📍',
          id: pinData['pinId'] ?? child.key ?? '',
          latitude: pinLat,
          longitude: pinLng,
          imageUrl: (pinData['photoUrls'] as List<dynamic>?)?.isNotEmpty == true
              ? pinData['photoUrls'][0]
              : '',
          moodIconUrl: pinData['moodIconUrl'] ??
              pinData['mood'] ??
              '📍', // Use moodIconUrl first, fallback to mood
          photoCount: (pinData['photoUrls'] as List<dynamic>?)?.length ?? 0,
          audioCount: (pinData['audioUrls'] as List<dynamic>?)?.length ?? 0,
          imageUrls: List<String>.from(pinData['photoUrls'] ?? []),
          viewsCount: pinData['views'] ?? 0,
          playsCount: pinData['plays'] ?? 0,
          description: pinData['description'] ?? '',
          audioUrls: List<String>.from(pinData['audioUrls'] ?? []),
          createdAt: pinData['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(pinData['timestamp'])
              : null,
        );

        print('Created Pin object:');
        print('Pin ID: ${pin.id}');
        print('Image URL: ${pin.imageUrl}');
        print('Mood Icon URL: ${pin.moodIconUrl}');
        print('Image URLs list: ${pin.imageUrls}');

        userPins.add(pin);
      }
      return userPins;
    } catch (e) {
      print('Error getting user pins: $e');
      return [];
    }
  }

  /// Get pin by ID
  Future<Pin?> getPinById(String pinId) async {
    try {
      final snapshot = await _pinsRef.child(pinId).get();
      if (!snapshot.exists) {
        print('Pin not found with ID: $pinId');
        return null;
      }

      final pinData = snapshot.value as Map<dynamic, dynamic>;
      print('Retrieved pin data for ID $pinId: $pinData');

      final pinLat = _toDouble(pinData['latitude']);
      final pinLng = _toDouble(pinData['longitude']);

      return Pin(
        location: pinData['location'] ?? '',
        flagEmoji: pinData['mood'] ?? '📍',
        title: pinData['title'] ?? '',
        emoji: pinData['mood'] ?? '📍',
        id: pinId, // Use the passed pinId parameter, not from data
        latitude: pinLat,
        longitude: pinLng,
        imageUrl: (pinData['photoUrls'] as List<dynamic>?)?.isNotEmpty == true
            ? pinData['photoUrls'][0]
            : '',
        moodIconUrl: pinData['moodIconUrl'] ?? pinData['mood'] ?? '📍',
        photoCount: (pinData['photoUrls'] as List<dynamic>?)?.length ?? 0,
        audioCount: (pinData['audioUrls'] as List<dynamic>?)?.length ?? 0,
        imageUrls: List<String>.from(pinData['photoUrls'] ?? []),
        viewsCount: pinData['views'] ?? 0,
        playsCount: pinData['plays'] ?? 0,
        description: pinData['description'] ?? '',
        audioUrls: List<String>.from(pinData['audioUrls'] ?? []),
        createdAt: pinData['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(pinData['timestamp'])
            : null,
      );
    } catch (e) {
      print('Error getting pin by ID $pinId: $e');
      return null; // Return null instead of throwing to prevent crashes
    }
  }

  /// Increment pin views
  Future<void> incrementPinViews(String pinId) async {
    try {
      final ref = _pinsRef.child(pinId).child('views');
      final snapshot = await ref.get();
      final currentViews = snapshot.value as int? ?? 0;
      await ref.set(currentViews + 1);
    } catch (e) {
      print('Failed to increment pin views: $e');
    }
  }

  // ========== TAPU OPERATIONS ==========

  /// Create a new tapu
  Future<String> createTapu({
    required String title,
    required String description,
    required String mood,
    required double latitude,
    required double longitude,
    required String location,
    required List<String> photoUrls,
    required List<String> pinIds,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      final tapuId = _tapusRef.push().key!;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final tapuData = {
        'tapuId': tapuId,
        'userId': userId,
        'title': title,
        'description': description,
        'mood': mood,
        'latitude': latitude,
        'longitude': longitude,
        'location': location,
        'photoUrls': photoUrls,
        'pinIds': pinIds,
        'timestamp': timestamp,
        'totalPins': pinIds.length,
        'views': 0,
      };

      await _tapusRef.child(tapuId).set(tapuData);

      // Update user's created tapus
      await _usersRef.child(userId).child('createdTapuIds').push().set(tapuId);

      return tapuId;
    } catch (e) {
      throw Exception('Failed to create tapu: $e');
    }
  }

  /// Get user's tapus
  Future<List<Tapus>> getUserTapus({String? userId}) async {
    try {
      final targetUserId = userId ?? currentUserId;
      if (targetUserId == null) throw Exception('User not authenticated');

      final snapshot =
          await _tapusRef.orderByChild('userId').equalTo(targetUserId).get();

      if (!snapshot.exists) return [];

      final List<Tapus> userTapus = [];

      for (final child in snapshot.children) {
        final tapuData = child.value as Map<dynamic, dynamic>;

        final tapu = Tapus(
          id: tapuData['tapuId'] ?? '',
          name: tapuData['title'] ?? '',
          avatarUrl:
              (tapuData['photoUrls'] as List<dynamic>?)?.isNotEmpty == true
                  ? tapuData['photoUrls'][0]
                  : '',
          centerPinImageUrl:
              (tapuData['photoUrls'] as List<dynamic>?)?.isNotEmpty == true
                  ? tapuData['photoUrls'][0]
                  : '',
          centerCoordinates: MapCoordinates(
            latitude: tapuData['latitude'] ?? 0.0,
            longitude: tapuData['longitude'] ?? 0.0,
          ),
          totalPins: tapuData['totalPins'] ?? 0,
        );
        userTapus.add(tapu);
      }

      return userTapus;
    } catch (e) {
      throw Exception('Failed to get user tapus: $e');
    }
  }

  /// Get tapu by ID
  Future<Tapus?> getTapuById(String tapuId) async {
    try {
      final snapshot = await _tapusRef.child(tapuId).get();

      if (!snapshot.exists) return null;

      final tapuData = snapshot.value as Map<dynamic, dynamic>;

      return Tapus(
        id: tapuData['tapuId'] ?? '',
        name: tapuData['title'] ?? '',
        avatarUrl: (tapuData['photoUrls'] as List<dynamic>?)?.isNotEmpty == true
            ? tapuData['photoUrls'][0]
            : '',
        centerPinImageUrl:
            (tapuData['photoUrls'] as List<dynamic>?)?.isNotEmpty == true
                ? tapuData['photoUrls'][0]
                : '',
        centerCoordinates: MapCoordinates(
          latitude: tapuData['latitude'] ?? 0.0,
          longitude: tapuData['longitude'] ?? 0.0,
        ),
        totalPins: tapuData['totalPins'] ?? 0,
      );
    } catch (e) {
      throw Exception('Failed to get tapu: $e');
    }
  }

  // ========== SAVED PINS OPERATIONS ==========

  /// Save a pin for the current user
  Future<void> savePin(String pinId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Add to user's saved pins
      await _usersRef.child(userId).child('savedPinIds').push().set(pinId);

      // Add user to pin's saved by list
      await _pinsRef.child(pinId).child('savedByUsers').push().set(userId);
    } catch (e) {
      throw Exception('Failed to save pin: $e');
    }
  }

  /// Unsave a pin
  Future<void> unsavePin(String pinId) async {
    try {
      final userId = currentUserId;
      if (userId == null) throw Exception('User not authenticated');

      // Remove from user's saved pins
      final userSavedSnapshot =
          await _usersRef.child(userId).child('savedPinIds').get();
      if (userSavedSnapshot.exists) {
        for (final child in userSavedSnapshot.children) {
          if (child.value == pinId) {
            await child.ref.remove();
            break;
          }
        }
      }

      // Remove user from pin's saved by list
      final pinSavedSnapshot =
          await _pinsRef.child(pinId).child('savedByUsers').get();
      if (pinSavedSnapshot.exists) {
        for (final child in pinSavedSnapshot.children) {
          if (child.value == userId) {
            await child.ref.remove();
            break;
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to unsave pin: $e');
    }
  }

  /// Get user's saved pins
  Future<List<Pin>> getSavedPins() async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        print('User not authenticated');
        return [];
      }

      final snapshot = await _usersRef.child(userId).child('savedPinIds').get();

      if (!snapshot.exists) {
        print('No saved pins found for user: $userId');
        return [];
      }

      print(
          'Found ${snapshot.children.length} saved pin IDs for user: $userId');
      final List<Pin> savedPins = [];

      for (final child in snapshot.children) {
        final pinId = child.value as String?;
        print('Processing saved pin ID: $pinId');

        if (pinId != null && pinId.isNotEmpty) {
          final pin = await getPinById(pinId);
          if (pin != null) {
            print(
                'Successfully retrieved pin: ${pin.title} with ${pin.imageUrls.length} images');
            savedPins.add(pin);
          } else {
            print('Failed to retrieve pin with ID: $pinId');
          }
        } else {
          print('Invalid pin ID found: $pinId');
        }
      }

      print('Returning ${savedPins.length} saved pins');
      return savedPins;
    } catch (e) {
      print('Error getting saved pins: $e');
      return []; // Return empty list instead of throwing
    }
  }

  /// Check if pin is saved by current user
  Future<bool> isPinSaved(String pinId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return false;

      final snapshot = await _usersRef.child(userId).child('savedPinIds').get();

      if (!snapshot.exists) return false;

      for (final child in snapshot.children) {
        if (child.value == pinId) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  // ========== REAL-TIME LISTENERS ==========

  /// Listen to nearby pins in real-time
  Stream<List<Pin>> listenToNearbyPins({
    required double userLatitude,
    required double userLongitude,
    required double radiusInKm,
  }) {
    return _pinsRef.onValue.map((event) {
      if (!event.snapshot.exists) return [];
      final List<Pin> nearbyPins = [];
      for (final child in event.snapshot.children) {
        final pinData = child.value as Map<dynamic, dynamic>;
        if (pinData['isPublic'] == false) continue;
        final pinLat = _toDouble(pinData['latitude']);
        final pinLng = _toDouble(pinData['longitude']);
        final distance = Geolocator.distanceBetween(
              userLatitude,
              userLongitude,
              pinLat,
              pinLng,
            ) /
            1000;
        if (distance <= radiusInKm) {
          final pin = Pin(
            location: pinData['location'] ?? '',
            flagEmoji: pinData['mood'] ?? '📍',
            title: pinData['title'] ?? '',
            emoji: pinData['mood'] ?? '📍',
            id: pinData['pinId'] ?? child.key ?? '',
            latitude: pinLat,
            longitude: pinLng,
            imageUrl:
                (pinData['photoUrls'] as List<dynamic>?)?.isNotEmpty == true
                    ? pinData['photoUrls'][0]
                    : '',
            moodIconUrl: pinData['moodIconUrl'] ??
                pinData['mood'] ??
                '📍', // Use moodIconUrl first, fallback to mood
            photoCount: (pinData['photoUrls'] as List<dynamic>?)?.length ?? 0,
            audioCount: (pinData['audioUrls'] as List<dynamic>?)?.length ?? 0,
            imageUrls: List<String>.from(pinData['photoUrls'] ?? []),
            viewsCount: pinData['views'] ?? 0,
            playsCount: pinData['plays'] ?? 0,
            description: pinData['description'] ?? '',
            audioUrls: List<String>.from(pinData['audioUrls'] ?? []),
            createdAt: pinData['timestamp'] != null
                ? DateTime.fromMillisecondsSinceEpoch(pinData['timestamp'])
                : null,
          );
          nearbyPins.add(pin);
        }
      }
      return nearbyPins;
    });
  }
}
