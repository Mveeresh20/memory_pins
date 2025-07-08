import 'package:flutter/foundation.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/models/pin.dart';
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
  List<Pin> _tapuPins = []; // Pins within a selected Tapu
  bool _isLoading = false;
  String? _error;
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;

  // Getters
  List<Tapus> get userTapus => _userTapus;
  List<Tapus> get allTapus => _allTapus;
  List<Pin> get tapuPins => _tapuPins;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get currentLatitude => _currentLatitude;
  double get currentLongitude => _currentLongitude;

  // Initialize provider
  Future<void> initialize() async {
    await _getCurrentLocation();
    await loadUserTapus();
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
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final tapuId = await _firebaseService.createTapu(
        title: title,
        description: description,
        mood: mood,
        latitude: _currentLatitude,
        longitude: _currentLongitude,
        location: await _getLocationName(_currentLatitude, _currentLongitude),
        photoUrls: photoUrls,
        pinIds: pinIds,
      );

      // Reload user tapus to include the new tapu
      await loadUserTapus();

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

  // Get distance between two points
  double getDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) /
        1000; // Convert to km
  }

  // Get formatted distance string
  String getFormattedDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()}m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  }

  // Get tapus near current location
  Future<List<Tapus>> getNearbyTapus(double radiusInKm) async {
    try {
      final List<Tapus> nearbyTapus = [];

      for (final tapu in _userTapus) {
        final distance = Geolocator.distanceBetween(
              _currentLatitude,
              _currentLongitude,
              tapu.centerCoordinates.latitude,
              tapu.centerCoordinates.longitude,
            ) /
            1000; // Convert to km

        if (distance <= radiusInKm) {
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
