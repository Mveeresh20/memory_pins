import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:http/http.dart' as http;
import 'package:memory_pins_app/utills/Constants/image_picker_util.dart';

class FlutterMapPinWidget extends StatefulWidget {
  final List<Pin> pins;
  final Function(Pin) onPinTap;
  final bool isLoading;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onLocationTap;
  final Function(Pin)? getPinDistance;

  const FlutterMapPinWidget({
    Key? key,
    required this.pins,
    required this.onPinTap,
    this.isLoading = false,
    this.onZoomIn,
    this.onZoomOut,
    this.onLocationTap,
    this.getPinDistance,
  }) : super(key: key);

  @override
  State<FlutterMapPinWidget> createState() => FlutterMapPinWidgetState();
}

class FlutterMapPinWidgetState extends State<FlutterMapPinWidget> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  List<Marker> _markers = [];
  bool _isMapReady = false;

  // Helper method to convert image filename to full URL
  String _getImageUrl(String filename) {
    final imagePickerUtil = ImagePickerUtil();
    return imagePickerUtil.getUrlForUserUploadedImage(filename);
  }

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
  void didUpdateWidget(FlutterMapPinWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pins != widget.pins) {
      print('Pins updated, refreshing markers...');
      print('Old pins count: ${oldWidget.pins.length}');
      print('New pins count: ${widget.pins.length}');
      _updateMarkers();
    }
  }

  Future<void> _initializeMap() async {
    try {
      print('Initializing flutter_map...');

      // Get current location with retry logic
      _currentPosition = await _getLocationWithRetry();

      // Update markers
      _updateMarkers();

      setState(() {
        _isMapReady = true;
      });

      print(
          'Flutter map initialized successfully. Current position: $_currentPosition');
    } catch (e) {
      print('Error initializing flutter_map: $e');
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
    print('Updating flutter_map markers...');
    print('Total pins to process: ${widget.pins.length}');

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

    // Process pins in batches for better performance
    await _processPinsInBatches(widget.pins, markers);

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

  Future<void> _processPinsInBatches(
      List<Pin> pins, List<Marker> markers) async {
    const int batchSize = 10;

    for (int i = 0; i < pins.length; i += batchSize) {
      final end = (i + batchSize < pins.length) ? i + batchSize : pins.length;
      final batch = pins.sublist(i, end);

      await Future.wait(
        batch.map((pin) => _processPin(pin, markers)),
      );

      // Small delay between batches to prevent UI blocking
      if (end < pins.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  Future<void> _processPin(Pin pin, List<Marker> markers) async {
    try {
      final distance = _calculateDistance(pin);
      final distanceText = _getFormattedDistance(distance);

      print('Processing pin ${pin.id}: moodIconUrl = ${pin.moodIconUrl}');

      // Create or get custom marker
      Uint8List? customMarkerData;
      if (_customMarkers.containsKey(pin.id)) {
        customMarkerData = _customMarkers[pin.id];
        print('Using cached custom marker for pin ${pin.id}');
      } else if (!_markerCreationInProgress.containsKey(pin.id)) {
        _markerCreationInProgress[pin.id] = true;
        print('Creating custom marker for pin ${pin.id}');
        customMarkerData = await _createCustomMarkerAsync(pin);
        if (customMarkerData != null) {
          _customMarkers[pin.id] = customMarkerData;
          print('Custom marker created successfully for pin ${pin.id}');
        } else {
          print('Custom marker creation failed for pin ${pin.id}');
        }
        _markerCreationInProgress.remove(pin.id);
      } else {
        print('Custom marker creation in progress for pin ${pin.id}');
      }

      markers.add(
        Marker(
          point: LatLng(pin.latitude, pin.longitude),
          width: 120, // Increased to accommodate mood emoji and green dot
          height: 120, // Increased to accommodate mood emoji and green dot
          child: GestureDetector(
            onTap: () => widget.onPinTap(pin),
            child: customMarkerData != null
                ? Image.memory(
                    customMarkerData,
                    fit: BoxFit.contain,
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
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
      print('Error processing pin ${pin.id}: $e');
      // Fallback to default marker
      markers.add(
        Marker(
          point: LatLng(pin.latitude, pin.longitude),
          width: 80, // Increased for fallback marker
          height: 80, // Increased for fallback marker
          child: GestureDetector(
            onTap: () => widget.onPinTap(pin),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
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
    }
  }

  double _calculateDistance(Pin pin) {
    if (_currentPosition == null) return 0.0;

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      pin.latitude,
      pin.longitude,
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

  Future<Uint8List?> _createCustomMarkerAsync(Pin pin) async {
    try {
      return await _createSimpleCustomMarker(pin);
    } catch (e) {
      print('Error creating custom marker for pin ${pin.id}: $e');
      return null;
    }
  }

  Future<Uint8List> _createSimpleCustomMarker(Pin pin) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(200, 200);

    // Draw the main circular background with shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(
      Offset(size.width / 2 + 2, size.height / 2 + 2),
      70,
      shadowPaint,
    );

    // Draw the main circular background (white circle)
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      70,
      paint,
    );

    // Draw border
    final borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      70,
      borderPaint,
    );

    // Try to load and draw profile image
    if (pin.imageUrl.isNotEmpty) {
      try {
        final imageUrl = _getImageUrl(pin.imageUrl);
        final response = await http.get(Uri.parse(imageUrl));

        if (response.statusCode == 200) {
          final codec = await ui.instantiateImageCodec(response.bodyBytes);
          final frameInfo = await codec.getNextFrame();
          final image = frameInfo.image;

          // Create a circular clip path
          final clipPath = ui.Path()
            ..addOval(Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: 60,
            ));

          canvas.save();
          canvas.clipPath(clipPath);

          // Draw the image
          canvas.drawImageRect(
            image,
            Rect.fromLTWH(
                0, 0, image.width.toDouble(), image.height.toDouble()),
            Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: 60,
            ),
            Paint(),
          );

          canvas.restore();
        }
      } catch (e) {
        print('Error loading profile image for pin ${pin.id}: $e');
        // Draw default icon if image fails to load
        _drawDefaultIcon(canvas, size);
      }
    } else {
      _drawDefaultIcon(canvas, size);
    }

    // Draw mood icon circle (small circle overlapping half inside, half outside)
    final moodPaint = Paint()
      ..color = Colors.yellow // Changed to yellow for better visibility
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
      20, // Increased mood icon radius for better visibility
      moodPaint,
    );

    // Draw mood icon border
    final moodBorderPaint = Paint()
      ..color = Colors.orange // Changed to orange for better visibility
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3; // Increased border width

    canvas.drawCircle(
      moodCenter,
      20, // Increased mood icon radius for better visibility
      moodBorderPaint,
    );

    // Try to load and draw the mood image
    try {
      print('Loading mood icon for pin ${pin.id}: ${pin.moodIconUrl}');

      if (pin.moodIconUrl.isNotEmpty && pin.moodIconUrl.startsWith('http')) {
        print('Mood icon URL is valid, making request...');

        final moodResponse = await http.get(Uri.parse(pin.moodIconUrl)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            print('Mood icon request timed out for pin ${pin.id}');
            throw Exception('Mood image request timed out');
          },
        );

        print(
            'Mood icon response status: ${moodResponse.statusCode} for pin ${pin.id}');

        if (moodResponse.statusCode == 200) {
          print('Loading mood icon image for pin ${pin.id}');
          final moodCodec =
              await ui.instantiateImageCodec(moodResponse.bodyBytes);
          final moodFrameInfo = await moodCodec.getNextFrame();
          final moodImage = moodFrameInfo.image;

          // Draw mood image in circle
          final moodRect = Rect.fromCircle(center: moodCenter, radius: 15);
          final moodImagePaint = Paint();
          canvas.saveLayer(moodRect, moodImagePaint);
          canvas.clipPath(ui.Path()..addOval(moodRect));
          canvas.drawImageRect(
            moodImage,
            Rect.fromLTWH(
                0, 0, moodImage.width.toDouble(), moodImage.height.toDouble()),
            moodRect,
            moodImagePaint,
          );
          canvas.restore();
          print('Mood icon drawn successfully for pin ${pin.id}');
        } else {
          print(
              'Mood icon request failed with status ${moodResponse.statusCode} for pin ${pin.id}');
          throw Exception(
              'Mood image request failed: ${moodResponse.statusCode}');
        }
      } else {
        print(
            'Mood icon URL is empty or invalid for pin ${pin.id}: ${pin.moodIconUrl}');
        throw Exception('Invalid mood icon URL: ${pin.moodIconUrl}');
      }
    } catch (e) {
      print('Error loading mood icon for pin ${pin.id}: $e');
      // Always draw a placeholder mood icon (for testing visibility)
      final placeholderMoodPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        moodCenter,
        15, // Placeholder mood radius
        placeholderMoodPaint,
      );

      // Draw a smiley face
      final smileyPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // Draw eyes
      canvas.drawCircle(
        Offset(moodCenter.dx - 7, moodCenter.dy - 5),
        4, // Eye size
        smileyPaint,
      );
      canvas.drawCircle(
        Offset(moodCenter.dx + 7, moodCenter.dy - 5),
        4, // Eye size
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

    // Draw green dot indicator (outside the pin, at the bottom center)
    final dotPaint = Paint()
      ..color = Colors.green // Changed to bright green for better visibility
      ..style = PaintingStyle.fill;

    // Position green dot outside the pin, at the bottom
    final dotCenter = Offset(
      size.width / 2, // Center horizontally
      size.height - 8, // Outside the pin at bottom
    );

    // Add shadow to green dot
    final dotShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5) // Increased shadow opacity
      ..maskFilter =
          const MaskFilter.blur(BlurStyle.normal, 3); // Increased shadow blur

    canvas.drawCircle(
      Offset(dotCenter.dx + 1, dotCenter.dy + 1),
      5, // Increased green dot shadow radius
      dotShadowPaint,
    );

    canvas.drawCircle(
      dotCenter,
      6, // Increased green dot radius for better visibility
      dotPaint,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(200, 200);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _drawDefaultIcon(Canvas canvas, Size size) {
    final iconPaint = Paint()
      ..color = Colors.red
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

  void refreshPins() {
    print('Refreshing pins...');
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
          print('Flutter map ready');
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
