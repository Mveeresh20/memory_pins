import 'package:flutter/foundation.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/services/firebase_service.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:memory_pins_app/utills/Constants/performance_monitor.dart';
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
  bool _isInitialized = false;
  String? _error;
  double _currentLatitude = 0.0;
  double _currentLongitude = 0.0;
  double _filterRadius = 5.0; // Default 5km radius
  String _filterType = 'nearby'; // 'nearby' or 'far'

  // Cache for distance calculations
  Map<String, double> _distanceCache = {};
  Map<String, String> _distanceTextCache = {};

  // Getters
  List<Pin> get nearbyPins => _nearbyPins;
  List<Pin> get userPins => _userPins;
  List<Pin> get savedPins => _savedPins;
  List<Pin> get filteredPins => _filteredPins;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;
  double get currentLatitude => _currentLatitude;
  double get currentLongitude => _currentLongitude;
  double get filterRadius => _filterRadius;
  String get filterType => _filterType;

  // Initialize provider with lazy loading
  Future<void> initialize() async {
    if (_isInitialized) {
      print('PinProvider - Already initialized, skipping...');
      return;
    }

    return PerformanceMonitor.timeAsync('PinProvider.initialize', () async {
      try {
        print('PinProvider - Starting initialization...');
        _isLoading = true;
        _error = null;
        notifyListeners();

        // Get current location first
        print('PinProvider - Getting current location...');
        await _getCurrentLocation();
        print(
            'PinProvider - Current location: $_currentLatitude, $_currentLongitude');

        // Load only nearby pins initially (most important for home screen)
        print('PinProvider - Loading nearby pins...');
        await loadNearbyPins();
        print('PinProvider - Loaded ${_nearbyPins.length} nearby pins');

        _isInitialized = true;
        _isLoading = false;
        print('PinProvider - Initialization completed successfully');
        notifyListeners();

        // Load other data in background
        print('PinProvider - Starting background data loading...');
        _loadBackgroundData();
      } catch (e) {
        print('PinProvider - Initialization failed: $e');
        _error = 'Failed to initialize: $e';
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // Load non-critical data in background
  Future<void> _loadBackgroundData() async {
    try {
      // Load user pins and saved pins in parallel
      await Future.wait([
        loadUserPins(),
        loadSavedPins(),
      ]);
    } catch (e) {
      print('Background data loading failed: $e');
    }
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

  // Load nearby pins with optimized filtering
  Future<void> loadNearbyPins() async {
    return PerformanceMonitor.timeAsync('PinProvider.loadNearbyPins', () async {
      try {
        _isLoading = true;
        _error = null;
        notifyListeners();

        _nearbyPins = await _firebaseService.getNearbyPins(
          userLatitude: _currentLatitude,
          userLongitude: _currentLongitude,
          radiusInKm: 30.0, // Fetch up to 30KM for both filters
        );

        // Pre-calculate distances for all pins
        _precalculateDistances();

        _applyFilters();
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _error = 'Failed to load nearby pins: $e';
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  // Pre-calculate distances for all pins to avoid repeated calculations
  void _precalculateDistances() {
    PerformanceMonitor.startTimer('PinProvider.precalculateDistances');

    _distanceCache.clear();
    _distanceTextCache.clear();

    for (final pin in _nearbyPins) {
      final distance = Geolocator.distanceBetween(
            _currentLatitude,
            _currentLongitude,
            pin.latitude,
            pin.longitude,
          ) /
          1000; // Convert to km

      _distanceCache[pin.id] = distance;
      _distanceTextCache[pin.id] = getFormattedDistance(distance);
    }

    PerformanceMonitor.endTimer('PinProvider.precalculateDistances');
  }

  // Load user's own pins
  Future<void> loadUserPins() async {
    try {
      _userPins = await _firebaseService.getUserPins();
      notifyListeners();
    } catch (e) {
      print('Failed to load user pins: $e');
    }
  }

  // Load saved pins
  Future<void> loadSavedPins() async {
    try {
      _savedPins = await _firebaseService.getSavedPins();
      notifyListeners();
    } catch (e) {
      print('Failed to load saved pins: $e');
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

  // Delete a pin
  Future<bool> deletePin(String pinId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _firebaseService.deletePin(pinId);

      if (success) {
        // Remove the pin from local lists
        _userPins.removeWhere((pin) => pin.id == pinId);
        _savedPins.removeWhere((pin) => pin.id == pinId);
        _nearbyPins.removeWhere((pin) => pin.id == pinId);
        _filteredPins.removeWhere((pin) => pin.id == pinId);

        // Clear distance cache for this pin
        _distanceCache.remove(pinId);
        _distanceTextCache.remove(pinId);
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to delete pin: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Increment pin views
  Future<void> incrementPinViews(String pinId) async {
    try {
      await _firebaseService.incrementPinViews(pinId);
      // Update the pin in memory instead of reloading all
      final pinIndex = _nearbyPins.indexWhere((pin) => pin.id == pinId);
      if (pinIndex != -1) {
        _nearbyPins[pinIndex] = _nearbyPins[pinIndex].copyWith(
          viewsCount: _nearbyPins[pinIndex].viewsCount + 1,
        );
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      print('Failed to increment pin views: $e');
    }
  }

  // Increment pin plays
  Future<void> incrementPinPlays(String pinId) async {
    try {
      await _firebaseService.incrementPinPlays(pinId);
      // Update the pin in memory instead of reloading all
      final pinIndex = _nearbyPins.indexWhere((pin) => pin.id == pinId);
      if (pinIndex != -1) {
        _nearbyPins[pinIndex] = _nearbyPins[pinIndex].copyWith(
          playsCount: _nearbyPins[pinIndex].playsCount + 1,
        );
        _applyFilters();
        notifyListeners();
      }
    } catch (e) {
      print('Failed to increment pin plays: $e');
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
    print('PinProvider - Setting filter type to: $type');
    _filterType = type;

    // Ensure distances are calculated before applying filters
    if (_distanceCache.isEmpty && _nearbyPins.isNotEmpty) {
      print(
          'PinProvider - Distance cache is empty, calculating distances first...');
      _precalculateDistances();
    }

    _applyFilters();
    print('PinProvider - Filter applied, notifying listeners...');
    notifyListeners();

    // Force a small delay to ensure UI updates
    Future.delayed(Duration(milliseconds: 100), () {
      print('PinProvider - Delayed notification after filter change');
      notifyListeners();
    });
  }

  // Apply filters to nearby pins using cached distances
  void _applyFilters() {
    print('PinProvider - Applying filters...');
    print('Filter type: $_filterType');
    print('Total nearby pins: ${_nearbyPins.length}');
    print('Distance cache size: ${_distanceCache.length}');

    if (_filterType == 'nearby') {
      // Show pins within 0-5KM range
      _filteredPins = _nearbyPins.where((pin) {
        final distance = _distanceCache[pin.id] ?? 0.0;
        final isInRange = distance >= 0 && distance <= 5.0;
        if (isInRange) {
          print(
              'Pin ${pin.title} included in nearby filter (distance: ${distance.toStringAsFixed(2)}km)');
        }
        return isInRange;
      }).toList();
    } else if (_filterType == 'far') {
      // Show pins within 5-30KM range
      _filteredPins = _nearbyPins.where((pin) {
        final distance = _distanceCache[pin.id] ?? 0.0;
        final isInRange = distance > 5.0 && distance <= 30.0;
        if (isInRange) {
          print(
              'Pin ${pin.title} included in far filter (distance: ${distance.toStringAsFixed(2)}km)');
        }
        return isInRange;
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
    _isInitialized = false;
    _distanceCache.clear();
    _distanceTextCache.clear();
    await initialize();
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

  // Get formatted distance for a specific pin from current location (cached)
  String getPinDistance(Pin pin) {
    return _distanceTextCache[pin.id] ?? 'Unknown distance';
  }

  // Get cached distance for a pin
  double getCachedDistance(Pin pin) {
    return _distanceCache[pin.id] ?? 0.0;
  }
}
