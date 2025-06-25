// screens/my_pins_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Assuming you use GoogleFonts
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/models/pin_item.dart';
import 'package:memory_pins_app/presentation/Pages/create_pin_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/pin_card_widget.dart';
import 'package:memory_pins_app/presentation/Widgets/recording_dialogue.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/app_padding.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/show_custom_dialogue.dart';
import 'package:memory_pins_app/utills/Constants/ui.dart';
import 'package:path/path.dart';
// Your PinCard widget

class MyPinsScreen extends StatefulWidget {
  const MyPinsScreen({Key? key}) : super(key: key);

  @override
  State<MyPinsScreen> createState() => _MyPinsScreenState();
}

class _MyPinsScreenState extends State<MyPinsScreen> {
  // This is your dynamic data source
  // In a real app, this would come from an API call, database, etc.
  // For demonstration, we'll use a hardcoded list.
  final List<PinItem> _allPins = [
    PinItem(
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
    PinItem(
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
    PinItem(
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

  String _selectedMonth = 'August'; // For the dropdown
  // List of available months for the dropdown
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF131F2B), // Dark background color

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Pins',
                      style: GoogleFonts.nunitoSans(
                        color: Colors.white,
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        NavigationService.pushNamed('/my-tapu');

                        // showDialog(
                        //   context: context,
                        //   builder: (BuildContext context) {
                        //     return const RecordingDialog();
                        //   },
                        // );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: UI.borderRadius8,
                            color: AppColors.frameBgColor),
                        child: Padding(
                          padding: AppPadding.allPadding10,
                          child: Image.asset(
                            Images.parentVector,
                          ),
                        ),
                      ),
                    )
                  ],
                ),

                // Month Dropdown
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF1D2B36), // Same as card background
                        borderRadius: UI.borderRadius8,
                        border:
                            Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          value: _selectedMonth,
                          icon: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.keyboard_arrow_down,
                                color: Colors.white),
                          ),
                          dropdownColor: AppColors.frameBgColor,
                          style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedMonth = newValue!;
                            });
                          },
                          items: _months
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

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
                    return PinCard(
                        pin: pin); // Pass the dynamic data to your card widget
                  },
                ),

                // Pushes navigation to the bottom
                // --- Bottom Navigation Bar ---
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

  // --- Bottom Sheet for Pin Details (as per your description) ---
  void _showPinDetailsBottomSheet(BuildContext context, Pin pin) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors
          .transparent, // Make background transparent to show curved corners
      isScrollControlled: true, // Allows full height
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.3, // Initial height of the sheet
          minChildSize: 0.3,
          maxChildSize: 0.8, // Max height it can expand to
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[900], // Dark background for the sheet
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      pin.title, // Pin Title
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${(pin.latitude / 100).toStringAsFixed(1)} KM Away', // Dummy distance
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(
                          Icons.photo_library,
                          color: Colors.white70,
                          size: 18,
                        ),
                        SizedBox(width: 5),
                        Text(
                          '4 photos',
                          style: TextStyle(color: Colors.white70),
                        ), // Dummy count
                        SizedBox(width: 15),
                        Icon(Icons.audiotrack, color: Colors.white70, size: 18),
                        SizedBox(width: 5),
                        Text(
                          '2 audios',
                          style: TextStyle(color: Colors.white70),
                        ), // Dummy count
                      ],
                    ),
                    const SizedBox(height: 15),

                    SizedBox(
                      height: 80, // Height for image thumbnails
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4, // Dummy count
                        itemBuilder: (context, index) {
                          // Use Image.network for images within the bottom sheet
                          String imageUrl;
                          if (index == 0) {
                            imageUrl = Images.forestImg;
                          } else if (index == 1) {
                            imageUrl = Images.rainThunder;
                          } else if (index == 2) {
                            imageUrl = Images.riverImg;
                          } else {
                            imageUrl =
                                Images.forestImg; // Default or another image
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      strokeWidth: 2,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.broken_image,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.visibility, color: Colors.white70, size: 18),
                        SizedBox(width: 5),
                        Text(
                          '34 views',
                          style: TextStyle(color: Colors.white70),
                        ), // Dummy count
                        SizedBox(width: 15),
                        Icon(Icons.play_arrow, color: Colors.white70, size: 18),
                        SizedBox(width: 5),
                        Text(
                          '12 plays',
                          style: TextStyle(color: Colors.white70),
                        ), // Dummy count
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Navigate to full details icon
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.amber,
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close bottom sheet
                          print(
                            'Navigate to full Pin Information Screen for ${pin.title}',
                          );
                          // TODO: Navigate to PinInformationScreen
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
