import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:http/http.dart' as http;
import 'package:memory_pins_app/utills/Constants/image_picker_util.dart'; // Add this import

class HomeMapWidget extends StatefulWidget {
  final List<Pin> pins;
  final Function(Pin) onPinTap;
  final bool isLoading;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onLocationTap;
  final Function(Pin)? getPinDistance;

  const HomeMapWidget({
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
  State<HomeMapWidget> createState() => HomeMapWidgetState();
}

class HomeMapWidgetState extends State<HomeMapWidget> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isMapReady = false;

  // Helper method to convert image filename to full URL
  String _getImageUrl(String filename) {
    final imagePickerUtil = ImagePickerUtil();
    // Use the filename as-is (Firebase stores full path, AWS also stores with "images/" prefix)
    return imagePickerUtil.getUrlForUserUploadedImage(filename);
  }

  // Improved caching system
  Map<String, BitmapDescriptor> _customMarkers = {};
  Map<String, bool> _markerCreationInProgress = {};
  BitmapDescriptor? _defaultPinIcon;
  BitmapDescriptor? _currentLocationIcon;

  // Default location (New York City) if location permission is denied
  static const LatLng _defaultLocation = LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(HomeMapWidget oldWidget) {
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
      print('Initializing map...');

      // Pre-load default icons
      await _preloadDefaultIcons();

      // Get current location with retry logic
      _currentPosition = await _getLocationWithRetry();

      // Update markers
      _updateMarkers();

      setState(() {
        _isMapReady = true;
      });

      print(
          'Map initialized successfully. Current position: $_currentPosition');
    } catch (e) {
      print('Error initializing map: $e');
      setState(() {
        _isMapReady = true;
      });
    }
  }

  // Pre-load default icons to avoid repeated creation
  Future<void> _preloadDefaultIcons() async {
    try {
      _defaultPinIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      _currentLocationIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    } catch (e) {
      print('Error preloading default icons: $e');
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
    print('Updating markers...');
    print('Total pins to process: ${widget.pins.length}');

    final Set<Marker> markers = {};

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: _currentLocationIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
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

    // Animate to show all markers if map controller is ready
    if (_mapController != null && markers.isNotEmpty) {
      print('Fitting bounds for ${markers.length} markers');
      _fitBounds();
    }
  }

  // Process pins in batches to avoid blocking the UI
  Future<void> _processPinsInBatches(
      List<Pin> pins, Set<Marker> markers) async {
    const int batchSize = 10; // Process 10 pins at a time

    for (int i = 0; i < pins.length; i += batchSize) {
      final end = (i + batchSize < pins.length) ? i + batchSize : pins.length;
      final batch = pins.sublist(i, end);

      // Process batch
      await _processPinBatch(batch, markers);

      // Allow UI to update between batches
      if (i + batchSize < pins.length) {
        await Future.delayed(Duration(milliseconds: 50));
      }
    }
  }

  Future<void> _processPinBatch(List<Pin> pins, Set<Marker> markers) async {
    for (final pin in pins) {
      print('Processing pin: ${pin.id} - ${pin.title}');
      print('Pin mood icon URL: ${pin.moodIconUrl}');
      print(
          'Pin distance: ${widget.getPinDistance?.call(pin) ?? pin.location}');

      // Get distance text for the pin
      final distanceText = widget.getPinDistance?.call(pin) ?? pin.location;

      try {
        // Check if custom marker already exists
        if (_customMarkers.containsKey(pin.id)) {
          // Use cached marker
          markers.add(
              _createMarkerFromPin(pin, _customMarkers[pin.id]!, distanceText));
          print('Using cached custom marker for pin ${pin.id}');
        } else if (_markerCreationInProgress[pin.id] == true) {
          // Skip if creation is in progress, use default
          markers
              .add(_createMarkerFromPin(pin, _defaultPinIcon!, distanceText));
          print(
              'Using default marker for pin ${pin.id} (creation in progress)');
        } else {
          // Create custom marker asynchronously
          _markerCreationInProgress[pin.id] = true;

          // Use default marker initially
          markers
              .add(_createMarkerFromPin(pin, _defaultPinIcon!, distanceText));

          // Create custom marker in background
          _createCustomMarkerAsync(pin).then((customIcon) {
            if (customIcon != null && mounted) {
              _customMarkers[pin.id] = customIcon;
              _markerCreationInProgress[pin.id] = false;
              print('Custom marker created successfully for pin ${pin.id}');

              // Update the marker with custom icon
              setState(() {
                _markers = _markers.map((marker) {
                  if (marker.markerId.value == 'pin_${pin.id}') {
                    print('Updating marker icon for pin ${pin.id}');
                    return marker.copyWith(iconParam: customIcon);
                  }
                  return marker;
                }).toSet();
              });
            } else {
              print('Custom marker creation failed for pin ${pin.id}');
            }
          }).catchError((e) {
            print('Error creating custom marker for pin ${pin.id}: $e');
            _markerCreationInProgress[pin.id] = false;
          });
        }
      } catch (e) {
        print('Error processing pin ${pin.id}: $e');
        // Fallback to default marker
        markers.add(_createMarkerFromPin(pin, _defaultPinIcon!, distanceText));
      }
    }
  }

  // Create marker from pin data
  Marker _createMarkerFromPin(
      Pin pin, BitmapDescriptor icon, String distanceText) {
    return Marker(
      markerId: MarkerId('pin_${pin.id}'),
      position: LatLng(pin.latitude, pin.longitude),
      icon: icon,
      anchor: const Offset(0.5, 1.0),
      flat: true,
      zIndex: 1000,
      infoWindow: InfoWindow(
        title: pin.title,
        snippet: distanceText,
      ),
      onTap: () => widget.onPinTap(pin),
    );
  }

  // Create custom marker asynchronously
  Future<BitmapDescriptor?> _createCustomMarkerAsync(Pin pin) async {
    try {
      // Use a simpler, faster custom marker creation
      return await _createSimpleCustomMarker(pin);
    } catch (e) {
      print('Error creating custom marker for pin ${pin.id}: $e');
      return null;
    }
  }

  // Simplified custom marker creation for better performance
  Future<BitmapDescriptor> _createSimpleCustomMarker(Pin pin) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(200, 200); // Increased size for better visibility

      // Draw the main circular background with shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(
        Offset(size.width / 2 + 2, size.height / 2 + 2),
        70, // Increased main circle radius for larger size
        shadowPaint,
      );

      // Draw the main circular background (white circle)
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        70, // Increased main circle radius for larger size
        paint,
      );

      // Draw border (white, not purple)
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        70, // Increased border radius for larger size
        borderPaint,
      );

      // Try to load and draw the pin image
      try {
        if (pin.imageUrl.isNotEmpty) {
          // Convert filename to full URL
          final fullImageUrl = _getImageUrl(pin.imageUrl);
          final response = await http.get(Uri.parse(fullImageUrl)).timeout(
                const Duration(seconds: 5),
                onTimeout: () => throw Exception('Image request timed out'),
              );

          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(response.bodyBytes);
            final frameInfo = await codec.getNextFrame();
            final image = frameInfo.image;

            final imageRect = Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: 60, // Increased image radius for larger size
            );

            final imagePaint = Paint();
            canvas.saveLayer(imageRect, imagePaint);
            canvas.clipPath(Path()..addOval(imageRect));
            canvas.drawImageRect(
              image,
              Rect.fromLTWH(
                  0, 0, image.width.toDouble(), image.height.toDouble()),
              imageRect,
              imagePaint,
            );
            canvas.restore();
          }
        }
      } catch (e) {
        // Draw a placeholder if image fails to load
        final placeholderPaint = Paint()
          ..color = Colors.blue[100]!
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          45, // Increased placeholder radius for larger size
          placeholderPaint,
        );

        // Draw a camera icon
        final iconPaint = Paint()
          ..color = Colors.blue[600]!
          ..style = PaintingStyle.fill;

        // Draw a simple camera icon
        final cameraRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 40,
          height: 30,
        );

        // Camera body
        canvas.drawRRect(
          RRect.fromRectAndRadius(cameraRect, const Radius.circular(5)),
          iconPaint,
        );

        // Camera lens
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          20, // Increased camera lens radius for larger size
          iconPaint,
        );

        // Add some text
        final textPainter = TextPainter(
          text: TextSpan(
            text: '📷',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            size.width / 2 - textPainter.width / 2,
            size.height / 2 - textPainter.height / 2,
          ),
        );
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

      // Try to load and draw the mood image
      try {
        print(
            'MapPinWidget - Loading mood icon for pin ${pin.id}: ${pin.moodIconUrl}');

        if (pin.moodIconUrl.isNotEmpty && pin.moodIconUrl.startsWith('http')) {
          print('MapPinWidget - Mood icon URL is valid, making request...');

          final moodResponse =
              await http.get(Uri.parse(pin.moodIconUrl)).timeout(
            const Duration(seconds: 10), // Increased timeout
            onTimeout: () {
              print(
                  'MapPinWidget - Mood icon request timed out for pin ${pin.id}');
              throw Exception('Mood image request timed out');
            },
          );

          print(
              'MapPinWidget - Mood icon response status: ${moodResponse.statusCode} for pin ${pin.id}');

          if (moodResponse.statusCode == 200) {
            print('MapPinWidget - Loading mood icon image for pin ${pin.id}');
            final moodCodec =
                await ui.instantiateImageCodec(moodResponse.bodyBytes);
            final moodFrameInfo = await moodCodec.getNextFrame();
            final moodImage = moodFrameInfo.image;

            // Draw mood image in circle
            final moodRect = Rect.fromCircle(center: moodCenter, radius: 15);
            final moodImagePaint = Paint();
            canvas.saveLayer(moodRect, moodImagePaint);
            canvas.clipPath(Path()..addOval(moodRect));
            canvas.drawImageRect(
              moodImage,
              Rect.fromLTWH(0, 0, moodImage.width.toDouble(),
                  moodImage.height.toDouble()),
              moodRect,
              moodImagePaint,
            );
            canvas.restore();
            print(
                'MapPinWidget - Mood icon drawn successfully for pin ${pin.id}');
          } else {
            print(
                'MapPinWidget - Mood icon request failed with status ${moodResponse.statusCode} for pin ${pin.id}');
            throw Exception(
                'Mood image request failed: ${moodResponse.statusCode}');
          }
        } else {
          print(
              'MapPinWidget - Mood icon URL is empty or invalid for pin ${pin.id}: ${pin.moodIconUrl}');
          throw Exception('Invalid mood icon URL: ${pin.moodIconUrl}');
        }
      } catch (e) {
        print('MapPinWidget - Error loading mood icon for pin ${pin.id}: $e');
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

      // Draw green dot indicator (outside the pin, at the bottom center)
      final dotPaint = Paint()
        ..color = Colors.greenAccent[400]!
        ..style = PaintingStyle.fill;

      // Position green dot outside the pin, at the bottom
      final dotCenter = Offset(
        size.width / 2, // Center horizontally
        size.height - 8, // Outside the pin at bottom
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
      final image =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      print('Error in custom marker creation: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  // Legacy method for complex custom markers (kept for reference)
  Future<BitmapDescriptor> _createCustomPinMarker(Pin pin) async {
    // This method is kept for backward compatibility but not used in the optimized version
    return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
  }

  // Test image URL (simplified)
  Future<void> _testImageUrl(String url) async {
    if (url.isEmpty || !url.startsWith('http')) {
      throw Exception('Invalid URL: $url');
    }

    final response = await http.head(Uri.parse(url)).timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw Exception('Image URL test timed out'),
        );

    if (response.statusCode != 200) {
      throw Exception('Image URL returned status: ${response.statusCode}');
    }
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;
      minLat = min(minLat, lat);
      maxLat = max(maxLat, lat);
      minLng = min(minLng, lng);
      maxLng = max(maxLng, lng);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void refreshPins() {
    print('Refreshing pins...');
    // Clear marker cache to ensure fresh markers are created
    // _customMarkers.clear();
    // _markerCreationInProgress.clear();
    print('Marker cache cleared, updating markers...');
    _updateMarkers();
  }

  // Zoom in method
  void zoomIn() {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.zoomIn());
    }
  }

  // Zoom out method
  void zoomOut() {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.zoomOut());
    }
  }

  // Center on user location method
  Future<void> centerOnUserLocation() async {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    } else if (_mapController != null) {
      // Try to get fresh location
      try {
        final position = await _locationService.getCurrentLocation();
        if (position != null) {
          _currentPosition = position;
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
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

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        print('Map controller created');

        // Fit bounds after controller is ready
        if (_markers.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fitBounds();
          });
        }
      },
      initialCameraPosition: CameraPosition(
        target: _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : _defaultLocation,
        zoom: 12.0,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onTap: (_) {
        // Handle map tap if needed
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
