import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:memory_pins_app/utills/Constants/image_picker_util.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class FlutterMapTapuDetailWidget extends StatefulWidget {
  final Tapus tapu;
  final List<Pin> pins;
  final Function(Pin)? onPinTap;
  final bool isLoading;
  final Function(Pin)? getPinDistance;
  final String? userProfileImageUrl; // Add profile image URL parameter

  const FlutterMapTapuDetailWidget({
    Key? key,
    required this.tapu,
    required this.pins,
    this.onPinTap,
    this.isLoading = false,
    this.getPinDistance,
    this.userProfileImageUrl, // Add this parameter
  }) : super(key: key);

  @override
  State<FlutterMapTapuDetailWidget> createState() =>
      FlutterMapTapuDetailWidgetState();
}

class FlutterMapTapuDetailWidgetState
    extends State<FlutterMapTapuDetailWidget> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  List<Marker> _markers = [];
  bool _isMapReady = false;

  // Helper method to convert image filename to full URL
  String _getImageUrl(String filename) {
    final imagePickerUtil = ImagePickerUtil();
    return imagePickerUtil.getUrlForUserUploadedImage(filename);
  }

  Map<String, Uint8List> _customMarkers = {};
  LatLng _currentCameraCenter = const LatLng(0, 0);
  double _currentZoom = 12.0;

  // Distance visualization constants
  static const List<double> _distanceCircleRadiiKm = [1.0, 2.0, 3.0, 4.0, 5.0];

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didUpdateWidget(FlutterMapTapuDetailWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pins != widget.pins ||
        oldWidget.tapu != widget.tapu ||
        oldWidget.userProfileImageUrl != widget.userProfileImageUrl) {
      _updateMarkers();
    }
  }

  Future<void> _initializeMap() async {
    try {
      _updateMarkers();
      // Set initial camera position to Tapu center
      _currentCameraCenter = LatLng(
        widget.tapu.centerCoordinates.latitude,
        widget.tapu.centerCoordinates.longitude,
      );
      setState(() {
        _isMapReady = true;
      });
    } catch (e) {
      print('Error initializing flutter_map tapu detail: $e');
      setState(() {
        _isMapReady = true;
      });
    }
  }

  void _updateMarkers() async {
    final List<Marker> markers = [];

    // Add tapu center marker (purple color)
    try {
      final tapuIcon = await _createCustomTapuMarker();
      markers.add(
        Marker(
          point: LatLng(
            widget.tapu.centerCoordinates.latitude,
            widget.tapu.centerCoordinates.longitude,
          ),
          width: 120, // Increased to accommodate custom drawn content
          height: 120, // Increased to accommodate custom drawn content
          child: GestureDetector(
            onTap: () {
              // Tapu center tap handler if needed
            },
            child: tapuIcon != null
                ? Image.memory(
                    tapuIcon,
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
      print('Error creating tapu marker: $e');
      // Fallback to default purple marker
      markers.add(
        Marker(
          point: LatLng(
            widget.tapu.centerCoordinates.latitude,
            widget.tapu.centerCoordinates.longitude,
          ),
          width: 120, // Same size as custom marker for consistency
          height: 120, // Same size as custom marker for consistency
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
              size: 30, // Increased icon size
            ),
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
        Uint8List? customIcon;
        if (_customMarkers.containsKey(pin.id)) {
          customIcon = _customMarkers[pin.id];
        } else {
          customIcon = await _createCustomPinMarker(pin);
          if (customIcon != null) {
            _customMarkers[pin.id] = customIcon;
          }
        }

        markers.add(
          Marker(
            point: LatLng(pin.latitude, pin.longitude),
            width: 80, // Reduced size for better visibility
            height: 80, // Reduced size for better visibility
            child: GestureDetector(
              onTap: () => widget.onPinTap?.call(pin),
              child: customIcon != null
                  ? Image.memory(
                      customIcon,
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
        print('Error creating custom marker for pin ${pin.id}: $e');
        // Fallback to default red marker
        markers.add(
          Marker(
            point: LatLng(pin.latitude, pin.longitude),
            width: 40,
            height: 40,
            child: GestureDetector(
              onTap: () => widget.onPinTap?.call(pin),
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
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });

    // Always center on Tapu first, then show bounds if pins exist
    if (markers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _centerOnTapu();
      });
    }
  }

  double _calculateDistanceFromTapu(Pin pin) {
    return Geolocator.distanceBetween(
      widget.tapu.centerCoordinates.latitude,
      widget.tapu.centerCoordinates.longitude,
      pin.latitude,
      pin.longitude,
    );
  }

  String _getFormattedDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)}km';
    }
  }

  Future<Uint8List?> _createCustomTapuMarker() async {
    try {
      print('Creating custom tapu marker for tapu ${widget.tapu.id}');
      print('Tapu center image URL: ${widget.tapu.centerPinImageUrl}');

      // Create a custom painter for the tapu marker
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(200, 200);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        70,
        borderPaint,
      );

      // Try to load and draw the tapu image
      try {
        if (widget.tapu.centerPinImageUrl.isNotEmpty) {
          // Convert filename to full URL
          final imageUrl = _getImageUrl(widget.tapu.centerPinImageUrl);
          print('Loading tapu image for tapu ${widget.tapu.id}:');
          print(
              '  Original centerPinImageUrl: ${widget.tapu.centerPinImageUrl}');
          print('  Converted imageUrl: $imageUrl');

          final response = await http.get(Uri.parse(imageUrl));

          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(response.bodyBytes);
            final frameInfo = await codec.getNextFrame();
            final image = frameInfo.image;

            final imageRect = Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: 70,
            );

            final imagePaint = Paint();
            canvas.saveLayer(imageRect, imagePaint);
            canvas.clipPath(ui.Path()..addOval(imageRect));
            canvas.drawImageRect(
              image,
              Rect.fromLTWH(
                  0, 0, image.width.toDouble(), image.height.toDouble()),
              imageRect,
              imagePaint,
            );
            canvas.restore();
            print('Tapu image drawn successfully for tapu ${widget.tapu.id}');
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
          width: 30,
          height: 30,
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

      return bytes;
    } catch (e) {
      print('Error creating custom tapu marker icon: $e');
      return null;
    }
  }

  Future<Uint8List?> _createCustomPinMarker(Pin pin) async {
    try {
      // Create a custom painter for the marker
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(200, 200); // Reduced from 300x300 to 200x200

      // Draw the main circular background with shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawCircle(
        Offset(size.width / 2 + 3, size.height / 2 + 3),
        65, // Reduced from 100 to 65
        shadowPaint,
      );

      // Draw the main circular background (white circle)
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        65, // Reduced from 100 to 65
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2; // Reduced from 3 to 2

      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        65, // Reduced from 100 to 65
        borderPaint,
      );

      // Try to load and draw the pin image
      try {
        if (pin.imageUrl.isNotEmpty) {
          // Use _getImageUrl to convert filename to full URL
          final imageUrl = _getImageUrl(pin.imageUrl);
          print('Loading pin image for pin ${pin.id}:');
          print('  Original imageUrl: ${pin.imageUrl}');
          print('  Converted imageUrl: $imageUrl');

          var response = await http.get(Uri.parse(imageUrl));

          if (response.statusCode == 403) {
            print('Got 403, trying alternative URL for pin ${pin.id}');
            final alternativeUrl =
                imageUrl.replaceFirst('/p27/upload/', '/upload/');
            print('  Alternative URL: $alternativeUrl');
            response = await http.get(Uri.parse(alternativeUrl));
          }

          if (response.statusCode == 200) {
            print(
                'Pin image request successful for pin ${pin.id}, response size: ${response.bodyBytes.length} bytes');
            final codec = await ui.instantiateImageCodec(response.bodyBytes);
            final frameInfo = await codec.getNextFrame();
            final image = frameInfo.image;
            print(
                'Pin image decoded successfully for pin ${pin.id}, size: ${image.width}x${image.height}');

            final imageRect = Rect.fromCircle(
              center: Offset(size.width / 2, size.height / 2),
              radius: 55, // Reduced from 80 to 55
            );

            final imagePaint = Paint();
            canvas.saveLayer(imageRect, imagePaint);
            canvas.clipPath(ui.Path()..addOval(imageRect));
            canvas.drawImageRect(
              image,
              Rect.fromLTWH(
                  0, 0, image.width.toDouble(), image.height.toDouble()),
              imageRect,
              imagePaint,
            );
            canvas.restore();
            print('Pin image drawn successfully for pin ${pin.id}');
          } else {
            print(
                'Pin image request failed with status ${response.statusCode} for pin ${pin.id}');
            print('Response headers: ${response.headers}');
            throw Exception('Pin image request failed: ${response.statusCode}');
          }
        } else {
          print('Pin ${pin.id} has empty imageUrl');
        }
      } catch (e) {
        print('Error loading pin image: $e');
        // Draw a placeholder
        final placeholderPaint = Paint()
          ..color = Colors.blue[100]!
          ..style = PaintingStyle.fill;

        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          35, // Reduced from 54 to 35
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
        size.width / 2 + 40, // Reduced from 60 to 40
        size.height / 2 + 40, // Reduced from 60 to 40
      );

      canvas.drawCircle(
        moodCenter,
        24, // Reduced from 36 to 24
        moodPaint,
      );

      // Draw mood icon border (black with opacity, 1px width)
      final moodBorderPaint = Paint()
        ..color = Colors.black.withOpacity(0.3) // Black with opacity
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1; // 1px width

      canvas.drawCircle(
        moodCenter,
        24, // Reduced from 36 to 24
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
        final moodRect = Rect.fromCircle(
            center: moodCenter, radius: 20); // Reduced from 30 to 20
        final moodImagePaint = Paint();
        canvas.saveLayer(moodRect, moodImagePaint);
        canvas.clipPath(ui.Path()..addOval(moodRect));
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
        size.height - 15, // Reduced from 20 to 15
      );

      final dotShadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter =
            const MaskFilter.blur(BlurStyle.normal, 3); // Reduced from 4 to 3

      canvas.drawCircle(
        Offset(
            dotCenter.dx + 1, dotCenter.dy + 1), // Reduced offset from 2 to 1
        6, // Reduced from 8 to 6
        dotShadowPaint,
      );

      canvas.drawCircle(
        dotCenter,
        8, // Reduced from 12 to 8
        dotPaint,
      );

      // Convert to image
      final picture = recorder.endRecording();
      final image =
          await picture.toImage(200, 200); // Reduced from 300x300 to 200x200
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      return bytes;
    } catch (e) {
      print('Error creating custom marker icon: $e');
      return null;
    }
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

  void _drawPlaceholderIcon(Canvas canvas, Size size) {
    // Draw a simple placeholder icon
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw a simple icon (e.g., a star or heart)
    final path = ui.Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 20.0;

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

  void _drawDefaultPinIcon(Canvas canvas, Size size) {
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

  void _centerOnTapu() {
    _mapController.move(
      LatLng(
        widget.tapu.centerCoordinates.latitude,
        widget.tapu.centerCoordinates.longitude,
      ),
      12.0,
    );
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
        // Flutter Map as background
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(
              widget.tapu.centerCoordinates.latitude,
              widget.tapu.centerCoordinates.longitude,
            ),
            initialZoom: 12.0,
            onMapEvent: (MapEvent event) {
              if (event is MapEventMove) {
                setState(() {
                  _currentCameraCenter = event.camera.center;
                  _currentZoom = event.camera.zoom;
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
                    cameraCenter: _currentCameraCenter,
                    zoom: _currentZoom,
                    screenSize:
                        Size(constraints.maxWidth, constraints.maxHeight),
                    distanceCircleRadiiKm: _distanceCircleRadiiKm,
                  ),
                );
              },
            ),
          ),
        ),

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
                    zoomIn();
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
                    zoomOut();
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
    super.dispose();
  }
}

// Real-time Distance Visualization Painter
class DistanceVisualizationPainter extends CustomPainter {
  final LatLng tapuCenter;
  final List<Pin> pins;
  final LatLng cameraCenter;
  final double zoom;
  final Size screenSize;
  final List<double> distanceCircleRadiiKm;

  DistanceVisualizationPainter({
    required this.tapuCenter,
    required this.pins,
    required this.cameraCenter,
    required this.zoom,
    required this.screenSize,
    required this.distanceCircleRadiiKm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Convert Tapu center to screen coordinates
    final tapuScreenPos = _latLngToScreen(tapuCenter);

    // Draw light blue background for 5KM radius area
    final fiveKmRadiusMeters = 5.0 * 1000;
    final fiveKmRadiusPixels = _metersToPixels(fiveKmRadiusMeters, zoom);

    final backgroundPaint = Paint()
      ..color = Colors.lightBlue.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(tapuScreenPos, fiveKmRadiusPixels, backgroundPaint);

    // Draw dotted distance circles around Tapu center
    for (int i = 0; i < distanceCircleRadiiKm.length; i++) {
      final radiusKm = distanceCircleRadiiKm[i];
      final radiusMeters = radiusKm * 1000;

      // Calculate circle radius in screen pixels based on zoom level
      final circleRadius = _metersToPixels(radiusMeters, zoom);

      // Use single color for all distance circles
      final circleColor = const Color(0xFF2A9EF5);

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
      _drawDistanceLabel(canvas, midPoint, formattedDistance);
    }
  }

  // Convert LatLng to screen coordinates
  Offset _latLngToScreen(LatLng latLng) {
    // Calculate pixel offset from center
    final latDiff = latLng.latitude - cameraCenter.latitude;
    final lngDiff = latLng.longitude - cameraCenter.longitude;

    // Convert to pixels (approximate calculation)
    final pixelsPerDegree = pow(2, zoom) * 256 / 360;
    final x = screenSize.width / 2 + (lngDiff * pixelsPerDegree);
    final y = screenSize.height / 2 - (latDiff * pixelsPerDegree);

    return Offset(x, y);
  }

  // Convert meters to pixels based on zoom level
  double _metersToPixels(double meters, double zoom) {
    // Approximate calculation - meters to pixels at equator
    final pixelsPerMeter =
        pow(2, zoom) * 256 / (40075000 * cos(cameraCenter.latitude * pi / 180));
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

  // Format distance for display
  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      final distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)}km';
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
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final circumference = 2 * pi * radius;
    final totalDashLength = dashLength + gapLength;
    final numDashes = (circumference / totalDashLength).floor();

    for (int i = 0; i < numDashes; i++) {
      final startAngle = (i * totalDashLength / radius) - pi / 2;
      final endAngle = startAngle + (dashLength / radius);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
    }
  }

  // Draw distance label
  void _drawDistanceLabel(Canvas canvas, Offset position, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw background
    final backgroundRect = Rect.fromCenter(
      center: position,
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
      backgroundPaint,
    );

    // Draw text
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
