import 'package:flutter/material.dart';
import 'package:memory_pins_app/models/tapu_pins_item.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/presentation/Widgets/tapu_pins_card.dart';
import 'package:memory_pins_app/providers/tapu_provider.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:provider/provider.dart';

class TapuPins extends StatefulWidget {
  final Tapus tapus; // Add Tapus parameter

  const TapuPins({super.key, required this.tapus});

  @override
  State<TapuPins> createState() => _TapuPinsState();
}

class _TapuPinsState extends State<TapuPins> {
  List<TapuPinsItem> _allPins = [];
  List<Pin> _originalPins = []; // Store original Pin objects
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTapuPins();
  }

  Future<void> _loadTapuPins() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tapuProvider = Provider.of<TapuProvider>(context, listen: false);

      // Load pins around the Tapus
      final pins = await tapuProvider.loadPinsAroundTapu(widget.tapus);
      print('Loaded ${pins.length} pins for Tapus: ${widget.tapus.name}');

      // Store original Pin objects and convert to TapuPinsItem
      _originalPins = pins;
      final tapuPinsItems =
          pins.map((pin) => _convertPinToTapuPinsItem(pin)).toList();

      setState(() {
        _allPins = tapuPinsItems;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading Tapu pins: $e');
      setState(() {
        _error = 'Failed to load pins: $e';
        _isLoading = false;
      });
    }
  }

  TapuPinsItem _convertPinToTapuPinsItem(Pin pin) {
    return TapuPinsItem(
      id: pin.id,
      location: pin.location,
      flagEmoji: pin.flagEmoji,
      title: pin.title,
      emoji: pin.moodIconUrl, // Use moodIconUrl as emoji
      photoCount: pin.photoCount,
      audioCount: pin.audioCount,
      imageUrls: pin.imageUrls.isNotEmpty
          ? pin.imageUrls
          : [pin.imageUrl], // Use imageUrls or fallback to imageUrl
      viewsCount: pin.viewsCount,
      playsCount: pin.playsCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF131F2B),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.frameBgColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14.0, vertical: 17),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: Text(widget.tapus.name, // Use Tapus name
                          textAlign: TextAlign.center,
                          style: text18W700White(context)),
                    ),
                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                              colors: [Color(0xFFF5C253), Color(0xFFEBA145)])),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: GestureDetector(
                          onTap: () {
                            NavigationService.pushNamed('/tapu-detail');
                          },
                          child: Icon(Icons.map, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Loading state
                if (_isLoading)
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: AppColors.bgGroundYellow,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading pins...',
                          style: text14W400White(context),
                        ),
                      ],
                    ),
                  ),

                // Error state
                if (_error != null)
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.red),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTapuPins,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),

                // Empty state
                if (!_isLoading && _error == null && _allPins.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No pins found',
                          style: text18W700White(context),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No pins have been created for this Tapus yet',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Pins list
                if (!_isLoading && _error == null && _allPins.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) {
                      return SizedBox(height: 12);
                    },
                    itemCount: _allPins.length,
                    itemBuilder: (context, index) {
                      final tapuPin = _allPins[index];
                      final originalPin = _originalPins[index];
                      return TapuPinsCard(
                        tapuPins: tapuPin,
                        originalPin: originalPin,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
