import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:memory_pins_app/services/location_permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';


class LocationService {
  final String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  final Distance _distance = const Distance();
  BuildContext? _context;
  
  // Cache keys
  static const String _lastLocationKey = 'last_location';
  static const String _searchCachePrefix = 'location_search_';
  
  // Singleton instance
  static LocationService? _instance;
  
  // Private constructor
  LocationService._();
  
  // Factory constructor
  factory LocationService() {
    _instance ??= LocationService._();
    return _instance!;
  }
  
  // Set context method
  void setContext(BuildContext context) {
    _context = context;
  }
  
  // Check if location permission is granted
  Future<bool> isLocationPermissionGranted() async {
    final status = await Geolocator.checkPermission();
    return status == LocationPermission.always || status == LocationPermission.whileInUse;
  }

  // Check if location permission is permanently denied
  Future<bool> isLocationPermissionPermanentlyDenied() async {
    final status = await Geolocator.checkPermission();
    return status == LocationPermission.deniedForever;
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
  
  // Get current location with caching
  Future<Position?> getCurrentLocation({bool useCache = true}) async {
    
    try {
      // First check if location services are enabled
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        await LocationPermissionHandler.showLocationServicesDialog( );
        return null;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      // If permission is denied, request it (this will show native dialog)
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      // If permission is permanently denied, show settings dialog
      if (permission == LocationPermission.deniedForever) {
        await LocationPermissionHandler.showLocationSettingsDialog( );
        return null;
      }
      
      // Try to get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Cache the location
      _cacheLastLocation(position);
      
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      
      // If using cache is allowed and there was an error, try to return cached location
      if (useCache) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final locationJson = prefs.getString(_lastLocationKey);
          
          if (locationJson != null) {
            final locationData = jsonDecode(locationJson);
            
            // Check if the cached location is not too old (24 hours)
            final timestamp = locationData['timestamp'] as int;
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - timestamp <= 24 * 60 * 60 * 1000) {
              // Instead of creating a Position object, just get a fresh position
              // This avoids issues with the Position constructor
              return await Geolocator.getLastKnownPosition();
            }
          }
        } catch (e) {
          print('Error retrieving cached location: $e');
        }
      }
      
      return null;
    }
  }
  
  // Cache the last known location
  Future<void> _cacheLastLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_lastLocationKey, jsonEncode(locationData));
    } catch (e) {
      print('Error caching location: $e');
    }
  }
  
  // Search for location using Nominatim with caching
  Future<List<Map<String, dynamic>>> searchLocation(String query, {bool useCache = true}) async {
    if (query.isEmpty) {
      return [];
    }
    
    // Check cache first if enabled
    if (useCache) {
      final cachedResults = await _getCachedSearch(query);
      if (cachedResults != null) {
        return cachedResults;
      }
    }
    
    try {
      // Add delay to respect Nominatim usage policy (1 request per second)
      await Future.delayed(Duration(milliseconds: 1000));
      
      final response = await http.get(
        Uri.parse('$_nominatimBaseUrl/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&addressdetails=1'),
        headers: {
          'User-Agent': 'EventSpot App',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );
      
      if (response.statusCode == 200) {
        List<dynamic> results = json.decode(response.body);
        final formattedResults = results.map((result) => {
          'displayName': result['display_name'],
          'latitude': double.parse(result['lat']),
          'longitude': double.parse(result['lon']),
          'type': result['type'],
          'placeId': result['place_id'],
          'address': {
            'city': result['address']?['city'] ?? result['address']?['town'] ?? result['address']?['village'],
            'state': result['address']?['state'],
            'country': result['address']?['country'],
            'postcode': result['address']?['postcode'],
            'road': result['address']?['road'],
            'houseNumber': result['address']?['house_number'],
            'neighbourhood': result['address']?['neighbourhood'],
          }
        }).toList();
        
        // Cache the results
        if (useCache) {
          _cacheSearchResults(query, formattedResults);
        }
        
        return formattedResults;
      } else {
        print('Error searching location: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception searching location: $e');
      return [];
    }
  }
  
  // Cache search results
  Future<void> _cacheSearchResults(String query, List<Map<String, dynamic>> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _searchCachePrefix + query.toLowerCase();
      final cacheData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'results': results,
      };
      
      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      print('Error caching search results: $e');
    }
  }
  
  // Get cached search results
  Future<List<Map<String, dynamic>>?> _getCachedSearch(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _searchCachePrefix + query.toLowerCase();
      final cacheJson = prefs.getString(cacheKey);
      
      if (cacheJson == null) {
        return null;
      }
      
      final cacheData = jsonDecode(cacheJson);
      
      // Check if the cache is not too old (1 hour)
      final timestamp = cacheData['timestamp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > 60 * 60 * 1000) {
        return null;
      }
      
      return (cacheData['results'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error retrieving cached search: $e');
      return null;
    }
  }
  
  // Reverse geocode (get address from coordinates) with caching
  Future<Map<String, dynamic>?> reverseGeocode(double latitude, double longitude, {bool useCache = true}) async {
    // Create a cache key based on coordinates (rounded to 5 decimal places for better cache hits)
    final cacheKey = _searchCachePrefix + 'reverse_${latitude.toStringAsFixed(5)}_${longitude.toStringAsFixed(5)}';
    
    // Check cache first if enabled
    if (useCache) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final cacheJson = prefs.getString(cacheKey);
        
        if (cacheJson != null) {
          final cacheData = jsonDecode(cacheJson);
          
          // Check if the cache is not too old (24 hours)
          final timestamp = cacheData['timestamp'] as int;
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now - timestamp <= 24 * 60 * 60 * 1000) {
            return cacheData['result'];
          }
        }
      } catch (e) {
        print('Error retrieving cached reverse geocode: $e');
      }
    }
    
    try {
      // Add delay to respect Nominatim usage policy (1 request per second)
      await Future.delayed(Duration(milliseconds: 1000));
      
      final response = await http.get(
        Uri.parse('$_nominatimBaseUrl/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1'),
        headers: {
          'User-Agent': 'EventSpot App',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      );
      
      if (response.statusCode == 200) {
        Map<String, dynamic> result = json.decode(response.body);
        final formattedResult = {
          'displayName': result['display_name'],
          'latitude': latitude,
          'longitude': longitude,
          'placeId': result['place_id'],
          'address': {
            'city': result['address']?['city'] ?? result['address']?['town'] ?? result['address']?['village'],
            'state': result['address']?['state'],
            'country': result['address']?['country'],
            'postcode': result['address']?['postcode'],
            'road': result['address']?['road'],
            'houseNumber': result['address']?['house_number'],
            'neighbourhood': result['address']?['neighbourhood'],
          },
          'formattedAddress': _formatAddress(result['address']),
        };
        
        // Cache the result
        if (useCache) {
          try {
            final prefs = await SharedPreferences.getInstance();
            final cacheData = {
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'result': formattedResult,
            };
            
            await prefs.setString(cacheKey, jsonEncode(cacheData));
          } catch (e) {
            print('Error caching reverse geocode: $e');
          }
        }
        
        return formattedResult;
      } else {
        print('Error reverse geocoding: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception reverse geocoding: $e');
      return null;
    }
  }
  
  // Format address components into a readable string
  String _formatAddress(Map<String, dynamic> address) {
    List<String> components = [];
    
    if (address['house_number'] != null) {
      components.add(address['house_number']);
    }
    
    if (address['road'] != null) {
      components.add(address['road']);
    }
    
    if (address['neighbourhood'] != null) {
      components.add(address['neighbourhood']);
    }
    
    if (address['city'] != null) {
      components.add(address['city']);
    } else if (address['town'] != null) {
      components.add(address['town']);
    } else if (address['village'] != null) {
      components.add(address['village']);
    }
    
    if (address['state'] != null) {
      components.add(address['state']);
    }
    
    if (address['postcode'] != null) {
      components.add(address['postcode']);
    }
    
    if (address['country'] != null) {
      components.add(address['country']);
    }
    
    return components.join(', ');
  }
  
  // Calculate distance between two points using Haversine formula
  double calculateDistance(LatLng point1, LatLng point2) {
    return _distance.as(LengthUnit.Kilometer, point1, point2);
  }
  
  // Get events within radius
  List<Map<String, dynamic>> getEventsWithinRadius(
    List<Map<String, dynamic>> events,
    LatLng center,
    double radiusKm
  ) {
    return events.where((event) {
      if (event['location'] == null || 
          event['location']['latitude'] == null || 
          event['location']['longitude'] == null) {
        return false;
      }
      
      double lat = event['location']['latitude'];
      double lng = event['location']['longitude'];
      LatLng eventLocation = LatLng(lat, lng);
      double distance = calculateDistance(center, eventLocation);
      
      // Add the distance to the event object for sorting
      event['distance'] = distance;
      
      return distance <= radiusKm;
    }).toList();
  }
  
  // Get formatted address string from coordinates
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    final locationData = await reverseGeocode(latitude, longitude);
    if (locationData != null && locationData['formattedAddress'] != null) {
      return locationData['formattedAddress'];
    } else if (locationData != null && locationData['displayName'] != null) {
      return locationData['displayName'];
    } else {
      return '$latitude, $longitude';
    }
  }
}

// Custom exceptions
class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);
  
  @override
  String toString() => 'LocationServiceException: $message';
}

class LocationPermissionException implements Exception {
  final String message;
  LocationPermissionException(this.message);
  
  @override
  String toString() => 'LocationPermissionException: $message';
} 