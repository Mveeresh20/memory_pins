import 'package:flutter/material.dart';
import 'package:memory_pins_app/models/saved_pin_item.dart';
import 'package:memory_pins_app/presentation/Pages/create_pin_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/saved_pin_card.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:provider/provider.dart';
import 'package:memory_pins_app/models/pin.dart';

class SavedPins extends StatefulWidget {
  const SavedPins({super.key});

  @override
  State<SavedPins> createState() => _SavedPinsState();
}

class _SavedPinsState extends State<SavedPins> {
  @override
  void initState() {
    super.initState();
    // Load saved pins when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      pinProvider.loadSavedPins();
    });
  }

  // Convert Pin to SavedPinItem for the UI
  SavedPinItem _convertPinToSavedPinItem(Pin pin) {
    print('Converting pin to SavedPinItem:');
    print('  Title: ${pin.title}');
    print('  Location: ${pin.location}');
    print('  Photo count: ${pin.photoCount}');
    print('  Audio count: ${pin.audioCount}');
    print('  Image URLs: ${pin.imageUrls}');
    print('  Views: ${pin.viewsCount}');
    print('  Plays: ${pin.playsCount}');

    // Validate pin data and provide fallbacks
    final validTitle = pin.title.isNotEmpty ? pin.title : 'Untitled Pin';
    final validLocation =
        pin.location.isNotEmpty ? pin.location : 'Unknown Location';
    final validEmoji = pin.emoji?.isNotEmpty == true
        ? pin.emoji!
        : pin.moodIconUrl.isNotEmpty
            ? pin.moodIconUrl
            : Images.smileImg;
    final validImageUrls =
        pin.imageUrls.isNotEmpty ? pin.imageUrls : [Images.umbrellaImg];

    return SavedPinItem(
      location: validLocation,
      title: validTitle,
      emoji: validEmoji,
      photoCount: pin.photoCount,
      audioCount: pin.audioCount,
      imageUrls: validImageUrls,
      viewsCount: pin.viewsCount,
      playsCount: pin.playsCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF131F2B),
      body: Consumer<PinProvider>(
        builder: (context, pinProvider, child) {
          final savedPins = pinProvider.savedPins;
          final isLoading = pinProvider.isLoading;

          return SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16)
                    .copyWith(top: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
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
                            )),
                        SizedBox(width: 12),
                        Text("Saved Pins", style: text18W700White(context)),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Show loading indicator if loading
                    if (isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    else if (savedPins.isEmpty)
                      // Show empty state
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark_border,
                              color: Colors.white54,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No saved pins yet',
                              style: text16W600White(context),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Save pins from the map to see them here',
                              style: text12W400White(context),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      // Show saved pins list
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) {
                          return SizedBox(
                            height: 12,
                          );
                        },
                        itemCount: savedPins.length,
                        itemBuilder: (context, index) {
                          final pin = savedPins[index];
                          print(
                              'Building saved pin card for index $index: ${pin.title}');

                          // Skip pins with completely invalid data
                          if (pin.title.isEmpty && pin.location.isEmpty) {
                            print(
                                'Skipping pin with invalid data at index $index');
                            return SizedBox.shrink();
                          }

                          final savedPinItem = _convertPinToSavedPinItem(pin);
                          return SavedPinCard(
                            pins: savedPinItem,
                            originalPin: pin, // Pass the original pin object
                          );
                        },
                      )
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Color(
            0xFF1D1F24,
          ), // Slightly darker for bottom nav
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem('My Pins', Images.myPinsImg, () {}),
            _buildCentralActionButton(() {
              print('Central Action Button tapped (Tapus/Main)');
              // TODO: Navigate to Tapus Map Screen or main action
            }),
            _buildBottomNavItem('New Pin', Images.newPinImg, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePinScreen(),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    String label,
    String imageUrl,
    VoidCallback onPressed,
  ) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 21,
            height: 21,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(Icons.error, color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Helper function for building the central action button in bottom nav
  Widget _buildCentralActionButton(VoidCallback onPressed) {
    return SizedBox(
      width: 48, // Make it a bit wider than others
      height: 48, // Make it taller for the floating effect
      child: FloatingActionButton(
        shape: CircleBorder(),
        heroTag: 'central_nav_fab',
        onPressed: onPressed,
        backgroundColor: Color(0xFFEBA145), // Yellow like the filter buttons
        child: Icon(Icons.map, color: Colors.white, size: 24), // Tapus icon
        elevation: 5, // Lift it above the bottom nav
      ),
    );
  }
}
