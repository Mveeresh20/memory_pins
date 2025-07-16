import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memory_pins_app/models/tapu.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:memory_pins_app/services/edit_profile_provider.dart';
import 'package:http/http.dart' as http;

class TapuMapWidget extends StatefulWidget {
  final List<Tapu> tapus;
  final Function(Tapu) onTapuTap;
  final bool isLoading;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onLocationTap;
  final Function(Tapu)? getTapuDistance;
  final String? userProfileImageUrl; // Add profile image URL parameter

  const TapuMapWidget({
    Key? key,
    required this.tapus,
    required this.onTapuTap,
    this.isLoading = false,
    this.onZoomIn,
    this.onZoomOut,
    this.onLocationTap,
    this.getTapuDistance,
    this.userProfileImageUrl, // Add this parameter
  }) : super(key: key);

  @override
  State<TapuMapWidget> createState() => TapuMapWidgetState();
}

class TapuMapWidgetState extends State<TapuMapWidget> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isMapReady = false;

  // Improved caching system
  Map<String, BitmapDescriptor> _customMarkers = {};
  Map<String, bool> _markerCreationInProgress = {};
  BitmapDescriptor? _defaultTapuIcon;
  BitmapDescriptor? _currentLocationIcon;

  // Default location (New York City) if location permission is denied
  static const LatLng _defaultLocation = LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(TapuMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tapus != widget.tapus ||
        oldWidget.userProfileImageUrl != widget.userProfileImageUrl) {
      print('TapuMapWidget updated - refreshing markers');
      print('Old profile URL: ${oldWidget.userProfileImageUrl}');
      print('New profile URL: ${widget.userProfileImageUrl}');
      _updateMarkers();
    }
  }

  Future<void> _initializeMap() async {
    try {
      print('Initializing tapu map...');

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
          'Tapu map initialized successfully. Current position: $_currentPosition');
    } catch (e) {
      print('Error initializing tapu map: $e');
      setState(() {
        _isMapReady = true;
      });
    }
  }

  // Pre-load default icons to avoid repeated creation
  Future<void> _preloadDefaultIcons() async {
    try {
      _defaultTapuIcon =
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
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
    print('Updating tapu markers...');
    print('Total tapus to process: ${widget.tapus.length}');

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

    // Process tapus in batches for better performance
    await _processTapusInBatches(widget.tapus, markers);

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

  // Process tapus in batches to avoid blocking the UI
  Future<void> _processTapusInBatches(
      List<Tapu> tapus, Set<Marker> markers) async {
    const int batchSize = 10; // Process 10 tapus at a time

    for (int i = 0; i < tapus.length; i += batchSize) {
      final end = (i + batchSize < tapus.length) ? i + batchSize : tapus.length;
      final batch = tapus.sublist(i, end);

      // Process batch
      await _processTapuBatch(batch, markers);

      // Allow UI to update between batches
      if (i + batchSize < tapus.length) {
        await Future.delayed(Duration(milliseconds: 50));
      }
    }
  }

  Future<void> _processTapuBatch(List<Tapu> tapus, Set<Marker> markers) async {
    for (final tapu in tapus) {
      print('Processing tapu: ${tapu.id} - ${tapu.title}');

      // Get distance text for the tapu
      final distanceText = widget.getTapuDistance?.call(tapu) ?? tapu.location;

      try {
        // Check if custom marker already exists
        if (_customMarkers.containsKey(tapu.id)) {
          // Use cached marker
          markers.add(_createMarkerFromTapu(
              tapu, _customMarkers[tapu.id]!, distanceText));
          print('Using cached custom marker for tapu ${tapu.id}');
        } else if (_markerCreationInProgress[tapu.id] == true) {
          // Skip if creation is in progress, use default
          markers.add(
              _createMarkerFromTapu(tapu, _defaultTapuIcon!, distanceText));
          print(
              'Using default marker for tapu ${tapu.id} (creation in progress)');
        } else {
          // Create custom marker asynchronously
          _markerCreationInProgress[tapu.id] = true;

          // Use default marker initially
          markers.add(
              _createMarkerFromTapu(tapu, _defaultTapuIcon!, distanceText));

          // Create custom marker in background
          _createCustomTapuMarkerAsync(tapu).then((customIcon) {
            if (customIcon != null && mounted) {
              _customMarkers[tapu.id] = customIcon;
              _markerCreationInProgress[tapu.id] = false;

              // Update the marker with custom icon
              setState(() {
                _markers = _markers.map((marker) {
                  if (marker.markerId.value == 'tapu_${tapu.id}') {
                    return marker.copyWith(iconParam: customIcon);
                  }
                  return marker;
                }).toSet();
              });
            }
          }).catchError((e) {
            print('Error creating custom marker for tapu ${tapu.id}: $e');
            _markerCreationInProgress[tapu.id] = false;
          });
        }
      } catch (e) {
        print('Error processing tapu ${tapu.id}: $e');
        // Fallback to default marker
        markers
            .add(_createMarkerFromTapu(tapu, _defaultTapuIcon!, distanceText));
      }
    }
  }

  // Create marker from tapu data
  Marker _createMarkerFromTapu(
      Tapu tapu, BitmapDescriptor icon, String distanceText) {
    return Marker(
      markerId: MarkerId('tapu_${tapu.id}'),
      position: LatLng(tapu.latitude, tapu.longitude),
      icon: icon,
      anchor: const Offset(0.5, 1.0),
      flat: true,
      zIndex: 1000,
      infoWindow: InfoWindow(
        title: tapu.title,
        snippet: distanceText,
      ),
      onTap: () => widget.onTapuTap(tapu),
    );
  }

  // Create custom marker asynchronously
  Future<BitmapDescriptor?> _createCustomTapuMarkerAsync(Tapu tapu) async {
    try {
      // Use a simpler, faster custom marker creation
      return await _createSimpleCustomTapuMarker(tapu);
    } catch (e) {
      print('Error creating custom marker for tapu ${tapu.id}: $e');
      return null;
    }
  }

  Future<BitmapDescriptor?> _createSimpleCustomTapuMarker(Tapu tapu) async {
    try {
      print('Starting simple custom tapu marker creation for tapu: ${tapu.id}');
      print('Tapu image URL: ${tapu.imageUrl}');
      print('Tapu mood URL: ${tapu.mood}');

      // Test the image URL first (but don't fail if it doesn't work)
      try {
        await _testImageUrl(tapu.imageUrl);
      } catch (e) {
        print('Image URL test failed, but continuing: $e');
      }

      // Create a custom painter for the marker
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(200,
          200); // Increased size for better visibility while keeping performance

      print('Created canvas with size: $size');

      // Draw the main circular background with shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      // Add box shadow for the entire marker
      final boxShadowPaint = Paint()
        ..color =
            const Color(0xFF000000).withOpacity(0.3) // #000000 with opacity
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 33); // 33px blur

      // Draw shadow slightly offset (X: 0px, Y: 4px)
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2 + 4), // Y offset of 4px
        70, // Increased radius for larger size
        boxShadowPaint,
      );

      // Try to load and draw the static tapu image (from assets)
      try {
        print('Loading static tapu image for tapu ${tapu.id}');

        // Load the static image from assets
        final ByteData data = await rootBundle.load('assets/images/tapus.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frameInfo = await codec.getNextFrame();
        final image = frameInfo.image;

        // Create a circular clip path for the image
        final imageRect = Rect.fromCircle(
          center: Offset(size.width / 2, size.height / 2),
          radius: 60, // Increased image radius for larger size
        );

        // Draw the image in a circle
        final imagePaint = Paint();
        canvas.saveLayer(imageRect, imagePaint);
        canvas.clipPath(Path()..addOval(imageRect));
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          imageRect,
          imagePaint,
        );
        canvas.restore();
        print('Static tapu image loaded successfully');
      } catch (e) {
        print('Error loading static tapu image: $e');
        // Draw a placeholder icon if image fails to load
        _drawPlaceholderIcon(canvas, size);
      }

      // Draw mood icon circle (small circle overlapping half inside, half outside)
      final moodPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // Position mood icon to overlap half inside, half outside (bottom-right)
      final moodCenter = Offset(
        size.width / 2 + 35, // Right side - adjusted for larger size
        size.height / 2 + 35, // Bottom side - adjusted for larger size
      );

      canvas.drawCircle(
        moodCenter,
        20, // Increased mood icon radius for larger size
        moodPaint,
      );

      // Draw mood icon border
      final moodBorderPaint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        moodCenter,
        20, // Increased mood icon radius for larger size
        moodBorderPaint,
      );

      // Try to load and draw the user's profile image in the mood position
      try {
        print(
            'Loading user profile image for mood position in tapu ${tapu.id}');

        // Use the profile image URL passed from parent widget
        final profileImageUrl = widget.userProfileImageUrl;

        print('Profile image URL: $profileImageUrl');

        if (profileImageUrl != null &&
            profileImageUrl.isNotEmpty &&
            profileImageUrl.startsWith('http')) {
          // Try the profile image URL with timeout
          final response = await http.get(Uri.parse(profileImageUrl)).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Profile image request timed out');
            },
          );
          print('Profile image response status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(response.bodyBytes);
            final frameInfo = await codec.getNextFrame();
            final image = frameInfo.image;

            // Draw profile image in circle
            final moodRect = Rect.fromCircle(center: moodCenter, radius: 16);
            final moodImagePaint = Paint();
            canvas.saveLayer(moodRect, moodImagePaint);
            canvas.clipPath(Path()..addOval(moodRect));
            canvas.drawImageRect(
              image,
              Rect.fromLTWH(
                  0, 0, image.width.toDouble(), image.height.toDouble()),
              moodRect,
              moodImagePaint,
            );
            canvas.restore();
            print('User profile image loaded successfully in mood position');
          } else {
            throw Exception(
                'Failed to load profile image: HTTP ${response.statusCode}');
          }
        } else {
          throw Exception('Invalid profile image URL: $profileImageUrl');
        }
      } catch (e) {
        print('Error loading user profile image in mood position: $e');
        // Draw a more attractive placeholder mood icon
        final placeholderMoodPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          moodCenter,
          16, // Increased placeholder mood radius for larger size
          placeholderMoodPaint,
        );

        // Draw a smiley face
        final smileyPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        // Draw eyes
        canvas.drawCircle(
          Offset(moodCenter.dx - 8, moodCenter.dy - 5),
          4, // Increased eye size for larger marker
          smileyPaint,
        );
        canvas.drawCircle(
          Offset(moodCenter.dx + 8, moodCenter.dy - 5),
          4, // Increased eye size for larger marker
          smileyPaint,
        );

        // Draw smile
        final smilePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawArc(
          Rect.fromCenter(center: moodCenter, width: 20, height: 15),
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
        size.height -
            12, // Outside the tapu at bottom - adjusted for larger size
      );

      // Add shadow to green dot
      final dotShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(dotCenter.dx + 1, dotCenter.dy + 1),
        3, // Reduced green dot radius
        dotShadowPaint,
      );

      canvas.drawCircle(
        dotCenter,
        4, // Reduced green dot radius
        dotPaint,
      );

      // Convert to image
      print('Converting canvas to image...');
      final picture = recorder.endRecording();
      final image = await picture.toImage(150, 150); // Increased image size
      print('Image created with size: ${image.width}x${image.height}');

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final bytes = byteData.buffer.asUint8List();
      print('Image converted to bytes: ${bytes.length} bytes');

      final bitmapDescriptor = BitmapDescriptor.fromBytes(bytes);
      print('BitmapDescriptor created successfully');

      return bitmapDescriptor;
    } catch (e) {
      print('Error creating simple custom tapu marker: $e');
      return null;
    }
  }

  void _drawPlaceholderIcon(Canvas canvas, Size size) {
    // Draw a simple placeholder icon
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw a simple icon (e.g., a star or heart)
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 20.0; // Reduced radius

    // Draw a simple star shape
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * pi / 5) - pi / 2;
      final outerPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final innerPoint = Offset(
        center.dx + (radius * 0.5) * cos(angle + pi / 5),
        center.dy + (radius * 0.5) * sin(angle + pi / 5),
      );

      if (i == 0) {
        path.moveTo(outerPoint.dx, outerPoint.dy);
      } else {
        path.lineTo(outerPoint.dx, outerPoint.dy);
      }
      path.lineTo(innerPoint.dx, innerPoint.dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  Future<void> _testImageUrl(String url) async {
    try {
      print('Testing image URL: $url');

      // Test with different headers
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'image/*',
          'Accept-Encoding': 'gzip, deflate, br',
        },
      );

      print('Test response status: ${response.statusCode}');
      print('Test response headers: ${response.headers}');

      if (response.statusCode == 403) {
        print(
            '403 Forbidden - This indicates a permissions issue with AWS S3/CloudFront');
        print('Possible causes:');
        print('1. CORS not configured properly');
        print('2. CloudFront distribution not set up correctly');
        print('3. S3 bucket permissions are restrictive');
        print('4. URL path is incorrect');
      }
    } catch (e) {
      print('Error testing image URL: $e');
    }
  }

  void _fitBounds() {
    if (_markers.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in _markers) {
      minLat = min(minLat, marker.position.latitude);
      maxLat = max(maxLat, marker.position.latitude);
      minLng = min(minLng, marker.position.longitude);
      maxLng = max(maxLng, marker.position.longitude);
    }

    // Check if all markers are very close together (within 100 meters)
    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;

    if (latDiff < 0.001 && lngDiff < 0.001) {
      // If markers are too close, just center on the first marker with a reasonable zoom
      final firstMarker = _markers.first;
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          firstMarker.position,
          14.0, // Reasonable zoom level
        ),
      );
      return;
    }

    // Add some padding to prevent deep zooming (same as HomeMapWidget)
    const double padding = 0.01; // About 1km
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // padding in pixels
      ),
    );
  }

  // Public methods for external control
  void refreshTapus() {
    print('Refreshing tapus...');
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

  // Method to clear cache and force recreate all markers
  void forceRefreshMarkers() {
    print('Force refreshing tapu markers - clearing cache...');
    _customMarkers.clear();
    _updateMarkers();
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
        if (_markers.isNotEmpty) {
          _fitBounds();
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
      myLocationButtonEnabled: false, // We'll add custom location button
      zoomControlsEnabled: false, // We'll add custom zoom controls
      mapToolbarEnabled: false,
      compassEnabled: true,
      onTap: (_) {
        // Handle map tap if needed
      },
    );
  }
}
