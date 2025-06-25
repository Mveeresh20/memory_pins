import 'package:flutter/material.dart';
import 'package:memory_pins_app/models/saved_pin_item.dart';
import 'package:memory_pins_app/presentation/Pages/create_pin_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/saved_pin_card.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';

class SavedPins extends StatefulWidget {
  const SavedPins({super.key});

  @override
  State<SavedPins> createState() => _SavedPinsState();
}

class _SavedPinsState extends State<SavedPins> {

  final List<SavedPinItem> _allPins = [
    SavedPinItem(
      location: 'New Jersey',
      // Example flag emoji
      title: 'Rainy Window Seat',
      emoji: Images.smileImg,
      photoCount: 7,
      audioCount: 1,
      imageUrls: [
        Images.umbrellaImg,
        Images.childUmbrella,
        Images.manWithRiver,
        Images.rainImg,
        Images.umbrellaImg
      ],
      viewsCount: 34,
      playsCount: 12,
    ),
    SavedPinItem(
      location: 'Washington DC',
      flagEmoji: '🇺🇸',
      title: 'Sunset Goodbye',
      emoji: Images.confusionImg,
      photoCount: 9,
      audioCount: 2,
      imageUrls: [
        Images.umbrellaImg,
        Images.childUmbrella,
        Images.manWithRiver,
        Images.rainImg
      ],
      viewsCount: 500,
      playsCount: 5,
    ),
    SavedPinItem(
      location:
          'Inter Milan', // Assuming this is a place, not the football club

      title: 'Lighthouse Curve',
      emoji: Images.dancingImg,
      photoCount: 7,
      audioCount: 1,
      imageUrls: [
        Images.umbrellaImg,
        Images.childUmbrella,
        Images.manWithRiver,
        Images.rainImg
      ],
      viewsCount: 34,
      playsCount: 12,
    ),
    // Add more PinItem instances as needed
  ];



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF131F2B),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
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
        
                ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    separatorBuilder: (context, index) {
                      return SizedBox(
                        height: 12,
                      );
                    },
        
                    itemCount:
                        _allPins.length, // Use the length of your dynamic data
                    itemBuilder: (context, index) {
                      final pin = _allPins[index]; // Get the current PinItem
                      return SavedPinCard(
                          pins: pin); // Pass the dynamic data to your card widget
                    },
                  )
              ],
            ),
          ),
        ),
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
