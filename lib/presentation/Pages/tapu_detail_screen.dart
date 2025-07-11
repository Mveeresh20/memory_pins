import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/tapu.dart';
import 'package:memory_pins_app/models/map_coordinates.dart';
import 'package:memory_pins_app/models/tapu_pins_item.dart';
import 'package:memory_pins_app/models/tapuattachment.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/presentation/Widgets/tapu_detail_map_widget.dart';
import 'package:memory_pins_app/presentation/Widgets/tapu_pins_card.dart';
import 'package:memory_pins_app/presentation/Pages/pin_detail_screen.dart';
import 'package:memory_pins_app/models/pin_detail.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/providers/tapu_provider.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:provider/provider.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';

class TapuDetailScreen extends StatefulWidget {
  final Tapus tapu;

  const TapuDetailScreen({super.key, required this.tapu});

  @override
  State<TapuDetailScreen> createState() => _TapuDetailScreenState();
}

class _TapuDetailScreenState extends State<TapuDetailScreen> {
  List<Pin> _nearbyPins = [];
  bool _isLoading = true;
  String? _error;
  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _loadNearbyPins();
  }

  Future<void> _loadNearbyPins() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tapuProvider = Provider.of<TapuProvider>(context, listen: false);
      final pins = await tapuProvider.loadPinsAroundTapu(widget.tapu);

      setState(() {
        _nearbyPins = pins;
        _isLoading = false;
      });

      print(
          'Loaded ${_nearbyPins.length} pins within 5KM of tapu "${widget.tapu.name}"');
    } catch (e) {
      setState(() {
        _error = 'Failed to load nearby pins: $e';
        _isLoading = false;
      });
      print('Error loading nearby pins: $e');
    }
  }

  // Convert Pin to TapuPinsItem for the card widget
  TapuPinsItem _convertPinToTapuPinsItem(Pin pin) {
    return TapuPinsItem(
      id: pin.id,
      title: pin.title,
      location: pin.location,
      emoji: pin.emoji,
      photoCount: pin.photoCount,
      audioCount: pin.audioCount,
      imageUrls: pin.imageUrls,
      viewsCount: pin.viewsCount,
      playsCount: pin.playsCount,
    );
  }

  // Convert Pin to PinDetail for navigation
  PinDetail _convertPinToPinDetail(Pin pin) {
    // Convert image URLs to PhotoItem list
    List<PhotoItem> photos =
        pin.imageUrls.map((url) => PhotoItem(imageUrl: url)).toList();

    // Convert audio URLs to AudioItem list
    List<AudioItem> audios = [];
    for (int i = 0; i < pin.audioUrls.length; i++) {
      audios.add(AudioItem(
        audioUrl: pin.audioUrls[i],
        duration: '${(i + 1) * 2}:${(i + 1) * 10}',
      ));
    }

    String description = (pin.description?.isNotEmpty == true)
        ? pin.description!
        : 'A beautiful memory captured at ${pin.location}. This pin contains ${pin.photoCount} photos and ${pin.audioCount} audio recordings.';

    return PinDetail(
      title: pin.title,
      description: description,
      audios: audios,
      photos: photos,
    );
  }

  // Navigate to pin detail screen
  void _navigateToPinDetail(Pin pin) {
    print('Navigating to pin detail for: ${pin.title}');
    final pinDetail = _convertPinToPinDetail(pin);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinDetailScreen(
          pinDetail: pinDetail,
          originalPin: pin,
        ),
      ),
    );
  }

  // Get distance from tapu center to pin
  String _getPinDistanceFromTapu(Pin pin) {
    final tapuProvider = Provider.of<TapuProvider>(context, listen: false);
    return tapuProvider.getPinDistanceFromTapu(widget.tapu, pin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // --- Real-time Google Maps Background ---
          Positioned.fill(
            child: TapuDetailMapWidget(
              tapu: widget.tapu,
              pins: _nearbyPins,
              onPinTap: (pin) {
                print('Tapped on pin: ${pin.title}');
                _navigateToPinDetail(pin);
              },
              isLoading: _isLoading,
              getPinDistance: (pin) => _getPinDistanceFromTapu(pin),
            ),
          ),

          // --- Loading Overlay ---
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),

          // --- Top Bar (Custom AppBar) ---
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Color(0xFF253743),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF0F172A).withOpacity(0.5),
                          border: Border.all(
                              color: Color(0xFF0F172A).withOpacity(0.06)),
                          borderRadius: BorderRadius.circular(36),
                        ),
                        child: Text(
                          widget.tapu.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      NavigationService.pushNamed('/profile');
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(widget.tapu.avatarUrl),
                      onBackgroundImageError: (exception, stackTrace) {
                        print('Error loading avatar image: $exception');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Bottom Sheet with Nearby Pins List ---
          Align(
            alignment: Alignment.bottomCenter,
            child: DraggableScrollableSheet(
              controller: _bottomSheetController,
              initialChildSize: 0.3,
              minChildSize: 0.2,
              maxChildSize: 0.7,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF15212F),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Drag handle
                      const SizedBox(height: 10),
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Color(0xFFD4D4D4),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nearby Pins (${_nearbyPins.length})',
                              style: text18W700White(context),
                            ),
                            if (_error != null)
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 20,
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Pins List
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : _error != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 48,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Error loading pins',
                                          style: text16W700White(context),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _error!,
                                          style: text14W400White(context),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: _loadNearbyPins,
                                          child: Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  )
                                : _nearbyPins.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.location_off,
                                              color: Colors.grey[400],
                                              size: 48,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No pins found within 5km',
                                              style: text16W700White(context),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Pins within 5km of this tapu will appear here',
                                              style: text14W400White(context),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        controller: scrollController,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        itemCount: _nearbyPins.length,
                                        itemBuilder: (context, index) {
                                          final pin = _nearbyPins[index];
                                          final tapuPinsItem =
                                              _convertPinToTapuPinsItem(pin);

                                          return Container(
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            child: GestureDetector(
                                              onTap: () =>
                                                  _navigateToPinDetail(pin),
                                              child: TapuPinsCard(
                                                tapuPins: tapuPinsItem,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
