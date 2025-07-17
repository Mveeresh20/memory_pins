import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/tapu.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/models/map_coordinates.dart';
import 'package:memory_pins_app/presentation/Pages/tapu_detail_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/map_tapu_widget.dart';
import 'package:memory_pins_app/presentation/Widgets/map_detail_card.dart';
import 'package:memory_pins_app/services/edit_profile_provider.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/services/location_service.dart';
import 'package:memory_pins_app/providers/tapu_provider.dart';
import 'package:memory_pins_app/providers/user_provider.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:provider/provider.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:geolocator/geolocator.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  Tapu? _selectedTapu;
  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();
  final GlobalKey<TapuMapWidgetState> _mapKey = GlobalKey<TapuMapWidgetState>();
  String _currentCity = 'Loading...';
  final LocationService _locationService = LocationService();
  bool _isFirstLoad = true; // Add flag for first load

  @override
  void initState() {
    super.initState();
    // Load tapus when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTapus();
      _getCurrentCity();
    });
  }

  void _loadTapus() async {
    final tapuProvider = Provider.of<TapuProvider>(context, listen: false);
    if (!tapuProvider.isInitialized) {
      print('First time loading tapus...');
      await tapuProvider.initialize(); // Wait for initialization to complete
      setState(() {
        _isFirstLoad = false;
      });
      print('Tapus loaded successfully');

      // Refresh the map widget to show the loaded tapus
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapKey.currentState?.refreshTapus();
      });
    } else {
      print('Tapus already initialized, using cached data');
      setState(() {
        _isFirstLoad = false;
      });

      // Refresh the map widget to show the cached tapus
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapKey.currentState?.refreshTapus();
      });
    }
  }

  // Method to refresh tapus manually
  void _refreshTapus() async {
    final tapuProvider = Provider.of<TapuProvider>(context, listen: false);
    setState(() {
      _isFirstLoad = true;
    });
    await tapuProvider.refresh();
    setState(() {
      _isFirstLoad = false;
    });
    _mapKey.currentState?.refreshTapus();
  }

  // Get current city based on user's location
  Future<void> _getCurrentCity() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        final city = await _getCityFromCoordinates(
            position.latitude, position.longitude);
        setState(() {
          _currentCity = city;
        });
      }
    } catch (e) {
      print('Error getting current city: $e');
      setState(() {
        _currentCity = 'Location unavailable';
      });
    }
  }

  // Get city name from coordinates using reverse geocoding
  Future<String> _getCityFromCoordinates(
      double latitude, double longitude) async {
    try {
      final locationData =
          await _locationService.reverseGeocode(latitude, longitude);

      if (locationData != null && locationData['address'] != null) {
        final address = locationData['address'] as Map<String, dynamic>;
        // Return city name from the address data
        return address['city'] ??
            address['town'] ??
            address['state'] ??
            'Unknown City';
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
    }
    return 'Unknown City';
  }

  void _showTapuDetails(Tapu tapu) {
    setState(() {
      _selectedTapu = tapu;
    });
    // Safely animate the bottom sheet to show tapu details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bottomSheetController.isAttached) {
        _bottomSheetController.animateTo(
          0.5, // Show 50% of the screen to display tapu details
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _hideTapuDetails() {
    if (_bottomSheetController.isAttached) {
      _bottomSheetController
          .animateTo(
        0.18, // Return to normal size (filters only)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInCubic,
      )
          .then((_) {
        setState(() {
          _selectedTapu = null;
        });
      });
    } else {
      // If controller is not attached, just clear the selection
      setState(() {
        _selectedTapu = null;
      });
    }
  }

  void _navigateToTapuDetail(Tapu tapu) async {
    try {
      // Ensure PinProvider has loaded pins first
      final pinProvider = Provider.of<PinProvider>(context, listen: false);
      if (pinProvider.nearbyPins.isEmpty) {
        await pinProvider.loadNearbyPins();
      }

      // Navigate to TapuDetailScreen with the loaded pins
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TapuDetailScreen(
            tapu: Tapus(
              id: tapu.id,
              name: tapu.title,
              avatarUrl: tapu.moodIconUrl,
              centerPinImageUrl: tapu.imageUrl,
              centerCoordinates: MapCoordinates(
                latitude: tapu.latitude,
                longitude: tapu.longitude,
              ),
              totalPins: tapu.totalPins,
              emojis: tapu.photoUrls, // Pass the emojis
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error navigating to tapu detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tapu details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: _buildCustomBottomNavBar(context),
      backgroundColor: Colors.grey[100], // A light background for the map
      body: Consumer2<TapuProvider, EditProfileProvider>(
        builder: (context, tapuProvider, editProfileProvider, child) {
          final tapus = tapuProvider.nearbyTapus;
          final isLoading = tapuProvider.isLoading;
          final isInitialized = tapuProvider.isInitialized;
          final userProfileImageUrl =
              editProfileProvider.getProfileImageUrlForScreens();

          // Debug logging
          print('MapViewScreen - Tapus count: ${tapus.length}');
          print('MapViewScreen - Is loading: $isLoading');
          print('MapViewScreen - Is initialized: $isInitialized');
          print('MapViewScreen - Is first load: $_isFirstLoad');
          print('MapViewScreen - User Profile Image URL: $userProfileImageUrl');

          return Stack(
            children: [
              // --- Google Maps Background ---
              Positioned.fill(
                child: TapuMapWidget(
                  key: _mapKey,
                  tapus: tapus,
                  onTapuTap: (selectedTapu) {
                    print('Tapped on tapu: ${selectedTapu.title}');
                    _navigateToTapuDetail(selectedTapu);
                  },
                  isLoading: isLoading,
                  userProfileImageUrl:
                      userProfileImageUrl, // Pass the profile image URL
                  getTapuDistance: (tapu) {
                    final tapuProvider =
                        Provider.of<TapuProvider>(context, listen: false);
                    return tapuProvider.getTapuDistanceText(tapu);
                  },
                ),
              ),

              // --- Loading Overlay ---
              if ((isLoading && !isInitialized) || _isFirstLoad)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Loading tapus...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // --- Map Control Buttons ---
              Positioned(
                top: 200, // Position below location selector
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
                          _mapKey.currentState?.zoomIn();
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
                          _mapKey.currentState?.zoomOut();
                        },
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                    // Location Button
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
                        icon: const Icon(Icons.my_location,
                            color: Colors.black87),
                        onPressed: () {
                          _mapKey.currentState?.centerOnUserLocation();
                        },
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                      ),
                    ),
                  ],
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

                      GestureDetector(
                    onTap: () {
                      NavigationService.pushNamed('/home');
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

                  SizedBox(width: 12),
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
                      Consumer<EditProfileProvider>(
                        builder: (context, provider, child) {
                          return GestureDetector(
                            onTap: () {
                              NavigationService.pushNamed('/profile');
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(
                                  provider.getProfileImageUrlForScreens()),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // --- Location Selector ---
              Positioned(
                top: 130, // Position relative to top bar
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        _currentCity,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // --- Floating Action Buttons (Positioned just above bottom sheet) ---
              AnimatedBuilder(
                animation: _bottomSheetController,
                builder: (context, child) {
                  final sheetHeight = _bottomSheetController.isAttached
                      ? _bottomSheetController.size
                      : 0.18; // Default to initial size if not attached
                  final screenHeight = MediaQuery.of(context).size.height;
                  final bottomPosition =
                      screenHeight * sheetHeight + 10; // 10px above the sheet

                  return Positioned(
                    bottom: bottomPosition,
                    left: 16,
                    child: FloatingActionButton(
                      shape: CircleBorder(),
                      heroTag: 'mood_fab',
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
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.sentiment_dissatisfied,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _bottomSheetController,
                builder: (context, child) {
                  final sheetHeight = _bottomSheetController.isAttached
                      ? _bottomSheetController.size
                      : 0.18; // Default to initial size if not attached
                  final screenHeight = MediaQuery.of(context).size.height;
                  final bottomPosition =
                      screenHeight * sheetHeight + 10; // 10px above the sheet

                  return Positioned(
                    bottom: bottomPosition,
                    right: 16,
                    child: FloatingActionButton(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      heroTag: 'stack_fab',
                      onPressed: () {
                        // NavigationService.pushNamed('/tapu-detail');
                        // TODO: Navigate to Saved Pins Screen
                      },
                      backgroundColor: Color(0xFFF5BF4D),
                      child: Image.network(Images.layersImg2),
                    ),
                  );
                },
              ),

              // --- Bottom UI Container (Sheet & Navigation) ---
              Align(
                alignment: Alignment.bottomCenter,
                child: DraggableScrollableSheet(
                  controller: _bottomSheetController,
                  initialChildSize:
                      0.18, // Reduced to make space for bottom nav
                  minChildSize: 0.18, // Minimum size to show filters
                  maxChildSize: 0.65, // Reduced max size to prevent overflow
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

                          // --- All Tapus List (Scrollable) ---
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Consumer<TapuProvider>(
                                builder: (context, tapuProvider, child) {
                                  final tapus = tapuProvider.nearbyTapus;

                                  if (tapus.isEmpty) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24,).copyWith(top: 30),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'No Tapu\'s/Pins found nearby',
                                            style: text18W600White(context),
                                          ),
                                          SizedBox(height: 20),
                                          Image.asset(
                                            "assets/images/notapus.png",
                                            fit: BoxFit.cover,
                                            height: 150,
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: tapus.map((tapu) {
                                      return Container(
                                        margin: EdgeInsets.only(bottom: 12),
                                        child: MapDetailCard(
                                          tapu: tapu,
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCustomBottomNavBar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: 15,
        bottom: MediaQuery.of(context).padding.bottom + 15,
      ),
      decoration: BoxDecoration(
        color: Color(0xFF1D1F24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem('My Pins', Images.myPinsImg, () {
            NavigationService.pushNamed('/my-pins');
          }),
          _buildCentralActionButton(() {
            print('Central Action Button tapped (Tapus/Main)');
            NavigationService.pushNamed('/tapu-pins');
          }),
          _buildBottomNavItem('New Pin', Images.newPinImg, () {
            NavigationService.pushNamed('/create-pin');
          }),
        ],
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

  Widget _buildCentralActionButton(VoidCallback onPressed) {
    return SizedBox(
      width: 48, // Make it a bit wider than others
      height: 48, // Make it taller for the floating effect
      child: FloatingActionButton(
        shape: CircleBorder(),
        heroTag: 'central_nav_fab',
        onPressed: onPressed,
        backgroundColor: Color(0xFFEBA145),
        elevation: 5, // Yellow like the filter buttons
        child: Icon(Icons.map, color: Colors.white, size: 24), // Tapus icon
        // Lift it above the bottom nav
      ),
    );
  }
}
