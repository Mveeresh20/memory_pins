import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memory_pins_app/models/tapu.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:http/http.dart' as http;

class TapuMapWidget extends StatefulWidget {
  final List<Tapu> tapus;
  final Function(Tapu) onTapuTap;
  final bool isLoading;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onLocationTap;
  final Function(Tapu)? getTapuDistance;

  const TapuMapWidget({
    Key? key,
    required this.tapus,
    required this.onTapuTap,
    this.isLoading = false,
    this.onZoomIn,
    this.onZoomOut,
    this.onLocationTap,
    this.getTapuDistance,
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
  Map<String, BitmapDescriptor> _customMarkers = {};

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
    if (oldWidget.tapus != widget.tapus) {
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

    // Add tapu markers with custom icons
    for (final tapu in widget.tapus) {
      // Get distance text for the tapu (calculate outside try-catch)
      final distanceText = widget.getTapuDistance?.call(tapu) ?? tapu.location;

      try {
        // Create or get custom marker icon
        BitmapDescriptor customIcon;
        if (_customMarkers.containsKey(tapu.id)) {
          customIcon = _customMarkers[tapu.id]!;
        } else {
          customIcon = await _createCustomTapuMarker(tapu);
          _customMarkers[tapu.id] = customIcon;
        }

        markers.add(
          Marker(
            markerId: MarkerId('tapu_${tapu.id}'),
            position: LatLng(tapu.latitude, tapu.longitude),
            icon: customIcon,
            infoWindow: InfoWindow(
              title: tapu.title,
              snippet: distanceText, // Show distance instead of location
            ),
            onTap: () => widget.onTapuTap(tapu),
          ),
        );
      } catch (e) {
        print('Error creating custom marker for tapu ${tapu.id}: $e');
        // Fallback to default marker
        markers.add(
          Marker(
            markerId: MarkerId('tapu_${tapu.id}'),
            position: LatLng(tapu.latitude, tapu.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: tapu.title,
              snippet: distanceText, // Show distance instead of location
            ),
            onTap: () => widget.onTapuTap(tapu),
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

  Future<BitmapDescriptor> _createCustomTapuMarker(Tapu tapu) async {
    try {
      // Test the image URL first
      await _testImageUrl(tapu.imageUrl);

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

      // Draw the main circular background (purple circle for tapus)
      final paint = Paint()
        ..color = const Color(0xFF531DAB) // Purple color for tapus
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

      // Try to load and draw the tapu image
      try {
        final response = await http.get(Uri.parse(tapu.imageUrl));
        if (response.statusCode == 200) {
          final codec = await ui.instantiateImageCodec(response.bodyBytes);
          final frameInfo = await codec.getNextFrame();
          final image = frameInfo.image;

          // Calculate the image rectangle to fit inside the circle
          final imageSize = 160.0; // Slightly smaller than the circle
          final imageRect = Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: imageSize,
            height: imageSize,
          );

          // Draw the image in a circular clip
          canvas.saveLayer(imageRect, Paint());
          canvas.clipPath(Path()
            ..addOval(Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: imageSize,
              height: imageSize,
            )));
          canvas.drawImageRect(image, imageRect, imageRect, Paint());
          canvas.restore();
        }
      } catch (e) {
        print('Error loading tapu image: $e');
        // Draw a placeholder icon if image fails to load
        _drawPlaceholderIcon(canvas, size);
      }

      // Draw mood icon in the bottom right corner
      if (tapu.mood.isNotEmpty) {
        try {
          final moodResponse = await http.get(Uri.parse(tapu.mood));
          if (moodResponse.statusCode == 200) {
            final moodCodec =
                await ui.instantiateImageCodec(moodResponse.bodyBytes);
            final moodFrameInfo = await moodCodec.getNextFrame();
            final moodImage = moodFrameInfo.image;

            // Draw mood icon in bottom right corner
            final moodSize = 60.0;
            final moodRect = Rect.fromLTWH(
              size.width - moodSize - 20,
              size.height - moodSize - 20,
              moodSize,
              moodSize,
            );

            canvas.drawImageRect(moodImage, moodRect, moodRect, Paint());
          }
        } catch (e) {
          print('Error loading mood icon: $e');
        }
      }

      // Convert to bitmap descriptor
      final picture = recorder.endRecording();
      final image =
          await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      print('Error creating custom tapu marker: $e');
      // Return a default purple marker
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
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
    final radius = 40.0;

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
      final response = await http.head(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Image not found');
      }
    } catch (e) {
      throw Exception('Failed to load image: $e');
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
  void zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void centerOnUserLocation() {
    if (_currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  void refreshPins() {
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
