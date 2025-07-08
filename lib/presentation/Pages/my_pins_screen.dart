// screens/my_pins_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/models/pin_item.dart';
import 'package:memory_pins_app/presentation/Pages/create_pin_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/pin_card_widget.dart';
import 'package:memory_pins_app/presentation/Widgets/recording_dialogue.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/services/app_integration_service.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:memory_pins_app/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/app_padding.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/show_custom_dialogue.dart';
import 'package:memory_pins_app/utills/Constants/ui.dart';
import 'package:path/path.dart' as path;
// Your PinCard widget

class MyPinsScreen extends StatefulWidget {
  const MyPinsScreen({Key? key}) : super(key: key);

  @override
  State<MyPinsScreen> createState() => _MyPinsScreenState();
}

class _MyPinsScreenState extends State<MyPinsScreen> {
  final AppIntegrationService _appService = AppIntegrationService();
  String _selectedMonth = 'August';

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
  void initState() {
    super.initState();
    // Load user pins when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPins();
    });
  }

  void _loadUserPins() {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    pinProvider.loadUserPins();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF131F2B),
      body: Consumer2<PinProvider, UserProvider>(
        builder: (context, pinProvider, userProvider, child) {
          final userPins = pinProvider.userPins;
          final isLoading = pinProvider.isLoading;
          final error = pinProvider.error;

          return Padding(
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
                            color: Color(0xFF1D2B36),
                            borderRadius: UI.borderRadius8,
                            border: Border.all(
                                color: Colors.white.withOpacity(0.1)),
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
                                // Filter pins by month
                                if (newValue != null) {
                                  final monthIndex = _months.indexOf(newValue);
                                  final month = DateTime.now().year;
                                  final filteredPins =
                                      pinProvider.filterPinsByMonth(
                                    userPins,
                                    DateTime(month, monthIndex + 1),
                                  );
                                  // You can implement month filtering logic here
                                }
                              },
                              items: _months.map<DropdownMenuItem<String>>(
                                  (String value) {
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

                    // Loading indicator
                    if (isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),

                    // Error message
                    if (error != null)
                      Container(
                        padding: EdgeInsets.all(16),
                        margin: EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                error,
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                pinProvider.clearError();
                                _loadUserPins();
                              },
                              child: Icon(Icons.refresh, color: Colors.red),
                            ),
                          ],
                        ),
                      ),

                    // Empty state
                    if (!isLoading && userPins.isEmpty && error == null)
                      Container(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.push_pin_outlined,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No pins yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create your first pin to get started!',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreatePinScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFF5BF4D),
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text('Create Pin'),
                            ),
                          ],
                        ),
                      ),

                    // Pins list
                    if (!isLoading && userPins.isNotEmpty)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) {
                          return SizedBox(height: 12);
                        },
                        itemCount: userPins.length,
                        itemBuilder: (context, index) {
                          final pin = userPins[index];
                          // Convert Pin to PinItem for the widget
                          final pinItem = PinItem(
                            location: pin.location,
                            flagEmoji: pin.flagEmoji,
                            title: pin.title,
                            emoji: pin.emoji,
                            photoCount: pin.photoCount,
                            audioCount: pin.audioCount,
                            imageUrls: pin.imageUrls,
                            viewsCount: pin.viewsCount,
                            playsCount: pin.playsCount,
                          );
                          return PinCard(pin: pinItem);
                        },
                      ),
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
          color: Color(0xFF1D1F24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBottomNavItem('My Pins', Images.myPinsImg, () {}),
            _buildCentralActionButton(() {
              print('Central Action Button tapped (Tapus/Main)');
              NavigationService.pushNamed('/tapu-pins');
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
