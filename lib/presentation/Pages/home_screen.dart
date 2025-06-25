import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/presentation/Pages/create_pin_screen.dart';
import 'package:memory_pins_app/presentation/Pages/map_view_screen.dart';
import 'package:memory_pins_app/presentation/Pages/my_pins_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/map_pin_widget.dart'; // Make sure this import is correct
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:memory_pins_app/utills/Constants/ui.dart'; // Your custom image paths

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Pin> _dummyPins = [
    Pin(
      playsCount: 10,
      location: 'New Jersey',
      flagEmoji: '🇺🇸',
      emoji: Images.smileImg,
      photoCount: 10,
      audioCount: 2,
      imageUrls: [Images.umbrellaImg,Images.childUmbrella,Images.manWithRiver,Images.umbrellaImg],
      viewsCount: 100,
      id: '1',
      latitude: 100, // Dummy position for screenshot
      longitude: 190, // Dummy position for screenshot
      imageUrl: Images.forestImg, // Now points to a network URL
      moodIconUrl: Images.confusionImg, // Now points to a network URL
      title: 'Serene Lake',
    ),
    Pin(
      playsCount: 10,
      location: 'New Jersey',
      flagEmoji: '🇺🇸',
      emoji: Images.smileImg,
      photoCount: 10,
      audioCount: 2,
      imageUrls: [Images.umbrellaImg,Images.childUmbrella,Images.manWithRiver,Images.umbrellaImg],
      viewsCount: 100,
      id: '2',
      latitude: 250,
      longitude: 280,
      imageUrl: Images.rainThunder,
      moodIconUrl: Images.dancingImg,
      title: 'Stormy Sea',
    ),
    Pin(
      playsCount: 10,
      location: 'New Jersey',
      flagEmoji: '🇺🇸',
      emoji: Images.smileImg,
      photoCount: 10,
      audioCount: 2,
      imageUrls: [Images.umbrellaImg,Images.childUmbrella,Images.manWithRiver,Images.umbrellaImg],
      viewsCount: 100,
      id: '3',
      latitude: 120,
      longitude: 400,
      imageUrl: Images.riverImg,
      moodIconUrl: Images.confusionImg,
      title: 'Forest Path',
    ),
    Pin(
      playsCount: 10,
      location: 'New Jersey',
      flagEmoji: '🇺🇸',
      emoji: Images.smileImg,
      photoCount: 10,
      audioCount: 2,
      imageUrls:[Images.umbrellaImg,Images.childUmbrella,Images.manWithRiver,Images.umbrellaImg],
      viewsCount: 100,
      id: '4',
      latitude: 380,
      longitude: 180,
      imageUrl: Images.forestImg,
      moodIconUrl: Images.smileImg,
      title: 'Green Hills',
    ),
    Pin(
      playsCount: 10,
      location: 'New Jersey',
      flagEmoji: '🇺🇸',
      emoji: Images.smileImg,
      photoCount: 10,
      audioCount: 2,
      imageUrls: [Images.umbrellaImg,Images.childUmbrella,Images.manWithRiver,Images.umbrellaImg],
      viewsCount: 100,
      id: '5',
      latitude: 300,
      longitude: 400,
      imageUrl: Images.riverImg,
      moodIconUrl: Images.dancingImg,
      title: 'Misty Mountains',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // A light background for the map
      body: Stack(
        children: [
          // --- Map Background Placeholder ---
          Positioned.fill(
            child: Image.network(
              Images.homeScreenBgImg, // Your network map background image URL
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat, // If your image is tileable
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(
                  Icons.broken_image,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          // --- Dummy Pins on Map (positioned manually for now) ---
          ..._dummyPins.map(
            (pin) => MapPinWidget(
              pin:
                  pin, // MapPinWidget now correctly uses Image.network internally
              onTap: (selectedPin) {
                print('Tapped on pin: ${selectedPin.title}');
                _showPinDetailsBottomSheet(context, selectedPin);
              },
            ),
          ),

          // --- Top Bar (Custom AppBar) ---
          Positioned(
            top: 60, // Adjust for status bar padding
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[700]?.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'Pins',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      NavigationService.pushNamed('/profile');
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(
                        Images.profileImg,
                      ), // Your network profile pic URL
                      onBackgroundImageError: (exception, stackTrace) {
                        print('Error loading profile image: $exception');
                        // Fallback to an icon if image fails to load
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Location Selector (New Jersey) ---
          Positioned(
            top: 130, // Position relative to top bar
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFFEDDCFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.network(Images.earthImg, height: 20),
                  const SizedBox(width: 6),
                  Text(
                    'New Jersey',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.black, size: 18),
                ],
              ),
            ),
          ),

          // --- Floating Action Buttons ---
          Positioned(
            bottom: 190, // Adjust position based on bottom sheet height
            left: 16,
            child: FloatingActionButton(
              shape: CircleBorder(),
              heroTag: 'mood_fab', // Unique tag for multiple FABs
              onPressed: () {
                print('Smiley/Mood FAB tapped');
              },
              backgroundColor: Color(0xFF531DAB),
              child: Image.network(
                Images.smileImg,
                width: 30,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.sentiment_dissatisfied,
                  color: Colors.red,
                ), // Fallback
              ),
            ),
          ),
          Positioned(
            bottom: 190, // Adjust position
            right: 16,
            child: FloatingActionButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              heroTag: 'stack_fab', // Unique tag
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => MapViewScreen()));

                // TODO: Navigate to Saved Pins Screen
              },
              backgroundColor: Color(0xFFF5BF4D),
              child: Image.network(Images.layersImg),
            ),
          ),

          // --- Bottom UI Container (Sheet & Navigation) ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 170, // Height of the bottom container
              decoration: BoxDecoration(
                color: Color(0xFF15212F),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
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
                  // --- Filter Buttons ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFF5BF4D),
                            borderRadius: BorderRadius.circular(57),
                            border: Border.all(width: 1, color: Colors.white),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(Images.mapMarketImg, height: 16),
                                SizedBox(width: 8),
                                Text(
                                  "Nearby",
                                  style: GoogleFonts.nunitoSans(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        SizedBox(width: 24),

                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFFFECC3),
                            borderRadius: BorderRadius.circular(57),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.network(Images.mapMarketImg, height: 16),
                                SizedBox(width: 8),
                                Text(
                                  "More than 5 KM",
                                  style: GoogleFonts.nunitoSans(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // _buildFilterButton('Nearby', Icons.location_on, () {
                        //   print('Nearby filter tapped');
                        // }),
                        // _buildFilterButton(
                        //     'More than 5KM', Icons.map_outlined, () {
                        //   print('More than 5KM filter tapped');
                        // }),
                      ],
                    ),
                  ),
                  const Spacer(), // Pushes navigation to the bottom
                  // --- Bottom Navigation Bar ---
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Color(
                        0xFF1D1F24,
                      ), // Slightly darker for bottom nav
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildBottomNavItem('My Pins', Images.myPinsImg, () {
                          NavigationService.pushNamed('/my-pins');
                        }),
                        _buildCentralActionButton(() {
                          print('Central Action Button tapped (Tapus/Main)');
                          // TODO: Navigate to Tapus Map Screen or main action
                        }),
                        _buildBottomNavItem('New Pin', Images.newPinImg, () {
                          NavigationService.pushNamed('/create-pin');
                        }),
                      ],
                    ),
                  ),
                  // Padding for iPhone home indicator
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function for building filter buttons
  // Widget _buildFilterButton(
  //     String text, IconData icon, VoidCallback onPressed) {
  //   return ElevatedButton.icon(
  //     onPressed: onPressed,
  //     icon: Icon(icon, color: Colors.black87),
  //     label: Text(text, style: const TextStyle(color: Colors.black)),
  //     style: ElevatedButton.styleFrom(
  //       backgroundColor: Color(0xFFF5BF4D), // Yellow background
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(57),
  //       ),
  //       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  //       elevation: 0,
  //     ),
  //   );
  // }

  // Helper function for building bottom navigation items
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

  void _showPinDetailsBottomSheet(BuildContext context, Pin pin) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Color(0xFF15212F),
    isScrollControlled: true,
    builder: (context) {
      final width = MediaQuery.of(context).size.width;

      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Color(0xFF15212F),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(width: 1, color: Colors.white.withOpacity(0.2)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 60,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
            
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.frameBgColor,
                      borderRadius: UI.borderRadius16,
                      border: Border.all(width: 1, color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(pin.location, style: text14W400White(context)),
                                ),
                                const SizedBox(width: 4),
                                Image.asset(Images.trackImage, height: 20),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.borderColor1),
                              color: AppColors.bgGroundYellow,
                              boxShadow: [AppColors.backShadow],
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(Images.sendIcon, height: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                                    
                      // Title and Emoji
                      Row(
                        children: [
                          Image.asset(Images.locationRedIcon, height: 20),
                          const SizedBox(width: 4),
                          Flexible(child: Text(pin.title, style: text18W700White(context))),
                          const SizedBox(width: 4),
                          if (pin.emoji != null)
                            Image.network(pin.emoji!, height: 20, fit: BoxFit.contain),
                        ],
                      ),
                      const SizedBox(height: 8),
                                    
                      // Photos and Audios Count
                      Row(
                        children: [
                          Image.asset(Images.photolibrary, height: 20),
                          const SizedBox(width: 4),
                          Text('${pin.photoCount} Photos', style: text14W500White(context)),
                          const SizedBox(width: 16),
                          Image.asset(Images.audioIcon, height: 20),
                          const SizedBox(width: 4),
                          Text('${pin.audioCount} Audios', style: text14W500White(context)),
                        ],
                      ),
                      const SizedBox(height: 16),
                                    
                      // Image Previews
                      Row(
                        children: [
                          ...pin.imageUrls.asMap().entries.take(4).map((entry) {
                            final idx = entry.key;
                            final url = entry.value;
                            final imageSize = width * 0.18;
                                    
                            if (idx == 3 && pin.imageUrls.length > 4) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: UI.borderRadius8,
                                  border: Border.all(
                                      width: 1, color: Colors.white.withOpacity(0.5)),
                                ),
                                child: ClipRRect(
                                  borderRadius: UI.borderRadius8,
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        url,
                                        height: imageSize,
                                        width: imageSize,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: imageSize,
                                          width: imageSize,
                                          color: Colors.grey[700],
                                          child: const Icon(Icons.image,
                                              color: Colors.white54, size: 30),
                                        ),
                                      ),
                                      Container(
                                        height: imageSize,
                                        width: imageSize,
                                        color: Colors.black.withOpacity(0.5),
                                        child: Center(
                                          child: Text(
                                            '${pin.imageUrls.length - 3}+',
                                            style: GoogleFonts.nunitoSans(
                                              color: Colors.white,
                                              fontSize: width * 0.035,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                                    
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: UI.borderRadius8,
                                border: Border.all(
                                    width: 1, color: Colors.white.withOpacity(0.5)),
                              ),
                              child: ClipRRect(
                                borderRadius: UI.borderRadius8,
                                child: Image.network(
                                  url,
                                  height: imageSize,
                                  width: imageSize,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: imageSize,
                                    width: imageSize,
                                    color: Colors.grey[700],
                                    child: const Icon(Icons.image,
                                        color: Colors.white54, size: 30),
                                  ),
                                ),
                              ),
                            );
                          }).toList()
                        ],
                      ),
                      const SizedBox(height: 16),
                                    
                      // Views and Plays
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${pin.viewsCount} Views',
                            style: GoogleFonts.nunitoSans(
                              color: AppColors.bgGroundYellow,
                              fontSize: width * 0.03,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '${pin.playsCount} Plays',
                            style: GoogleFonts.nunitoSans(
                              color: AppColors.bgGroundYellow,
                              fontSize: width * 0.03,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      
                        ],
                      ),
                    ),
                  ),
            
                  // Location & Send Icon
                  
                  const SizedBox(height: 20),
            
                  // Navigate Button
                  
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

// --- Bottom Sheet for Pin Details (as per your description) ---
//   void _showPinDetailsBottomSheet(BuildContext context, Pin pin) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors
//           .transparent, // Make background transparent to show curved corners
//       isScrollControlled: true, // Allows full height
//       builder: (context) {
//         return DraggableScrollableSheet(
//           initialChildSize: 0.3, // Initial height of the sheet
//           minChildSize: 0.3,
//           maxChildSize: 0.8, // Max height it can expand to
//           expand: false,
//           builder: (BuildContext context, ScrollController scrollController) {
//             return Container(
//               decoration: BoxDecoration(
//                 color: Colors.grey[900], // Dark background for the sheet
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(20),
//                 ),
//               ),
//               child: SingleChildScrollView(
//                 controller: scrollController,
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Center(
//                       child: Container(
//                         width: 40,
//                         height: 4,
//                         margin: const EdgeInsets.only(bottom: 15),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[700],
//                           borderRadius: BorderRadius.circular(2),
//                         ),
//                       ),
//                     ),
//                     Text(
//                       pin.title, // Pin Title
//                       style: const TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.directions_walk,
//                           color: Colors.white70,
//                           size: 18,
//                         ),
//                         const SizedBox(width: 5),
//                         Text(
//                           '${(pin.latitude / 100).toStringAsFixed(1)} KM Away', // Dummy distance
//                           style: const TextStyle(
//                             fontSize: 16,
//                             color: Colors.white70,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 15),
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.photo_library,
//                           color: Colors.white70,
//                           size: 18,
//                         ),
//                         SizedBox(width: 5),
//                         Text(
//                           '4 photos',
//                           style: TextStyle(color: Colors.white70),
//                         ), // Dummy count
//                         SizedBox(width: 15),
//                         Icon(Icons.audiotrack, color: Colors.white70, size: 18),
//                         SizedBox(width: 5),
//                         Text(
//                           '2 audios',
//                           style: TextStyle(color: Colors.white70),
//                         ), // Dummy count
//                       ],
//                     ),
//                     const SizedBox(height: 15),

//                     SizedBox(
//                       height: 80, // Height for image thumbnails
//                       child: ListView.builder(
//                         scrollDirection: Axis.horizontal,
//                         itemCount: 4, // Dummy count
//                         itemBuilder: (context, index) {
//                           // Use Image.network for images within the bottom sheet
//                           String imageUrl;
//                           if (index == 0) {
//                             imageUrl = Images.forestImg;
//                           } else if (index == 1) {
//                             imageUrl = Images.rainThunder;
//                           } else if (index == 2) {
//                             imageUrl = Images.riverImg;
//                           } else {
//                             imageUrl =
//                                 Images.forestImg; // Default or another image
//                           }

//                           return Padding(
//                             padding: const EdgeInsets.only(right: 8.0),
//                             child: ClipRRect(
//                               borderRadius: BorderRadius.circular(8),
//                               child: Image.network(
//                                 imageUrl,
//                                 width: 80,
//                                 height: 80,
//                                 fit: BoxFit.cover,
//                                 loadingBuilder: (
//                                   context,
//                                   child,
//                                   loadingProgress,
//                                 ) {
//                                   if (loadingProgress == null) return child;
//                                   return Center(
//                                     child: CircularProgressIndicator(
//                                       value:
//                                           loadingProgress.expectedTotalBytes !=
//                                                   null
//                                               ? loadingProgress
//                                                       .cumulativeBytesLoaded /
//                                                   loadingProgress
//                                                       .expectedTotalBytes!
//                                               : null,
//                                       strokeWidth: 2,
//                                     ),
//                                   );
//                                 },
//                                 errorBuilder: (context, error, stackTrace) =>
//                                     const Icon(
//                                   Icons.broken_image,
//                                   color: Colors.red,
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 15),
//                     Row(
//                       children: [
//                         Icon(Icons.visibility, color: Colors.white70, size: 18),
//                         SizedBox(width: 5),
//                         Text(
//                           '34 views',
//                           style: TextStyle(color: Colors.white70),
//                         ), // Dummy count
//                         SizedBox(width: 15),
//                         Icon(Icons.play_arrow, color: Colors.white70, size: 18),
//                         SizedBox(width: 5),
//                         Text(
//                           '12 plays',
//                           style: TextStyle(color: Colors.white70),
//                         ), // Dummy count
//                       ],
//                     ),
//                     const SizedBox(height: 20),
//                     // Navigate to full details icon
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: IconButton(
//                         icon: const Icon(
//                           Icons.arrow_forward_ios,
//                           color: Colors.amber,
//                           size: 30,
//                         ),
//                         onPressed: () {
//                           Navigator.pop(context); // Close bottom sheet
//                           print(
//                             'Navigate to full Pin Information Screen for ${pin.title}',
//                           );
//                           // TODO: Navigate to PinInformationScreen
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }
