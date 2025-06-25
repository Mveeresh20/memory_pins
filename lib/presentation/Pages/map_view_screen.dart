import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:memory_pins_app/models/map_cordinates.dart';
import 'package:memory_pins_app/models/tapu.dart';
import 'package:memory_pins_app/presentation/Pages/create_pin_screen.dart';
import 'package:memory_pins_app/presentation/Pages/my_pins_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/map_detail_card.dart';
import 'package:memory_pins_app/presentation/Widgets/map_pin_widget.dart';
import 'package:memory_pins_app/presentation/Widgets/map_tapu_widget.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  MapDetailCardData? _currentDetailCard;

  final MapScreenData _mapData = MapScreenData(
    currentMapName: "Tapu's",
    zoomLevelText: "52 x 52",
    userAvatars: [
      UserAvatar(
        imageUrl: 'assets/images/track_image.png',
        coordinates: MapCordinates(latitude: 0, longitude: 0),
      ),
      UserAvatar(
        imageUrl: Images.earthImg,
        coordinates: MapCordinates(latitude: 10, longitude: 32),
      ),
      UserAvatar(
        imageUrl: Images.forestImg,
        coordinates: MapCordinates(latitude: 20, longitude: 50),
      ),
    ],
    mapItems: [
      MapItem(
        id: 'pin1',
        iconUrl: Images.forestImg,
        coordinates: MapCordinates(latitude: 0, longitude: 0),
        associatedDetailId: 'goa_drift',
      ),
      MapItem(
        id: 'pin2',
        iconUrl: Images.earthImg,
        coordinates: MapCordinates(latitude: 10, longitude: 32),
      ),
      MapItem(
        id: 'pin3',
        iconUrl: Images.rainThunder,
        coordinates: MapCordinates(latitude: 20, longitude: 50),
      ),
    ],
    detailCards: [
      MapDetailCardData(
        distance: 4.5,
        distanceUnit: 'KM',
        title: 'Goa Drift',
        pinCount: 3,
        imageCount: 4,
        audioCount: 2,
        reactionEmojis: [Images.confusionImg,Images.dancingImg,Images.dancingImg],
        viewsCount: 34,
      ),
      // Add more detail cards if you have multiple locations with details
    ],
  );

  @override
  void initState() {
    super.initState();
    // Initially display the first detail card for demonstration
    if (_mapData.detailCards.isNotEmpty) {
      _currentDetailCard = _mapData.detailCards.first;
    }
  }

  // A helper function to simulate tapping on a map item to show its details
  void _showDetailCardForMapItem(String? detailId) {
    setState(() {
      if (detailId != null) {
        _currentDetailCard = _mapData.detailCards.firstWhere(
          (card) => card.title
              .toLowerCase()
              .contains(detailId.toLowerCase()), // Simple matching
          orElse: () => _mapData.detailCards.first, // Fallback if not found
        );
      } else {
        _currentDetailCard = null; // Hide card if no detailId
      }
    });
  }

  final List<Tapu> _dummyPins = [
    Tapu(
      id: '1',
      latitude: 100, // Dummy position for screenshot
      longitude: 190, // Dummy position for screenshot
      imageUrl: Images.aeroplaneImg, // Now points to a network URL
      moodIconUrl: Images.aeroplanePersonImg, // Now points to a network URL
      title: 'Serene Lake',
    ),
    Tapu(
      id: '2',
      latitude: 250,
      longitude: 280,
      imageUrl: Images.aeroplaneImg,
      moodIconUrl: Images.aeroplanePersonImg,
      title: 'Stormy Sea',
    ),
    Tapu(
      id: '3',
      latitude: 120,
      longitude: 400,
      imageUrl: Images.aeroplaneImg,
      moodIconUrl: Images.aeroplanePersonImg,
      title: 'Forest Path',
    ),
    Tapu(
      id: '4',
      latitude: 380,
      longitude: 180,
      imageUrl: Images.aeroplaneImg,
      moodIconUrl: Images.aeroplanePersonImg,
      title: 'Green Hills',
    ),
    Tapu(
      id: '5',
      latitude: 300,
      longitude: 400,
      imageUrl: Images.aeroplaneImg,
      moodIconUrl: Images.aeroplanePersonImg,
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

          //
          ..._dummyPins.map(
            (tapu) => MapTapuWidget(
              
              tapu:
                  tapu, // MapPinWidget now correctly uses Image.network internally
              onTap: (selectedPin) {
                NavigationService.pushNamed('/tapu-detail');
                
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
                        "Tapu's",
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

          // --- Floating Action Buttons ---
          Positioned(
            bottom: 300, // Adjust position based on bottom sheet height
            left: 16,
            child: FloatingActionButton(
              shape: CircleBorder(),
              heroTag: 'mood_fab', // Unique tag for multiple FABs
              onPressed: () {
                NavigationService.pushNamed('/create-tapu');
                print('Smiley/Mood FAB tapped');
              },
              backgroundColor: Color(0xFF531DAB),
              child: Image.network(
                Images.addIcon,
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
            bottom: 300, // Adjust position
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
              height: 80, // Reduced height to fit only the bottom nav
              decoration: BoxDecoration(
                color: Color(0xFF15212F),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Color(0xFF1D1F24), // Slightly darker for bottom nav
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildBottomNavItem('My Pins', Images.myPinsImg, () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => MyPinsScreen()));
                    }),
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
            ),
          ),
          // --- Detail Card (Above Bottom Sheet) ---
          if (_currentDetailCard != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 70, // Height of the bottom sheet
              child: MapDetailCard(
                data: _currentDetailCard!,
                onClose: () {
                  setState(() {
                    _currentDetailCard = null; // Hide the card
                  });
                },
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
}

