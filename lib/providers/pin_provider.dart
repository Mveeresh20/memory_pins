import 'package:flutter/foundation.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/services/firebase_service.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PinProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();

  // State variables
  List<Pin> _nearbyPins = [];
  List<Pin> _userPins = [];
  List<Pin> _savedPins = [];
  List<Pin> _filteredPins = [];
  bool _isLoading = false;
  String? _error;
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  double _filterRadius = 5.0; // Default 5km radius
  String _filterType = 'nearby'; // 'nearby' or 'far'

  // Getters
  List<Pin> get nearbyPins => _nearbyPins;
  List<Pin> get userPins => _userPins;
  List<Pin> get savedPins => _savedPins;
  List<Pin> get filteredPins => _filteredPins;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get currentLatitude => _currentLatitude;
  double get currentLongitude => _currentLongitude;
  double get filterRadius => _filterRadius;
  String get filterType => _filterType;

  // Initialize provider
  Future<void> initialize() async {
    await _getCurrentLocation();
    await loadNearbyPins();
    await loadUserPins();
    await loadSavedPins();
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

  // Load nearby pins
  Future<void> loadNearbyPins() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _nearbyPins = await _firebaseService.getNearbyPins(
        userLatitude: _currentLatitude,
        userLongitude: _currentLongitude,
        radiusInKm: _filterRadius,
      );

      _applyFilters();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load nearby pins: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load user's own pins
  Future<void> loadUserPins() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _userPins = await _firebaseService.getUserPins();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user pins: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load saved pins
  Future<void> loadSavedPins() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _savedPins = await _firebaseService.getSavedPins();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load saved pins: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new pin
  Future<bool> createPin({
    required String title,
    required String description,
    required String mood,
    required List<String> photoUrls,
    required List<String> audioUrls,
    double? latitude,
    double? longitude,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Creating pin with:');
      print('Title: $title');
      print('Description: $description');
      print('Mood: $mood');
      print('Photo URLs: $photoUrls');
      print('Audio URLs: $audioUrls');
      print('Latitude: $latitude');
      print('Longitude: $longitude');

      // Use provided coordinates or fall back to current location
      final pinLatitude = latitude ?? _currentLatitude;
      final pinLongitude = longitude ?? _currentLongitude;

      final pinId = await _firebaseService.createPin(
        title: title,
        description: description,
        mood: mood,
        latitude: pinLatitude,
        longitude: pinLongitude,
        location: await _getLocationName(pinLatitude, pinLongitude),
        photoUrls: photoUrls,
        audioUrls: audioUrls,
      );

      print('Pin created with ID: $pinId');

      // Reload user pins to include the new pin
      await loadUserPins();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create pin: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Save a pin
  Future<void> savePin(String pinId) async {
    try {
      await _firebaseService.savePin(pinId);
      await loadSavedPins(); // Reload saved pins
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save pin: $e';
      notifyListeners();
    }
  }

  // Unsave a pin
  Future<void> unsavePin(String pinId) async {
    try {
      await _firebaseService.unsavePin(pinId);
      await loadSavedPins(); // Reload saved pins
      notifyListeners();
    } catch (e) {
      _error = 'Failed to unsave pin: $e';
      notifyListeners();
    }
  }

  // Check if pin is saved
  Future<bool> isPinSaved(String pinId) async {
    try {
      return await _firebaseService.isPinSaved(pinId);
    } catch (e) {
      return false;
    }
  }

  // Increment pin views
  Future<void> incrementPinViews(String pinId) async {
    try {
      await _firebaseService.incrementPinViews(pinId);
      // Reload nearby pins to get updated view count
      await loadNearbyPins();
    } catch (e) {
      print('Failed to increment pin views: $e');
    }
  }

  // Set filter radius
  void setFilterRadius(double radius) {
    _filterRadius = radius;
    _applyFilters();
    notifyListeners();
  }

  // Set filter type
  void setFilterType(String type) {
    _filterType = type;
    _applyFilters();
    notifyListeners();
  }

  // Apply filters to nearby pins
  void _applyFilters() {
    if (_filterType == 'nearby') {
      // Show pins within 0-5KM range
      _filteredPins = _nearbyPins.where((pin) {
        final distance = Geolocator.distanceBetween(
              _currentLatitude,
              _currentLongitude,
              pin.latitude,
              pin.longitude,
            ) /
            1000; // Convert to km
        return distance >= 0 && distance <= 5.0; // 0-5KM range
      }).toList();
    } else if (_filterType == 'far') {
      // Show pins within 5-30KM range
      _filteredPins = _nearbyPins.where((pin) {
        final distance = Geolocator.distanceBetween(
              _currentLatitude,
              _currentLongitude,
              pin.latitude,
              pin.longitude,
            ) /
            1000; // Convert to km
        return distance > 5.0 && distance <= 30.0; // 5-30KM range
      }).toList();
    } else {
      _filteredPins = _nearbyPins;
    }

    print('Filter applied: $_filterType');
    print('Total pins: ${_nearbyPins.length}');
    print('Filtered pins: ${_filteredPins.length}');
  }

  // Filter pins by month
  List<Pin> filterPinsByMonth(List<Pin> pins, DateTime month) {
    return pins.where((pin) {
      // If pin doesn't have createdAt, include it (for backward compatibility)
      if (pin.createdAt == null) {
        return true;
      }

      // Check if pin was created in the specified month and year
      final pinCreatedAt = pin.createdAt!;
      return pinCreatedAt.year == month.year &&
          pinCreatedAt.month == month.month;
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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refresh() async {
    await _getCurrentLocation();
    await loadNearbyPins();
    await loadUserPins();
    await loadSavedPins();
  }

  // Get pin by ID
  Future<Pin?> getPinById(String pinId) async {
    try {
      return await _firebaseService.getPinById(pinId);
    } catch (e) {
      _error = 'Failed to get pin: $e';
      notifyListeners();
      return null;
    }
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

  // Get formatted distance for a specific pin from current location
  String getPinDistance(Pin pin) {
    final distanceInKm = getDistance(
        _currentLatitude, _currentLongitude, pin.latitude, pin.longitude);
    final formattedDistance = getFormattedDistance(distanceInKm);
    return '$formattedDistance away';
  }
}
