import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:http/http.dart' as http;

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
  Map<String, BitmapDescriptor> _customMarkers = {};

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
      _updateMarkers();
    }
  }

  Future<void> _initializeMap() async {
    try {
      // Get current location
      _currentPosition = await _locationService.getCurrentLocation();

      // Update markers
      _updateMarkers();

      setState(() {
        _isMapReady = true;
      });
    } catch (e) {
      print('Error initializing map: $e');
      setState(() {
        _isMapReady = true;
      });
    }
  }

  void _updateMarkers() async {
    final Set<Marker> markers = {};

    // Add current location marker
    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
        ),
      );
    }

    // Add pin markers with custom icons
    for (final pin in widget.pins) {
      // Get distance text for the pin (calculate outside try-catch)
      final distanceText = widget.getPinDistance?.call(pin) ?? pin.location;

      try {
        // Create or get custom marker icon
        BitmapDescriptor customIcon;
        if (_customMarkers.containsKey(pin.id)) {
          customIcon = _customMarkers[pin.id]!;
        } else {
          customIcon = await _createCustomPinMarker(pin);
          _customMarkers[pin.id] = customIcon;
        }

        markers.add(
          Marker(
            markerId: MarkerId('pin_${pin.id}'),
            position: LatLng(pin.latitude, pin.longitude),
            icon: customIcon,
            infoWindow: InfoWindow(
              title: pin.title,
              snippet: distanceText, // Show distance instead of location
            ),
            onTap: () => widget.onPinTap(pin),
          ),
        );
      } catch (e) {
        print('Error creating custom marker for pin ${pin.id}: $e');
        // Fallback to default marker
        markers.add(
          Marker(
            markerId: MarkerId('pin_${pin.id}'),
            position: LatLng(pin.latitude, pin.longitude),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: pin.title,
              snippet: distanceText, // Show distance instead of location
            ),
            onTap: () => widget.onPinTap(pin),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });

    // Animate to show all markers if map controller is ready
    if (_mapController != null && markers.isNotEmpty) {
      _fitBounds();
    }
  }

  Future<BitmapDescriptor> _createCustomPinMarker(Pin pin) async {
    try {
      // Test the image URL first
      await _testImageUrl(pin.imageUrl);

      // Create a custom painter for the marker
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(300, 300); // Much larger size for better visibility

      // Draw the main circular background with shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawCircle(
        Offset(size.width / 2 + 4, size.height / 2 + 4),
        100, // Much larger main circle radius
        shadowPaint,
      );

      // Draw the main circular background (white circle)
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        100, // Much larger main circle radius
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        100, // Border radius
        borderPaint,
      );

      // Try to load and draw the pin image
      try {
        print('Loading pin image from: ${pin.imageUrl}');
        if (pin.imageUrl.isNotEmpty && pin.imageUrl.startsWith('http')) {
          // Try the original URL first
          var response = await http.get(Uri.parse(pin.imageUrl));
          print('Pin image response status: ${response.statusCode}');
          print('Pin image response headers: ${response.headers}');

          // If 403, try alternative URL patterns
          if (response.statusCode == 403) {
            print('403 error - trying alternative URL patterns...');

            // Try without the bundle name prefix
            final alternativeUrl =
                pin.imageUrl.replaceFirst('/p27/upload/', '/upload/');
            print('Trying alternative URL: $alternativeUrl');
            response = await http.get(Uri.parse(alternativeUrl));
            print('Alternative URL response status: ${response.statusCode}');

            // If still 403, try another pattern
            if (response.statusCode == 403) {
              final anotherUrl = pin.imageUrl.replaceFirst('/p27/upload/', '/');
              print('Trying another URL: $anotherUrl');
              response = await http.get(Uri.parse(anotherUrl));
              print('Another URL response status: ${response.statusCode}');
            }
          }

          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(response.bodyBytes);
            final frameInfo = await codec.getNextFrame();
            final image = frameInfo.image;

            // Create a circular clip path for the image
            final imageRect = Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: 100, // Much larger image radius
            );

            // Draw the image in a circle
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
            print('Pin image loaded successfully');
          } else {
            throw Exception(
                'Failed to load image: HTTP ${response.statusCode}');
          }
        } else {
          throw Exception('Invalid image URL: ${pin.imageUrl}');
        }
      } catch (e) {
        print('Error loading pin image: $e');
        // Draw a more attractive placeholder if image fails to load
        final placeholderPaint = Paint()
          ..color = Colors.blue[100]!
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          54, // Much larger placeholder radius
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
          12,
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

      // Position mood icon to overlap half inside, half outside (bottom-right)
      final moodCenter = Offset(
        size.width / 2 + 60, // Right side
        size.height / 2 + 60, // Bottom side
      );

      canvas.drawCircle(
        moodCenter,
        36, // Much larger mood icon radius
        moodPaint,
      );

      // Draw mood icon border
      final moodBorderPaint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(
        moodCenter,
        36, // Much larger mood icon radius
        moodBorderPaint,
      );

      // Try to load and draw the mood image
      try {
        print('Loading mood image from: ${pin.moodIconUrl}');
        if (pin.moodIconUrl.isNotEmpty && pin.moodIconUrl.startsWith('http')) {
          final moodResponse = await http.get(Uri.parse(pin.moodIconUrl));
          print('Mood image response status: ${moodResponse.statusCode}');
          if (moodResponse.statusCode == 200) {
            final moodCodec =
                await ui.instantiateImageCodec(moodResponse.bodyBytes);
            final moodFrameInfo = await moodCodec.getNextFrame();
            final moodImage = moodFrameInfo.image;

            // Draw mood image in circle
            final moodRect = Rect.fromCircle(center: moodCenter, radius: 30);
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
            print('Mood image loaded successfully');
          } else {
            throw Exception(
                'Failed to load mood image: HTTP ${moodResponse.statusCode}');
          }
        } else {
          throw Exception('Invalid mood URL: ${pin.moodIconUrl}');
        }
      } catch (e) {
        print('Error loading mood image: $e');
        // Draw a more attractive placeholder mood icon
        final placeholderMoodPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          moodCenter,
          30, // Much larger placeholder mood radius
          placeholderMoodPaint,
        );

        // Draw a smiley face
        final smileyPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        // Draw eyes
        canvas.drawCircle(
          Offset(moodCenter.dx - 6, moodCenter.dy - 4),
          3,
          smileyPaint,
        );
        canvas.drawCircle(
          Offset(moodCenter.dx + 6, moodCenter.dy - 4),
          3,
          smileyPaint,
        );

        // Draw smile
        final smilePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawArc(
          Rect.fromCenter(center: moodCenter, width: 16, height: 12),
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
        size.height - 20, // Outside the pin at bottom
      );

      // Add shadow to green dot
      final dotShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(
        Offset(dotCenter.dx + 2, dotCenter.dy + 2),
        8, // Much larger green dot radius
        dotShadowPaint,
      );

      canvas.drawCircle(
        dotCenter,
        12, // Much larger green dot radius
        dotPaint,
      );

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(300, 300); // Much larger image size
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      print('Error creating custom marker icon: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  // Test function to verify image URL accessibility
  Future<void> _testImageUrl(String imageUrl) async {
    try {
      print('Testing image URL: $imageUrl');

      // Test with different headers
      final response = await http.get(
        Uri.parse(imageUrl),
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

    // Add some padding
    const double padding = 0.01; // About 1km
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50.0, // padding in pixels
      ),
    );
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

  // Method to refresh pins (called from parent widget)
  void refreshPins() {
    _updateMarkers();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMapReady) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
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
      mapType: MapType.normal,
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
