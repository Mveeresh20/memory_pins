import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class TapuDetailMapWidget extends StatefulWidget {
  final Tapus tapu;
  final List<Pin> pins;
  final Function(Pin)? onPinTap;
  final bool isLoading;
  final Function(Pin)? getPinDistance;

  const TapuDetailMapWidget({
    Key? key,
    required this.tapu,
    required this.pins,
    this.onPinTap,
    this.isLoading = false,
    this.getPinDistance,
  }) : super(key: key);

  @override
  State<TapuDetailMapWidget> createState() => TapuDetailMapWidgetState();
}

class TapuDetailMapWidgetState extends State<TapuDetailMapWidget> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  Set<Marker> _markers = {};
  bool _isMapReady = false;
  Map<String, BitmapDescriptor> _customMarkers = {};
  CameraPosition _currentCameraPosition = CameraPosition(
    target: LatLng(0, 0),
    zoom: 12.0,
  );

  // Distance visualization constants
  static const List<double> _distanceCircleRadiiKm = [1.0, 2.0, 3.0, 4.0, 5.0];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(TapuDetailMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pins != widget.pins || oldWidget.tapu != oldWidget.tapu) {
      _updateMarkers();
    }
  }

  Future<void> _initializeMap() async {
    try {
      _updateMarkers();
      // Set initial camera position to Tapu center
      _currentCameraPosition = CameraPosition(
        target: LatLng(
          widget.tapu.centerCoordinates.latitude,
          widget.tapu.centerCoordinates.longitude,
        ),
        zoom: 12.0,
      );
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

    // Add tapu center marker (purple color)
    try {
      final tapuIcon = await _createCustomTapuMarker();
      markers.add(
        Marker(
          markerId: MarkerId('tapu_center_${widget.tapu.id}'),
          position: LatLng(
            widget.tapu.centerCoordinates.latitude,
            widget.tapu.centerCoordinates.longitude,
          ),
          icon: tapuIcon,
          infoWindow: InfoWindow(
            title: widget.tapu.name,
            snippet: 'Tapu Center',
          ),
        ),
      );
    } catch (e) {
      print('Error creating tapu marker: $e');
      // Fallback to default purple marker
      markers.add(
        Marker(
          markerId: MarkerId('tapu_center_${widget.tapu.id}'),
          position: LatLng(
            widget.tapu.centerCoordinates.latitude,
            widget.tapu.centerCoordinates.longitude,
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: widget.tapu.name,
            snippet: 'Tapu Center',
          ),
        ),
      );
    }

    // Add pin markers within 5km radius
    for (final pin in widget.pins) {
      final distance = _calculateDistanceFromTapu(pin);
      final formattedDistance = _getFormattedDistance(distance);
      final distanceText = '$formattedDistance from center';

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
              snippet: distanceText,
            ),
            onTap: () => widget.onPinTap?.call(pin),
          ),
        );
      } catch (e) {
        print('Error creating custom marker for pin ${pin.id}: $e');
        // Fallback to default red marker
        markers.add(
          Marker(
            markerId: MarkerId('pin_${pin.id}'),
            position: LatLng(pin.latitude, pin.longitude),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: pin.title,
              snippet: distanceText,
            ),
            onTap: () => widget.onPinTap?.call(pin),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });

    // Always center on Tapu first, then show bounds if pins exist
    if (_mapController != null) {
      if (widget.pins.isNotEmpty) {
        _fitBoundsWithTapuCenter();
      } else {
        _centerOnTapu();
      }
    }
  }

  // Calculate distance from Tapu center to pin
  double _calculateDistanceFromTapu(Pin pin) {
    return Geolocator.distanceBetween(
          widget.tapu.centerCoordinates.latitude,
          widget.tapu.centerCoordinates.longitude,
          pin.latitude,
          pin.longitude,
        ) /
        1000; // Convert to km
  }

  // Get formatted distance string
  String _getFormattedDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()}m';
    } else {
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  }

  // Center map on Tapu
  void _centerOnTapu() {
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            widget.tapu.centerCoordinates.latitude,
            widget.tapu.centerCoordinates.longitude,
          ),
        ),
      );
    }
  }

  // Fit bounds but ensure Tapu is always visible
  void _fitBoundsWithTapuCenter() {
    if (_markers.isEmpty) return;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    // Include Tapu center in bounds calculation
    minLat = min(minLat, widget.tapu.centerCoordinates.latitude);
    maxLat = max(maxLat, widget.tapu.centerCoordinates.latitude);
    minLng = min(minLng, widget.tapu.centerCoordinates.longitude);
    maxLng = max(maxLng, widget.tapu.centerCoordinates.longitude);

    // Include all pins
    for (final marker in _markers) {
      if (marker.markerId.value != 'tapu_center_${widget.tapu.id}') {
        minLat = min(minLat, marker.position.latitude);
        maxLat = max(maxLat, marker.position.latitude);
        minLng = min(minLng, marker.position.longitude);
        maxLng = max(maxLng, marker.position.longitude);
      }
    }

    // Add some padding
    const double padding = 0.01;
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
        50.0,
      ),
    );
  }

  Future<BitmapDescriptor> _createCustomTapuMarker() async {
    try {
      // Create a custom painter for the tapu marker
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(300, 300);

      // Draw shadow
      // final shadowPaint = Paint()
      //   ..color = Colors.black.withOpacity(0.3)
      //   ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      // canvas.drawCircle(
      //   Offset(size.width / 2 + 4, size.height / 2 + 4),
      //   100,
      //   shadowPaint,
      // );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        100,
        borderPaint,
      );

      // Try to load and draw the tapu image
      try {
        if (widget.tapu.centerPinImageUrl.isNotEmpty &&
            widget.tapu.centerPinImageUrl.startsWith('http')) {
          final response =
              await http.get(Uri.parse(widget.tapu.centerPinImageUrl));

          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(response.bodyBytes);
            final frameInfo = await codec.getNextFrame();
            final image = frameInfo.image;

            final imageRect = Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: 80,
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
        print('Error loading tapu image: $e');
        // Draw a placeholder icon
        final iconPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        // Draw a simple map icon
        final iconRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 40,
          height: 40,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(iconRect, const Radius.circular(8)),
          iconPaint,
        );
      }

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(300, 300);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      print('Error creating custom tapu marker icon: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  Future<BitmapDescriptor> _createCustomPinMarker(Pin pin) async {
    try {
      // Test the image URL first
      await _testImageUrl(pin.imageUrl);

      // Create a custom painter for the marker
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(300, 300);

      // Draw the main circular background with shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawCircle(
        Offset(size.width / 2 + 4, size.height / 2 + 4),
        100,
        shadowPaint,
      );

      // Draw the main circular background (white circle)
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        100,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3; // Reduced from 10 to 3 for thinner border

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        100,
        borderPaint,
      );

      // Try to load and draw the pin image
      try {
        if (pin.imageUrl.isNotEmpty && pin.imageUrl.startsWith('http')) {
          var response = await http.get(Uri.parse(pin.imageUrl));

          if (response.statusCode == 403) {
            final alternativeUrl =
                pin.imageUrl.replaceFirst('/p27/upload/', '/upload/');
            response = await http.get(Uri.parse(alternativeUrl));
          }

          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(response.bodyBytes);
            final frameInfo = await codec.getNextFrame();
            final image = frameInfo.image;

            final imageRect = Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: 80,
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
        print('Error loading pin image: $e');
        // Draw a placeholder
        final placeholderPaint = Paint()
          ..color = Colors.blue[100]!
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          54,
          placeholderPaint,
        );

        // Draw a camera icon
        final iconPaint = Paint()
          ..color = Colors.blue[600]!
          ..style = PaintingStyle.fill;

        final cameraRect = Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 40,
          height: 30,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(cameraRect, const Radius.circular(5)),
          iconPaint,
        );

        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          12,
          iconPaint,
        );
      }

      // Draw mood icon circle (white background)
      final moodPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      final moodCenter = Offset(
        size.width / 2 + 60,
        size.height / 2 + 60,
      );

      canvas.drawCircle(
        moodCenter,
        36,
        moodPaint,
      );

      // Draw mood icon border (black with opacity, 1px width)
      final moodBorderPaint = Paint()
        ..color = Colors.black.withOpacity(0.3) // Black with opacity
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1; // 1px width

      canvas.drawCircle(
        moodCenter,
        36,
        moodBorderPaint,
      );

      // Try to load and draw the static red pin icon
      try {
        print('Loading static red pin icon for mood position');

        // Load the static image from assets
        final ByteData data =
            await rootBundle.load('assets/icons/red_pin_icon.png');
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frameInfo = await codec.getNextFrame();
        final image = frameInfo.image;

        // Draw the static image in circle
        final moodRect = Rect.fromCircle(center: moodCenter, radius: 30);
        final moodImagePaint = Paint();
        canvas.saveLayer(moodRect, moodImagePaint);
        canvas.clipPath(Path()..addOval(moodRect));
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          moodRect,
          moodImagePaint,
        );
        canvas.restore();
        print('Static red pin icon loaded successfully');
      } catch (e) {
        print('Error loading static red pin icon: $e');
        // Draw a placeholder mood icon
        final placeholderMoodPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          moodCenter,
          30,
          placeholderMoodPaint,
        );

        // Draw a smiley face
        final smileyPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

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

      // Draw green dot indicator
      final dotPaint = Paint()
        ..color = Colors.greenAccent[400]!
        ..style = PaintingStyle.fill;

      final dotCenter = Offset(
        size.width / 2,
        size.height - 20,
      );

      final dotShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(
        Offset(dotCenter.dx + 2, dotCenter.dy + 2),
        8,
        dotShadowPaint,
      );

      canvas.drawCircle(
        dotCenter,
        12,
        dotPaint,
      );

      // Convert to image
      final picture = recorder.endRecording();
      final image = await picture.toImage(300, 300);
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
    } catch (e) {
      print('Error testing image URL: $e');
    }
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

    return Stack(
      children: [
        // Google Maps as background
        GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
            // Always center on Tapu first
            _centerOnTapu();
          },
          onCameraMove: (CameraPosition position) {
            setState(() {
              _currentCameraPosition = position;
            });
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(
              widget.tapu.centerCoordinates.latitude,
              widget.tapu.centerCoordinates.longitude,
            ),
            zoom: 12.0,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          mapType: MapType.normal,
          onTap: (_) {
            // Handle map tap if needed
          },
        ),

        // Real-time distance visualization overlay
        Positioned.fill(
          child: IgnorePointer(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomPaint(
                  painter: DistanceVisualizationPainter(
                    tapuCenter: LatLng(
                      widget.tapu.centerCoordinates.latitude,
                      widget.tapu.centerCoordinates.longitude,
                    ),
                    pins: widget.pins,
                    cameraPosition: _currentCameraPosition,
                    screenSize:
                        Size(constraints.maxWidth, constraints.maxHeight),
                    distanceCircleRadiiKm: _distanceCircleRadiiKm,
                  ),
                );
              },
            ),
          ),
        ),

        // Distance legend

        // Map control buttons
        Positioned(
          top: 200,
          right: 16,
          child: Column(
            children: [
              // Zoom In Button
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.add, color: Colors.black87),
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              // Zoom Out Button
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.remove, color: Colors.black87),
                  onPressed: () {
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              // Center on Tapu Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.center_focus_strong,
                      color: Colors.black87),
                  onPressed: () {
                    _centerOnTapu();
                  },
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

// Real-time Distance Visualization Painter
class DistanceVisualizationPainter extends CustomPainter {
  final LatLng tapuCenter;
  final List<Pin> pins;
  final CameraPosition cameraPosition;
  final Size screenSize;
  final List<double> distanceCircleRadiiKm;

  DistanceVisualizationPainter({
    required this.tapuCenter,
    required this.pins,
    required this.cameraPosition,
    required this.screenSize,
    required this.distanceCircleRadiiKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Convert Tapu center to screen coordinates
    final tapuScreenPos = _latLngToScreen(tapuCenter);

    // Draw light blue background for 5KM radius area (like current location)
    final fiveKmRadiusMeters = 5.0 * 1000;
    final fiveKmRadiusPixels =
        _metersToPixels(fiveKmRadiusMeters, cameraPosition.zoom);

    final backgroundPaint = Paint()
      ..color = Colors.lightBlue.withOpacity(0.15) // Light blue background
      ..style = PaintingStyle.fill;

    canvas.drawCircle(tapuScreenPos, fiveKmRadiusPixels, backgroundPaint);

    // Draw dotted distance circles around Tapu center
    for (int i = 0; i < distanceCircleRadiiKm.length; i++) {
      final radiusKm = distanceCircleRadiiKm[i];
      final radiusMeters = radiusKm * 1000;

      // Calculate circle radius in screen pixels based on zoom level
      final circleRadius = _metersToPixels(radiusMeters, cameraPosition.zoom);

      // Use single color for all distance circles
      final circleColor = Color(0xFF2A9EF5);

      // Draw dotted circle
      _drawDottedCircle(
        canvas,
        tapuScreenPos,
        circleRadius,
        circleColor.withOpacity(0.6),
        2.0,
        8.0,
        8.0,
      );
    }

    // Draw lines from Tapu center to each pin with distance labels
    for (final pin in pins) {
      final pinScreenPos = _latLngToScreen(LatLng(pin.latitude, pin.longitude));
      final distance =
          _calculateDistance(tapuCenter, LatLng(pin.latitude, pin.longitude));
      final formattedDistance = _formatDistance(distance);

      // Draw connecting line
      final linePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(tapuScreenPos, pinScreenPos, linePaint);

      // Calculate midpoint of the line for distance label
      final midPoint = Offset(
        (tapuScreenPos.dx + pinScreenPos.dx) / 2,
        (tapuScreenPos.dy + pinScreenPos.dy) / 2,
      );

      // Draw distance label on the line
      _drawDistanceLabel(
        canvas,
        midPoint,
        formattedDistance,
      );
    }
  }

  // Convert LatLng to screen coordinates
  Offset _latLngToScreen(LatLng latLng) {
    final zoom = cameraPosition.zoom;
    final center = cameraPosition.target;

    // Calculate pixel offset from center
    final latDiff = latLng.latitude - center.latitude;
    final lngDiff = latLng.longitude - center.longitude;

    // Convert to pixels (approximate calculation)
    final pixelsPerDegree = pow(2, zoom) * 256 / 360;
    final x = screenSize.width / 2 + (lngDiff * pixelsPerDegree);
    final y = screenSize.height / 2 - (latDiff * pixelsPerDegree);

    return Offset(x, y);
  }

  // Convert meters to pixels based on zoom level
  double _metersToPixels(double meters, double zoom) {
    // Approximate calculation - meters to pixels at equator
    final pixelsPerMeter = pow(2, zoom) *
        256 /
        (40075000 * cos(cameraPosition.target.latitude * pi / 180));
    return meters * pixelsPerMeter;
  }

  // Calculate distance between two LatLng points
  double _calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }

  // Format distance string
  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  // Draw dotted circle
  void _drawDottedCircle(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
    double strokeWidth,
    double dashLength,
    double gapLength,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final dashPath = Path();
    final dashArray = [dashLength, gapLength];

    final pathMetrics = path.computeMetrics().first;
    final pathLength = pathMetrics.length;

    double distance = 0.0;
    bool draw = true;

    while (distance < pathLength) {
      final length = dashArray[draw ? 0 : 1];
      if (draw) {
        dashPath.addPath(
          pathMetrics.extractPath(distance, distance + length),
          Offset.zero,
        );
      }
      distance += length;
      draw = !draw;
    }

    canvas.drawPath(dashPath, paint);
  }

  // Draw distance label
  void _drawDistanceLabel(Canvas canvas, Offset position, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.nunitoSans(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw text directly without background
    textPainter.paint(
      canvas,
      Offset(position.dx + 10, position.dy - 30),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for real-time updates
  }
}
