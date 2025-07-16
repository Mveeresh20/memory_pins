import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/models/pin_detail.dart';
import 'package:memory_pins_app/presentation/Pages/create_pin_screen.dart';
import 'package:memory_pins_app/presentation/Pages/map_view_screen.dart';
import 'package:memory_pins_app/presentation/Pages/my_pins_screen.dart';
import 'package:memory_pins_app/presentation/Pages/pin_detail_screen.dart';
// Correct Google Maps widget with custom UI
import 'package:memory_pins_app/presentation/Widgets/map_pin_widget.dart';
import 'package:memory_pins_app/services/edit_profile_provider.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/services/app_integration_service.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:memory_pins_app/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:memory_pins_app/utills/Constants/ui.dart'; // Your custom image paths
import 'package:geolocator/geolocator.dart';
import 'package:memory_pins_app/services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'Nearby';
  final AppIntegrationService _appService = AppIntegrationService();
  final GlobalKey<HomeMapWidgetState> _mapKey = GlobalKey<HomeMapWidgetState>();
  String _currentCity = 'Loading...'; // Add current city state
  final LocationService _locationService =
      LocationService(); // Add location service
  Pin? _selectedPin;
  final DraggableScrollableController _bottomSheetController =
      DraggableScrollableController();
  bool _isFirstLoad = true; // Add first load state

  @override
  void initState() {
    super.initState();
    // Load pins when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPins(); // Wait for pins to load
      _getCurrentCity(); // Get current city
    });
  }

  Future<void> _loadPins() async {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    if (!pinProvider.isInitialized) {
      print('HomeScreen - Initializing PinProvider for first time...');
      await pinProvider.initialize(); // Wait for initialization to complete
      print('HomeScreen - PinProvider initialization completed');
    }

    // Mark first load as complete
    if (_isFirstLoad) {
      setState(() {
        _isFirstLoad = false;
      });
    }
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

  void _showPinDetails(Pin pin) {
    setState(() {
      _selectedPin = pin;
    });
    // Safely animate the bottom sheet to show pin details
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_bottomSheetController.isAttached) {
        _bottomSheetController.animateTo(
          0.5, // Show 50% of the screen to display pin details
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _hidePinDetails() {
    if (_bottomSheetController.isAttached) {
      _bottomSheetController
          .animateTo(
        0.18, // Return to normal size (filters only)
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInCubic,
      )
          .then((_) {
        setState(() {
          _selectedPin = null;
        });
      });
    } else {
      // If controller is not attached, just clear the selection
      setState(() {
        _selectedPin = null;
      });
    }
  }

  // Convert Pin data to PinDetail data for the detail screen
  PinDetail _convertPinToPinDetail(Pin pin) {
    print('Converting pin: ${pin.title}');
    print('Pin has description: ${pin.description}');
    print('Pin has ${pin.audioUrls.length} audio URLs');

    // Convert image URLs to PhotoItem list
    List<PhotoItem> photos =
        pin.imageUrls.map((url) => PhotoItem(imageUrl: url)).toList();

    // Convert audio URLs to AudioItem list
    List<AudioItem> audios = [];
    for (int i = 0; i < pin.audioUrls.length; i++) {
      audios.add(AudioItem(
        audioUrl: pin.audioUrls[i],
        duration:
            '${(i + 1) * 2}:${(i + 1) * 10}', // Will be updated with actual duration
      ));
    }

    // Use the actual description from the pin, with fallback for null/empty
    String description = (pin.description?.isNotEmpty == true)
        ? pin.description!
        : 'A beautiful memory captured at ${pin.location}. This pin contains ${pin.photoCount} photos and ${pin.audioCount} audio recordings.';

    print('Final description: $description');
    print('Created ${audios.length} audio items');

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
    print('Pin description: ${pin.description}');

    final pinDetail = _convertPinToPinDetail(pin);
    print('Converted pin detail title: ${pinDetail.title}');
    print('Converted pin detail description: ${pinDetail.description}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinDetailScreen(
          pinDetail: pinDetail,
          originalPin: pin, // Pass the original pin object
        ),
      ),
    );
  }

  void showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 270,
            height: 122.5,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2730),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Title and subtitle
                Padding(
                  padding: const EdgeInsets.only(
                    top: 18,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 238,
                        child: Text(
                          "Exit App",
                          style: const TextStyle(
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            height: 22 / 17,
                            letterSpacing: -0.41,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 238,
                        child: Text(
                          "Are you sure you want to exit app?",
                          style: const TextStyle(
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            height: 18 / 13,
                            letterSpacing: -0.08,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Buttons
                Row(
                  children: [
                    // Not Now
                    SizedBox(
                      width: 134.75,
                      height: 44,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 8,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(14),
                            ),
                          ),
                          foregroundColor: const Color(0xFF007AFF),
                          backgroundColor: Colors.transparent,
                          textStyle: const TextStyle(
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                            fontSize: 17,
                            letterSpacing: -0.41,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Not Now"),
                      ),
                    ),
                    // Yes
                    SizedBox(
                      width: 134.75,
                      height: 44,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 8,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(14),
                            ),
                          ),
                          foregroundColor: const Color(0xFFF23943),
                          backgroundColor: Colors.transparent,
                          textStyle: const TextStyle(
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                            fontSize: 17,
                            letterSpacing: -0.41,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          SystemNavigator.pop(); // This will exit the app
                        },
                        child: const Text("Yes"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showExitDialog(context);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100], // A light background for the map
        bottomNavigationBar: _buildCustomBottomNavBar(context),
        body: Consumer2<PinProvider, UserProvider>(
          builder: (context, pinProvider, userProvider, child) {
            final pins = pinProvider.filteredPins;
            final isLoading = pinProvider.isLoading;
            final isInitialized = pinProvider.isInitialized;
            final currentUser = userProvider.currentUser;

            print('HomeScreen - Building with ${pins.length} filtered pins');
            print('HomeScreen - Filter type: ${pinProvider.filterType}');
            print(
                'HomeScreen - Total nearby pins: ${pinProvider.nearbyPins.length}');

            return Stack(
              children: [
                // --- Google Maps Background ---
                Positioned.fill(
                  child: HomeMapWidget(
                    key: _mapKey,
                    pins: pins,
                    onPinTap: (selectedPin) {
                      print('Tapped on pin: ${selectedPin.title}');
                      _showPinDetails(selectedPin);
                    },
                    isLoading: isLoading,
                    getPinDistance: (pin) {
                      final pinProvider =
                          Provider.of<PinProvider>(context, listen: false);
                      return pinProvider.getPinDistance(pin);
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
                            'Loading pins...',
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

                // --- Map controls and overlays will be added here ---

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
                        Consumer<EditProfileProvider>(
                          builder: (context, provider, child) {
                            return GestureDetector(
                              onTap: () {
                                NavigationService.pushNamed('/profile');
                              },
                              child: CircleAvatar(
                                radius: 20,
                                backgroundImage:
                                    NetworkImage(provider.getProfileImageUrl()),
                              ),
                            );
                          },
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
                          print('Smiley/Mood FAB tapped');
                          // TODO: Navigate to mood/tapu creation
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
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MapViewScreen()));
                        },
                        backgroundColor: Color(0xFFF5BF4D),
                        child: Image.network(Images.layersImg),
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

                            // --- Filter Buttons (Always Visible) ---
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      print(
                                          'HomeScreen - Nearby filter button pressed');
                                      setState(() {
                                        _selectedFilter = 'Nearby';
                                      });
                                      pinProvider.setFilterType('nearby');

                                      // Force refresh with a small delay to ensure filter is applied
                                      Future.delayed(
                                          Duration(milliseconds: 150), () {
                                        print(
                                            'HomeScreen - Refreshing map after filter change');
                                        _mapKey.currentState?.refreshPins();
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _selectedFilter == 'Nearby'
                                            ? Color(0xFFF5BF4D)
                                            : Color(0xFFFFECC3),
                                        borderRadius: BorderRadius.circular(57),
                                        border: Border.all(
                                            width: 1, color: Colors.white),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(Images.mapMarketImg,
                                                height: 16),
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
                                  ),
                                  SizedBox(width: 24),
                                  GestureDetector(
                                    onTap: () {
                                      print(
                                          'HomeScreen - More than 5KM filter button pressed');
                                      setState(() {
                                        _selectedFilter = 'More than 5 KM';
                                      });
                                      pinProvider.setFilterType('far');

                                      // Force refresh with a small delay to ensure filter is applied
                                      Future.delayed(
                                          Duration(milliseconds: 150), () {
                                        print(
                                            'HomeScreen - Refreshing map after filter change');
                                        _mapKey.currentState?.refreshPins();
                                      });
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color:
                                            _selectedFilter == 'More than 5 KM'
                                                ? Color(0xFFF5BF4D)
                                                : Color(0xFFFFECC3),
                                        borderRadius: BorderRadius.circular(57),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 16,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(Images.mapMarketImg,
                                                height: 16),
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
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 24),

                            // --- Pin Details Content (Scrollable) ---
                            if (_selectedPin != null) ...[
                              const SizedBox(height: 16),
                              // Pin details content
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: scrollController,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: _PinDetailsContent(
                                    pin: _selectedPin!,
                                    onSend: () =>
                                        _navigateToPinDetail(_selectedPin!),
                                  ),
                                ),
                              ),
                            ],
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
        backgroundColor: Color(0xFFEBA145),
        elevation: 5, // Yellow like the filter buttons
        child: Icon(Icons.map, color: Colors.white, size: 24), // Tapus icon
        // Lift it above the bottom nav
      ),
    );
  }
}

class _PinDetailsContent extends StatelessWidget {
  final Pin pin;
  final VoidCallback onSend;

  const _PinDetailsContent({
    required this.pin,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final pinProvider = Provider.of<PinProvider>(context, listen: false);
    final distanceText = pinProvider.getPinDistance(pin);
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pin Details Card
        Container(
          decoration: BoxDecoration(
            border: Border.all(width: 1, color: Colors.white.withOpacity(0.2)),
            borderRadius: UI.borderRadius16,
            color: AppColors.frameBgColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Distance, Flag, Send Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              distanceText,
                              style: text14W400White(context),
                            ),
                          ),
                          SizedBox(width: 4),
                          Image.asset(
                            Images.trackImage,
                            height: 20,
                          )
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
                      child: ClipOval(
                        child: GestureDetector(
                          onTap: () {
                            print('Send icon tapped!');
                            onSend();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              Images.sendIcon,
                              height: 20,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Pin Title and Emoji
                Row(
                  children: [
                    Image.asset(
                      Images.locationRedIcon,
                      height: 20,
                      fit: BoxFit.contain,
                    ),
                    Flexible(
                      child: Text(
                        pin.title,
                        style: text18W700White(context),
                      ),
                    ),
                    SizedBox(width: 4),
                    if (pin.emoji != null)
                      Image.network(
                        pin.emoji!,
                        height: 20,
                        fit: BoxFit.contain,
                      )
                  ],
                ),
                const SizedBox(height: 8.0),

                // Photos and Audios Count
                Row(
                  children: [
                    Image.asset(
                      Images.photolibrary,
                      height: 20,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '${pin.photoCount} Photos',
                      style: text14W500White(context),
                    ),
                    const SizedBox(width: 16.0),
                    Image.asset(
                      Images.audioIcon,
                      height: 20,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '${pin.audioCount} Audios',
                      style: text14W500White(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Image Previews
                Row(
                  spacing: 8,
                  children: [
                    ...pin.imageUrls.asMap().entries.take(4).map((entry) {
                      final idx = entry.key;
                      final url = entry.value;
                      double imageSize = width * 0.18;
                      if (idx == 3 && pin.imageUrls.length > 4) {
                        return Stack(
                          children: [
                            _buildPreviewImage(url, imageSize),
                            Container(
                              height: imageSize,
                              width: imageSize,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${pin.imageUrls.length - 3}+',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return _buildPreviewImage(url, imageSize);
                      }
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Views and Plays Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${pin.viewsCount} Views',
                      style: GoogleFonts.nunitoSans(
                        color: AppColors.bgGroundYellow,
                        fontSize: MediaQuery.of(context).size.width * 0.03,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Text(
                      '${pin.playsCount} Plays',
                      style: GoogleFonts.nunitoSans(
                        color: AppColors.bgGroundYellow,
                        fontSize: MediaQuery.of(context).size.width * 0.03,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Bottom padding
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPreviewImage(String url, double size) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(width: 1, color: Colors.white.withOpacity(0.5)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          height: size,
          width: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: size,
            width: size,
            color: Colors.grey[700],
            child: const Icon(Icons.image, color: Colors.white54, size: 30),
          ),
        ),
      ),
    );
  }
}
