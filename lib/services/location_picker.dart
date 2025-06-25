import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'dart:developer' as developer;

import 'package:provider/provider.dart';
import 'package:memory_pins_app/models/location_model.dart';
import 'package:memory_pins_app/services/hive_service.dart';

class LocationPicker extends StatefulWidget {
  final void Function(Map<String, dynamic> location) onLocationSelected;
  final Map<String, dynamic>? initialLocation;

  const LocationPicker({
    Key? key,
    required this.onLocationSelected,
    this.initialLocation,
  }) : super(key: key);

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isSearching = false;
  bool _isGettingLocation = false;
  String? _errorMessage;
  late final LocationService _locationService;

  @override
  void initState() {
    super.initState();
    _locationService = Provider.of<LocationService>(context, listen: false);
    _locationService.setContext(context);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _checkLocationServices() async {
    final position = await _locationService.getCurrentLocation();
    if (position == null) {
      setState(() {
        _errorMessage = 'Location permission is required to show nearby events';
      });
      return false;
    }
    return true;
  }

  Future<bool> _handleLocationPermission() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        setState(() {
          _errorMessage =
              'Location permission is required to show nearby events';
        });
        return false;
      }
      return true;
    } catch (e) {
      developer.log('Error checking location permission: $e');
      setState(() {
        _errorMessage = 'Unable to check location permissions';
      });
      return false;
    }
  }

  Future<void> _initializeLocation() async {
    if (widget.initialLocation != null &&
        widget.initialLocation!['latitude'] != null &&
        widget.initialLocation!['longitude'] != null) {
      setState(() {
        _selectedLocation = LatLng(
          widget.initialLocation!['latitude'] as double,
          widget.initialLocation!['longitude'] as double,
        );
        _selectedAddress = widget.initialLocation!['address'] as String? ?? '';
        _errorMessage = null;
      });
      return;
    }

    try {
      final servicesEnabled = await _checkLocationServices();
      if (!servicesEnabled) {
        setState(() {
          _isGettingLocation = false;
          _errorMessage = "Location services are not enabled";
        });
        return;
      }

      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        setState(() {
          _isGettingLocation = false;
          _errorMessage =
              "Location falsepermission is required to show nearby events";
        });
        return;
      }

      setState(() {
        _isGettingLocation = true;
        _errorMessage = null;
      });

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
          _isGettingLocation = false;
        });
        await _getAddressFromCoordinates(position.latitude, position.longitude);
      }
    } catch (e) {
      developer.log('Error initializing location: $e');
      if (mounted) {
        setState(() {
          // _selectedLocation =
          //     LatLng(37.7749, -122.4194); // Default to San Francisco
          // _selectedAddress = 'San Francisco, CA';
          // _isGettingLocation = false;
          // _errorMessage =
          //     'Unable to get your location. Using default location.';
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        if (mounted) {
          Get.snackbar(
            'Location permission denied',
            'Please enable location services to use this feature. You can enable it in your device settings.',
            snackStyle: SnackStyle.FLOATING,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
        setState(() {
          _isGettingLocation = false;
        });
        return;
      }

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
        _mapController.move(_selectedLocation!, 15);
        await _getAddressFromCoordinates(position.latitude, position.longitude);
      }
    } catch (e) {
      if (mounted) {
        Get.snackbar(
          'Failed to get current location',
          'Please try again.',
          snackStyle: SnackStyle.FLOATING,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _locationService.searchLocation(query);
      if (results.isNotEmpty && mounted) {
        final location = results[0];
        final lat = location['latitude'] as double;
        final lon = location['longitude'] as double;

        setState(() {
          _selectedLocation = LatLng(lat, lon);
          _selectedAddress = location['displayName'] as String? ?? '';
        });

        _mapController.move(_selectedLocation!, 15);
        _updateSelectedLocation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to search location')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lon) async {
    try {
      final locationData = await _locationService.reverseGeocode(lat, lon);
      if (locationData != null && mounted) {
        setState(() {
          _selectedAddress = locationData['displayName'] as String? ?? '';
        });
        _updateSelectedLocation();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _updateSelectedLocation() {
    if (_selectedLocation != null) {
      widget.onLocationSelected({
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _selectedAddress,
      });
      _saveLastLocation();
    }
  }

  Future<void> _saveLastLocation() async {
    if (_selectedLocation != null) {
      try {
        // Split address components
        final addressParts =
            _selectedAddress.split(',').map((e) => e.trim()).toList();
        final city = addressParts.isNotEmpty ? addressParts.first : '';
        final country = addressParts.isNotEmpty ? addressParts.last : '';
        final state = addressParts.length > 1
            ? addressParts[addressParts.length - 2]
            : '';

        final locationData = {
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
          'address': _selectedAddress,
          'city': city,
          'state': state,
          'country': country,
        };

        await HiveService.saveLocation(locationData);
      } catch (e) {
        developer.log('Error saving location: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isGettingLocation) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Getting your location...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_disabled,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isGettingLocation = false;
                  });
                  _initializeLocation();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedLocation == null && _isGettingLocation) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Search location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppColors.borderColor),
                    ),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator.adaptive(
                                  strokeWidth: 2, strokeCap: StrokeCap.round),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.search,
                              color: AppColors.white,
                            ),
                            onPressed: () =>
                                _searchLocation(_searchController.text),
                          ),
                  ),
                  onSubmitted: _searchLocation,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: _isGettingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location, color: AppColors.white),
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                tooltip: 'Use current location',
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _selectedLocation ?? const LatLng(0, 0),
                  initialZoom: 15,
                  onTap: (tapPosition, point) async {
                    setState(() {
                      _selectedLocation = point;
                    });
                    await _getAddressFromCoordinates(
                      point.latitude,
                      point.longitude,
                    );
                    _updateSelectedLocation();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.eventspot.app',
                  ),
                  if (_selectedLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedLocation!,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              // Zoom controls
              Positioned(
                right: 16,
                bottom: 100,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_in',
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _selectedLocation!,
                          currentZoom + 1,
                        );
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'map_zoom_out',
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _selectedLocation!,
                          currentZoom - 1,
                        );
                      },
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
              // Address card
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _selectedAddress,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
