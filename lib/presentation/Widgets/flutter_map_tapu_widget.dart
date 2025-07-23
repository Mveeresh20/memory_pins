import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memory_pins_app/models/tapu.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:memory_pins_app/services/edit_profile_provider.dart';
import 'package:memory_pins_app/services/auth_service.dart';
import 'package:http/http.dart' as http;

class FlutterMapTapuWidget extends StatefulWidget {
  final List<Tapu> tapus;
  final Function(Tapu) onTapuTap;
  final bool isLoading;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onLocationTap;
  final Function(Tapu)? getTapuDistance;
  final String? userProfileImageUrl;

  const FlutterMapTapuWidget({
    Key? key,
    required this.tapus,
    required this.onTapuTap,
    this.isLoading = false,
    this.onZoomIn,
    this.onZoomOut,
    this.onLocationTap,
    this.getTapuDistance,
    this.userProfileImageUrl,
  }) : super(key: key);

  @override
  State<FlutterMapTapuWidget> createState() => FlutterMapTapuWidgetState();
}

class FlutterMapTapuWidgetState extends State<FlutterMapTapuWidget> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  List<Marker> _markers = [];
  bool _isMapReady = false;

  // Improved caching system
  Map<String, Uint8List> _customMarkers = {};
  Map<String, bool> _markerCreationInProgress = {};

  // Default location (New York City) if location permission is denied
  static const LatLng _defaultLocation = LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(FlutterMapTapuWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tapus != widget.tapus ||
        oldWidget.userProfileImageUrl != widget.userProfileImageUrl) {
      print('FlutterMapTapuWidget updated - refreshing markers');
      print('Old profile URL: ${oldWidget.userProfileImageUrl}');
      print('New profile URL: ${widget.userProfileImageUrl}');
      _updateMarkers();
    }
  }

  Future<void> _initializeMap() async {
    try {
      print('Initializing flutter_map tapu map...');

      // Get current location with retry logic
      _currentPosition = await _getLocationWithRetry();

      // Update markers
      _updateMarkers();

      setState(() {
        _isMapReady = true;
      });

      print(
          'Flutter map tapu initialized successfully. Current position: $_currentPosition');
    } catch (e) {
      print('Error initializing flutter_map tapu map: $e');
      setState(() {
        _isMapReady = true;
      });
    }
  }

  Future<Position?> _getLocationWithRetry({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        print('Attempting to get location (attempt ${i + 1}/$maxRetries)');

        // First try to get last known position using Geolocator directly
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          print('Using last known position: $lastKnown');
          return lastKnown;
        }

        // If no last known position, get current position
        Position? current = await _locationService.getCurrentLocation();
        if (current != null) {
          print('Got current position: $current');
          return current;
        }

        // Wait before retry
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 2));
        }
      } catch (e) {
        print('Error getting location (attempt ${i + 1}): $e');
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(seconds: 2));
        }
      }
    }

    print('Failed to get location after $maxRetries attempts');
    return null;
  }

  void _updateMarkers() async {
    print('Updating flutter_map tapu markers...');
    print('Total tapus to process: ${widget.tapus.length}');

    final List<Marker> markers = [];

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          point:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          width: 40,
          height: 40,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.my_location,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
      print('Added current location marker');
    }

    // Process tapus in batches for better performance
    await _processTapusInBatches(widget.tapus, markers);

    print('Total markers created: ${markers.length}');

    setState(() {
      _markers = markers;
    });

    // Fit bounds after markers are updated
    if (markers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitBounds();
      });
    }
  }

  Future<void> _processTapusInBatches(
      List<Tapu> tapus, List<Marker> markers) async {
    const int batchSize = 10;

    for (int i = 0; i < tapus.length; i += batchSize) {
      final end = (i + batchSize < tapus.length) ? i + batchSize : tapus.length;
      final batch = tapus.sublist(i, end);

      await Future.wait(
        batch.map((tapu) => _processTapu(tapu, markers)),
      );

      // Small delay between batches to prevent UI blocking
      if (end < tapus.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  Future<void> _processTapu(Tapu tapu, List<Marker> markers) async {
    try {
      final distance = _calculateDistance(tapu);
      final distanceText = _getFormattedDistance(distance);

      // Create or get custom marker
      Uint8List? customMarkerData;
      if (_customMarkers.containsKey(tapu.id)) {
        customMarkerData = _customMarkers[tapu.id];
      } else if (!_markerCreationInProgress.containsKey(tapu.id)) {
        _markerCreationInProgress[tapu.id] = true;
        customMarkerData = await _createCustomTapuMarkerAsync(tapu);
        if (customMarkerData != null) {
          _customMarkers[tapu.id] = customMarkerData;
        }
        _markerCreationInProgress.remove(tapu.id);
      }

      markers.add(
        Marker(
          point: LatLng(tapu.latitude, tapu.longitude),
          width: 60,
          height: 60,
          child: GestureDetector(
            onTap: () => widget.onTapuTap(tapu),
            child: customMarkerData != null
                ? Image.memory(
                    customMarkerData,
                    fit: BoxFit.contain,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
          ),
        ),
      );
    } catch (e) {
      print('Error processing tapu ${tapu.id}: $e');
      // Fallback to default marker
      markers.add(
        Marker(
          point: LatLng(tapu.latitude, tapu.longitude),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => widget.onTapuTap(tapu),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.purple,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_pin,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      );
    }
  }

  double _calculateDistance(Tapu tapu) {
    if (_currentPosition == null) return 0.0;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      tapu.latitude,
      tapu.longitude,
    );
  }

  String _getFormattedDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m away';
    } else {
      final distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)}km away';
    }
  }

  Future<Uint8List?> _createCustomTapuMarkerAsync(Tapu tapu) async {
    try {
      return await _createSimpleCustomTapuMarker(tapu);
    } catch (e) {
      print('Error creating custom marker for tapu ${tapu.id}: $e');
      return null;
    }
  }

  Future<Uint8List> _createSimpleCustomTapuMarker(Tapu tapu) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(200, 200);

    // Draw the main circular background with shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Add box shadow for the entire marker
    final boxShadowPaint = Paint()
      ..color = const Color(0xFF000000).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 33);

    // Draw shadow slightly offset
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2 + 4),
      70,
      boxShadowPaint,
    );

    // Try to load and draw the static tapu image (from assets)
    try {
      print('Loading static tapu image for tapu ${tapu.id}');

      // Load the static image from assets
      final ByteData data = await rootBundle.load('assets/images/tapus.png');
      print('Asset loaded, data size: ${data.lengthInBytes} bytes');

      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      print('Image codec created successfully');

      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;
      print('Image frame loaded, size: ${image.width}x${image.height}');

      // Create a circular clip path for the image
      final imageRect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: 60,
      );

      // Draw the image in a circle
      final imagePaint = Paint();
      canvas.saveLayer(imageRect, imagePaint);
      canvas.clipPath(ui.Path()..addOval(imageRect));
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        imageRect,
        imagePaint,
      );
      canvas.restore();
      print('Static tapu image drawn successfully');
    } catch (e) {
      print('Error loading static tapu image: $e');
      print('Stack trace: ${StackTrace.current}');
      // Draw a placeholder icon if image fails to load
      _drawDefaultTapuIcon(canvas, size);
    }

    // Draw mood icon circle (small circle overlapping half inside, half outside)
    final moodPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Position mood icon half inside, half outside the main circle (bottom-right)
    final moodCenter = Offset(
      size.width / 2 +
          50, // Right side - half inside, half outside (main circle radius 70, emoji radius 18)
      size.height / 2 +
          50, // Bottom side - half inside, half outside (main circle radius 70, emoji radius 18)
    );

    canvas.drawCircle(
      moodCenter,
      18, // Increased mood icon radius for better visibility on border
      moodPaint,
    );

    // Draw mood icon border
    final moodBorderPaint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
      moodCenter,
      18, // Increased mood icon radius for better visibility on border
      moodBorderPaint,
    );

    // Try to load and draw the tapu creator's profile image in the mood position
    try {
      print(
          'Loading creator profile image for mood position in tapu ${tapu.id}');

      // Get the creator's profile image URL using their userId
      String? profileImageUrl;
      if (tapu.userId != null && tapu.userId!.isNotEmpty) {
        try {
          final authService = AuthService();
          profileImageUrl =
              await authService.getProfileImageUrlByUserId(tapu.userId!);
          print('Found creator profile image URL: $profileImageUrl');
        } catch (e) {
          print('Error getting creator profile image URL: $e');
        }
      }

      // Fallback to the profile image URL passed from parent widget if creator's not available
      if (profileImageUrl == null || profileImageUrl.isEmpty) {
        profileImageUrl = widget.userProfileImageUrl;
        print('Using fallback profile image URL: $profileImageUrl');
      }

      print('Final profile image URL: $profileImageUrl');

      if (profileImageUrl != null &&
          profileImageUrl.isNotEmpty &&
          profileImageUrl.startsWith('http')) {
        print('Profile image URL is valid, making request...');

        // Try the profile image URL with timeout
        final response = await http.get(Uri.parse(profileImageUrl)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Profile image request timed out');
          },
        );
        print('Profile image response status: ${response.statusCode}');
        print(
            'Profile image response body size: ${response.bodyBytes.length} bytes');

        if (response.statusCode == 200) {
          print('Loading profile image from response...');
          final codec = await ui.instantiateImageCodec(response.bodyBytes);
          final frameInfo = await codec.getNextFrame();
          final image = frameInfo.image;
          print('Profile image loaded, size: ${image.width}x${image.height}');

          // Draw profile image in circle
          final moodRect = Rect.fromCircle(center: moodCenter, radius: 15);
          final moodImagePaint = Paint();
          canvas.saveLayer(moodRect, moodImagePaint);
          canvas.clipPath(ui.Path()..addOval(moodRect));
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble()),
            moodRect,
            moodImagePaint,
          );
          canvas.restore();
          print('User profile image drawn successfully in mood position');
        } else {
          throw Exception(
              'Failed to load profile image: HTTP ${response.statusCode}');
        }
      } else {
        print('Profile image URL is invalid: $profileImageUrl');
        throw Exception('Invalid profile image URL: $profileImageUrl');
      }
    } catch (e) {
      print('Error loading user profile image in mood position: $e');
      print('Stack trace: ${StackTrace.current}');
      // Draw a placeholder mood icon
      final placeholderMoodPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        moodCenter,
        15, // Increased placeholder mood radius for better visibility on border
        placeholderMoodPaint,
      );

      // Draw a smiley face
      final smileyPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // Draw eyes
      canvas.drawCircle(
        Offset(moodCenter.dx - 7, moodCenter.dy - 5),
        4, // Increased eye size for better visibility on border
        smileyPaint,
      );
      canvas.drawCircle(
        Offset(moodCenter.dx + 7, moodCenter.dy - 5),
        4, // Increased eye size for better visibility on border
        smileyPaint,
      );

      // Draw smile
      final smilePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCenter(center: moodCenter, width: 18, height: 14),
        0,
        3.14,
        false,
        smilePaint,
      );
    }

    // Draw green dot indicator (outside the tapu, at the bottom center)
    final dotPaint = Paint()
      ..color = Colors.greenAccent[400]!
      ..style = PaintingStyle.fill;

    // Position green dot outside the tapu, at the bottom
    final dotCenter = Offset(
      size.width / 2, // Center horizontally
      size.height - 8, // Outside the tapu at bottom
    );

    // Add shadow to green dot
    final dotShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(
      Offset(dotCenter.dx + 1, dotCenter.dy + 1),
      3, // Green dot shadow radius
      dotShadowPaint,
    );

    canvas.drawCircle(
      dotCenter,
      4, // Green dot radius
      dotPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(200, 200);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _drawDefaultTapuIcon(Canvas canvas, Size size) {
    final iconPaint = Paint()
      ..color = Colors.purple
      ..style = PaintingStyle.fill;

    // Draw a simple location pin icon
    final path = ui.Path()
      ..moveTo(size.width / 2, size.height / 2 - 40)
      ..lineTo(size.width / 2 - 20, size.height / 2 + 20)
      ..lineTo(size.width / 2 + 20, size.height / 2 + 20)
      ..close();

    canvas.drawPath(path, iconPaint);
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    try {
      final bounds = LatLngBounds.fromPoints(
        _markers.map((marker) => marker.point).toList(),
      );

      // Calculate center and zoom level manually
      final center = LatLng(
        (bounds.southWest.latitude + bounds.northEast.latitude) / 2,
        (bounds.southWest.longitude + bounds.northEast.longitude) / 2,
      );

      // Calculate appropriate zoom level
      final latDiff = bounds.northEast.latitude - bounds.southWest.latitude;
      final lngDiff = bounds.northEast.longitude - bounds.southWest.longitude;
      final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

      // Calculate zoom level (approximate)
      double zoom = 14.0;
      if (maxDiff > 0) {
        zoom = (14.0 - log(maxDiff * 100) / log(2)).clamp(10.0, 15.0);
      }

      _mapController.move(center, zoom);
    } catch (e) {
      print('Error fitting bounds: $e');
      // Fallback to center on current position
      if (_currentPosition != null) {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          12.0,
        );
      }
    }
  }

  void refreshTapus() {
    print('Refreshing tapus...');
    _updateMarkers();
  }

  // Zoom in method
  void zoomIn() {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(currentCenter, currentZoom + 1);
  }

  // Zoom out method
  void zoomOut() {
    final currentCenter = _mapController.camera.center;
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(currentCenter, currentZoom - 1);
  }

  // Center on user location method
  Future<void> centerOnUserLocation() async {
    if (_currentPosition != null) {
      final currentZoom = _mapController.camera.zoom;
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        currentZoom,
      );
    } else {
      // Try to get fresh location
      try {
        final position = await _locationService.getCurrentLocation();
        if (position != null) {
          _currentPosition = position;
          final currentZoom = _mapController.camera.zoom;
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            currentZoom,
          );
        }
      } catch (e) {
        print('Error getting location for centering: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMapReady) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : _defaultLocation,
        initialZoom: 12.0,
        onMapReady: () {
          print('Flutter map tapu ready');
          if (_markers.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _fitBounds();
            });
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.memoryPinsApp',
        ),
        MarkerLayer(
          markers: _markers,
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
