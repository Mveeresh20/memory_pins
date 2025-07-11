import 'package:flutter/foundation.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/models/tapu.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/models/map_cordinates.dart';
import 'package:memory_pins_app/services/firebase_service.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class TapuProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();

  // State variables
  List<Tapus> _userTapus = [];
  List<Tapus> _allTapus = [];
  List<Tapu> _nearbyTapus = []; // New list for nearby tapus
  List<Pin> _tapuPins = []; // Pins within a selected Tapu
  bool _isLoading = false;
  String? _error;
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  double _tapuRadius = 50.0;

  // Getters
  List<Tapus> get userTapus => _userTapus;
  List<Tapus> get allTapus => _allTapus;
  List<Tapu> get nearbyTapus => _nearbyTapus;
  List<Pin> get tapuPins => _tapuPins;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get currentLatitude => _currentLatitude;
  double get currentLongitude => _currentLongitude;
  double get tapuRadius => _tapuRadius;

  // Initialize provider
  Future<void> initialize() async {
    await _getCurrentLocation();
    await loadUserTapus();
    await loadNearbyTapus(_tapuRadius);
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      _currentLatitude = position?.latitude ?? 0.0;
      _currentLongitude = position?.longitude ?? 0.0;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to get current location: $e';
      notifyListeners();
    }
  }

  // Load user's tapus
  Future<void> loadUserTapus() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _userTapus = await _firebaseService.getUserTapus();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user tapus: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new tapu
  Future<bool> createTapu({
    required String title,
    required String description,
    required String mood,
    required List<String> photoUrls,
    required List<String> pinIds,
    List<String>? emojis,
    double? latitude, // Add latitude parameter
    double? longitude, // Add longitude parameter
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get current location if not provided
      if (latitude == null || longitude == null) {
        await _getCurrentLocation();
        latitude = _currentLatitude;
        longitude = _currentLongitude;
      }

      if (latitude == null || longitude == null) {
        throw Exception('Location not available');
      }

      print('Creating Tapu at location: $latitude, $longitude');

      // Create tapu in Firebase
      final tapuId = await _firebaseService.createTapu(
        title: title,
        description: description,
        mood: mood,
        latitude: latitude,
        longitude: longitude,
        location: await _getLocationName(latitude, longitude),
        photoUrls: photoUrls,
        pinIds: pinIds,
        emojis: emojis ?? [mood], // Use provided emojis or fallback to mood
      );

      print('Tapu created with ID: $tapuId at location: $latitude, $longitude');

      // Reload nearby tapus to include the new tapu
      await loadNearbyTapus(50.0);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create tapu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get tapu by ID
  Future<Tapus?> getTapuById(String tapuId) async {
    try {
      return await _firebaseService.getTapuById(tapuId);
    } catch (e) {
      _error = 'Failed to get tapu: $e';
      notifyListeners();
      return null;
    }
  }

  // Load pins within a tapu
  Future<void> loadTapuPins(String tapuId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final tapu = await _firebaseService.getTapuById(tapuId);
      if (tapu != null) {
        _tapuPins = [];
        // You'll need to implement getPinsByIds in FirebaseService
        // For now, this is a placeholder
        // _tapuPins = await _firebaseService.getPinsByIds(tapu.pinIds);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load tapu pins: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add pin to tapu
  Future<bool> addPinToTapu(String tapuId, String pinId) async {
    try {
      // You'll need to implement this in FirebaseService
      // await _firebaseService.addPinToTapu(tapuId, pinId);

      // Reload tapu pins
      await loadTapuPins(tapuId);

      return true;
    } catch (e) {
      _error = 'Failed to add pin to tapu: $e';
      notifyListeners();
      return false;
    }
  }

  // Remove pin from tapu
  Future<bool> removePinFromTapu(String tapuId, String pinId) async {
    try {
      // You'll need to implement this in FirebaseService
      // await _firebaseService.removePinFromTapu(tapuId, pinId);

      // Reload tapu pins
      await loadTapuPins(tapuId);

      return true;
    } catch (e) {
      _error = 'Failed to remove pin from tapu: $e';
      notifyListeners();
      return false;
    }
  }

  // Get tapus by month
  List<Tapus> filterTapusByMonth(List<Tapus> tapus, DateTime month) {
    return tapus.where((tapu) {
      // You'll need to add timestamp to your Tapus model
      // For now, this is a placeholder
      return true;
    }).toList();
  }

  // Get location name from coordinates
  Future<String> _getLocationName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}'
            .trim();
      }

      return 'Unknown Location';
    } catch (e) {
      return 'Unknown Location';
    }
  }

  // Calculate tapu center coordinates from pins

  // Load nearby tapus within specified radius (0-50KM range)
  Future<void> loadNearbyTapus(double radiusInKm) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
          'Loading nearby tapus within ${radiusInKm}KM from current location: $_currentLatitude, $_currentLongitude');

      // Get all tapus from Firebase (not just user tapus)
      final allTapus = await _firebaseService.getAllTapus();
      print('Found ${allTapus.length} total tapus in Firebase');

      // Filter tapus within 0-50KM range and calculate statistics
      _nearbyTapus = [];
      for (final tapus in allTapus) {
        final distance = getDistance(
          _currentLatitude,
          _currentLongitude,
          tapus.centerCoordinates.latitude,
          tapus.centerCoordinates.longitude,
        );

        print('Tapu "${tapus.name}" distance check:');
        print('  Current location: $_currentLatitude, $_currentLongitude');
        print(
            '  Tapu location: ${tapus.centerCoordinates.latitude}, ${tapus.centerCoordinates.longitude}');
        print('  Calculated distance: ${distance.toStringAsFixed(3)}km');
        print('  Radius limit: ${radiusInKm}km');
        print('  Within range: ${distance >= 0 && distance <= radiusInKm}');

        // Show tapus within 0-50KM range
        if (distance >= 0 && distance <= radiusInKm) {
          print(
              'Adding tapu "${tapus.name}" to nearby list (${distance.toStringAsFixed(1)}km)');
          print('  Tapus emojis: ${tapus.emojis}');

          // Calculate statistics from surrounding pins
          final statistics = await _calculateTapuStatistics(tapus);

          // Convert Tapus to Tapu with calculated statistics
          final enhancedTapu = Tapu(
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
            totalPins: statistics.pinCount,
            views: statistics.viewsCount,
          );

          print('  Enhanced Tapu photoUrls: ${enhancedTapu.photoUrls}');
          _nearbyTapus.add(enhancedTapu);
        } else {
          print(
              'Tapu "${tapus.name}" is outside the ${radiusInKm}km range (${distance.toStringAsFixed(1)}km)');
        }
      }

      print('Loaded ${_nearbyTapus.length} tapus within ${radiusInKm}KM range');

      // Sort by distance
      _nearbyTapus.sort((a, b) {
        final distanceA = getDistance(
            _currentLatitude, _currentLongitude, a.latitude, a.longitude);
        final distanceB = getDistance(
            _currentLatitude, _currentLongitude, b.latitude, b.longitude);
        return distanceA.compareTo(distanceB);
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load nearby tapus: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate statistics from surrounding pins within 5KM
  Future<MapDetailCardData> _calculateTapuStatistics(Tapus tapu) async {
    try {
      // Get all pins from Firebase
      final allPins = await _firebaseService.getNearbyPins(
        userLatitude: _currentLatitude ?? 0.0,
        userLongitude: _currentLongitude ?? 0.0,
        radiusInKm: 30.0, // Get all pins within 30KM, then filter
      );

      // Filter pins within 5KM of the tapu
      final nearbyPins = allPins.where((pin) {
        final distance = getDistance(
          tapu.centerCoordinates.latitude,
          tapu.centerCoordinates.longitude,
          pin.latitude,
          pin.longitude,
        );
        return distance <= 5.0; // Within 5KM
      }).toList();

      // Calculate statistics
      int totalPins = nearbyPins.length;
      int totalImages = 0;
      int totalAudios = 0;
      int totalViews = 0;

      for (final pin in nearbyPins) {
        totalImages += pin.photoCount;
        totalAudios += pin.audioCount;
        totalViews += pin.viewsCount;
      }

      // Get distance from current location to tapu (same as PinProvider)
      final distanceInKm = getDistance(
        _currentLatitude,
        _currentLongitude,
        tapu.centerCoordinates.latitude,
        tapu.centerCoordinates.longitude,
      );

      // Use the same logic as PinProvider for distance formatting
      double distanceValue;
      String distanceUnit;
      if (distanceInKm < 1) {
        distanceValue = (distanceInKm * 1000).round().toDouble();
        distanceUnit = 'm';
      } else {
        distanceValue = distanceInKm;
        distanceUnit = 'km';
      }

      return MapDetailCardData(
        distance: distanceValue,
        distanceUnit: distanceUnit,
        title: tapu.name,
        pinCount: totalPins,
        imageCount: totalImages,
        audioCount: totalAudios,
        viewsCount: totalViews,
        reactionEmojis: [],
        playsCount: 0,
      );
    } catch (e) {
      print('Error calculating tapu statistics: $e');
      return MapDetailCardData(
        playsCount: 0,
        distance: 0.0,
        distanceUnit: 'km',
        title: tapu.name,
        pinCount: 0,
        imageCount: 0,
        audioCount: 0,
        viewsCount: 0,
        reactionEmojis: [],
      );
    }
  }

  // Get MapDetailCardData for a tapu (exactly like pin distance calculation)
  MapDetailCardData getTapuDetailCardData(Tapu tapu, List<Pin> pins) {
    final distanceInKm = getDistance(
        _currentLatitude, _currentLongitude, tapu.latitude, tapu.longitude);

    // Use the same logic as PinProvider for distance formatting
    double distanceValue;
    String distanceUnit;
    if (distanceInKm < 1) {
      distanceValue = (distanceInKm * 1000).round().toDouble();
      distanceUnit = 'm';
    } else {
      distanceValue = distanceInKm;
      distanceUnit = 'km';
    }

    // Calculate statistics from pins within 5KM of the tapu
    int totalImages = 0;
    int totalAudios = 0;
    int totalViews = 0;
    int totalPlays = 0;

    // Get pins within 5KM of the tapu
    for (final pin in pins) {
      final pinDistance = getDistance(
        tapu.latitude,
        tapu.longitude,
        pin.latitude,
        pin.longitude,
      );

      if (pinDistance <= 5.0) {
        // Within 5KM of tapu
        totalImages += pin.photoCount;
        totalAudios += pin.audioCount;
        totalViews += pin.viewsCount;
        totalPlays += pin.playsCount;
      }
    }

    print(
        'Tapu "${tapu.title}" statistics: $totalImages images, $totalAudios audios, $totalViews views, $totalPlays plays');

    return MapDetailCardData(
      distance: distanceValue,
      distanceUnit: distanceUnit,
      title: tapu.title,
      pinCount: tapu.totalPins,
      imageCount: totalImages,
      audioCount: totalAudios,
      reactionEmojis: tapu.photoUrls.isNotEmpty
          ? tapu.photoUrls
          : [
              tapu.moodIconUrl
            ], // Use photo URLs as emojis or fallback to mood icon
      viewsCount: totalViews,
      playsCount: totalPlays,
    );
  }

  // Load pins within tapu radius (5KM)
  Future<List<Pin>> loadPinsAroundTapu(Tapus tapu) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print(
          'Loading pins around tapu "${tapu.name}" at location: ${tapu.centerCoordinates.latitude}, ${tapu.centerCoordinates.longitude}');

      // Get all pins from Firebase
      final allPins = await _firebaseService.getNearbyPins(
        userLatitude:
            tapu.centerCoordinates.latitude, // Use tapu center as reference
        userLongitude: tapu.centerCoordinates.longitude,
        radiusInKm: 30.0, // Get all pins within 30KM, then filter
      );

      // Filter pins within 5KM of the tapu center
      final nearbyPins = allPins.where((pin) {
        final distance = getDistance(
          tapu.centerCoordinates.latitude,
          tapu.centerCoordinates.longitude,
          pin.latitude,
          pin.longitude,
        );
        return distance <= 5.0; // Within 5KM of tapu center
      }).toList();

      print(
          'Found ${nearbyPins.length} pins within 5KM of tapu "${tapu.name}"');

      // Sort by distance from tapu center
      nearbyPins.sort((a, b) {
        final distanceA = getDistance(
          tapu.centerCoordinates.latitude,
          tapu.centerCoordinates.longitude,
          a.latitude,
          a.longitude,
        );
        final distanceB = getDistance(
          tapu.centerCoordinates.latitude,
          tapu.centerCoordinates.longitude,
          b.latitude,
          b.longitude,
        );
        return distanceA.compareTo(distanceB);
      });

      _tapuPins = nearbyPins;
      _isLoading = false;
      notifyListeners();

      return nearbyPins;
    } catch (e) {
      _error = 'Failed to load pins around tapu: $e';
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  // Get distance from tapu center to a pin
  String getPinDistanceFromTapu(Tapus tapu, Pin pin) {
    final distanceInKm = getDistance(
      tapu.centerCoordinates.latitude,
      tapu.centerCoordinates.longitude,
      pin.latitude,
      pin.longitude,
    );
    final formattedDistance = getFormattedDistance(distanceInKm);
    return '$formattedDistance from tapu';
  }

  // Load pins within tapu radius (5KM)

  // Get distance text for a tapu (exactly like pin distance)
  String getTapuDistanceText(Tapu tapu) {
    final distanceInKm = getDistance(
        _currentLatitude, _currentLongitude, tapu.latitude, tapu.longitude);
    final formattedDistance = getFormattedDistance(distanceInKm);
    print('Tapu "${tapu.title}" distance calculation:');
    print('  Current location: $_currentLatitude, $_currentLongitude');
    print('  Tapu location: ${tapu.latitude}, ${tapu.longitude}');
    print('  Raw distance: ${distanceInKm.toStringAsFixed(3)}km');
    print('  Formatted distance: $formattedDistance');
    return '$formattedDistance away';
  }

  Map<String, double> calculateTapuCenter(List<Pin> pins) {
    if (pins.isEmpty) {
      return {'latitude': _currentLatitude, 'longitude': _currentLongitude};
    }

    double totalLat = 0.0;
    double totalLng = 0.0;

    for (final pin in pins) {
      totalLat += pin.latitude;
      totalLng += pin.longitude;
    }

    return {
      'latitude': totalLat / pins.length,
      'longitude': totalLng / pins.length,
    };
  }

  // Get tapu statistics
  Map<String, dynamic> getTapuStatistics(Tapus tapu) {
    // You'll need to implement this based on your data structure
    return {
      'totalPins': tapu.totalPins,
      'totalPhotos': 0, // Calculate from pins
      'totalAudios': 0, // Calculate from pins
      'totalViews': 0, // Calculate from pins
      'averageDistance': 0.0, // Calculate from pins
    };
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    await _getCurrentLocation();
    await loadUserTapus();
  }

  // Get distance between two points (same as PinProvider)
  double getDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to km
  }

  // Get formatted distance string (same as PinProvider)
  String getFormattedDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()}m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  }

  // Get tapus near current location (0-50KM range)
  Future<List<Tapus>> getNearbyTapus(double radiusInKm) async {
    try {
      final List<Tapus> nearbyTapus = [];

      // Get all tapus from Firebase (not just user tapus)
      final allTapus = await _firebaseService.getAllTapus();

      for (final tapu in allTapus) {
        final distance = getDistance(
          _currentLatitude,
          _currentLongitude,
          tapu.centerCoordinates.latitude,
          tapu.centerCoordinates.longitude,
        );

        // Show tapus within 0-50KM range
        if (distance >= 0 && distance <= radiusInKm) {
          nearbyTapus.add(tapu);
        }
      }

      return nearbyTapus;
    } catch (e) {
      _error = 'Failed to get nearby tapus: $e';
      notifyListeners();
      return [];
    }
  }
}
