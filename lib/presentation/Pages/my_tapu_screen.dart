// lib/screens/my_tapus_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/home_tapu_card_data.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/models/map_coordinates.dart';
import 'package:memory_pins_app/presentation/Pages/create_pin_screen.dart';
import 'package:memory_pins_app/presentation/Pages/create_tapu_screen.dart';
import 'package:memory_pins_app/presentation/Pages/tapu_detail_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/home_tapu_card.dart';
import 'package:memory_pins_app/providers/tapu_provider.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:provider/provider.dart';

class MyTapusScreen extends StatefulWidget {
  const MyTapusScreen({Key? key}) : super(key: key);

  @override
  State<MyTapusScreen> createState() => _MyTapusScreenState();
}

class _MyTapusScreenState extends State<MyTapusScreen> {
  List<HomeTapuCardData> _tapuCards = [];
  List<Tapus> _originalTapus = []; // Store original Tapus objects
  bool _isLoading = true;
  bool _isLoadingDetails = false; // Loading detailed statistics
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserTapus();
  }

  Future<void> _loadUserTapus() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tapuProvider = Provider.of<TapuProvider>(context, listen: false);
      await tapuProvider.loadUserTapus();

      final userTapus = tapuProvider.userTapus;
      print('Loaded ${userTapus.length} user tapus');

      // Convert Tapus to HomeTapuCardData
      final tapuCards =
          userTapus.map((tapu) => _convertTapusToHomeCardData(tapu)).toList();

      setState(() {
        _tapuCards = tapuCards;
        _originalTapus = userTapus; // Store original Tapus
        _isLoading = false;
      });

      // Load detailed statistics for each Tapus
      await _loadDetailedStatistics();
    } catch (e) {
      print('Error loading user tapus: $e');
      setState(() {
        _error = 'Failed to load tapus: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDetailedStatistics() async {
    try {
      setState(() {
        _isLoadingDetails = true;
      });

      final tapuProvider = Provider.of<TapuProvider>(context, listen: false);

      // Load detailed statistics for each Tapus
      for (int i = 0; i < _originalTapus.length; i++) {
        final tapus = _originalTapus[i];
        final statistics = await tapuProvider.getTapusDetailedStatistics(tapus);

        // Update the corresponding card with real data
        setState(() {
          _tapuCards[i] = HomeTapuCardData(
            id: _tapuCards[i].id,
            locationName: _tapuCards[i].locationName,
            tapuName: _tapuCards[i].tapuName,
            mainImageUrl: _tapuCards[i].mainImageUrl,
            ownerAvatarUrl: _tapuCards[i].ownerAvatarUrl,
            emojis: _tapuCards[i].emojis,
            pinCount: statistics['totalPins'] as int,
            imageCount: statistics['totalImages'] as int,
            imageCount_text: statistics['totalImages'] as int,
            audioCount: statistics['totalAudios'] as int,
            viewsCount: statistics['totalViews'] as int,
            playsCount: statistics['totalPlays'] as int,
            previewImageUrls: _tapuCards[i].previewImageUrls,
            reactionEmojis: _tapuCards[i].reactionEmojis,
            originalTapus:
                _tapuCards[i].originalTapus, // Preserve original Tapus data
          );
        });
      }

      setState(() {
        _isLoadingDetails = false;
      });
    } catch (e) {
      print('Error loading detailed statistics: $e');
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  HomeTapuCardData _convertTapusToHomeCardData(Tapus tapu) {
    // Use the real location name from Tapus data, fallback to coordinates if empty
    final locationName = tapu.location.isNotEmpty
        ? tapu.location
        : _getLocationNameFromCoordinates(
            tapu.centerCoordinates.latitude,
            tapu.centerCoordinates.longitude,
          );

    return HomeTapuCardData(
      id: tapu.id,
      locationName: locationName,
      tapuName: tapu.name,
      mainImageUrl: tapu.centerPinImageUrl.isNotEmpty
          ? tapu.centerPinImageUrl
          : Images.myTapuImg1, // Fallback image
      ownerAvatarUrl: tapu.avatarUrl.isNotEmpty
          ? tapu.avatarUrl
          : Images.childUmbrella, // Fallback avatar
      emojis: tapu.emojis.isNotEmpty
          ? tapu.emojis
          : [Images.umbrellaImg], // Fallback emoji
      pinCount: tapu.totalPins,
      imageCount: tapu.totalPins, // Will be updated with real data
      imageCount_text: tapu.totalPins, // Will be updated with real data
      audioCount: 0, // Will be updated with real data
      viewsCount: 0, // Will be updated with real data
      playsCount: 0, // Will be updated with real data
      previewImageUrls: tapu.centerPinImageUrl.isNotEmpty
          ? [tapu.centerPinImageUrl]
          : [Images.myTapuImg1, Images.myTapuImg2],
      reactionEmojis: tapu.emojis.isNotEmpty
          ? tapu.emojis
          : [Images.dancingImg, Images.confusionImg],
      originalTapus: tapu, // Store original Tapus data
    );
  }

  String _getLocationNameFromCoordinates(double latitude, double longitude) {
    // For now, return a simple location name
    // In the future, you can implement reverse geocoding here
    if (latitude == 0.0 && longitude == 0.0) {
      return 'Unknown Location';
    }
    return 'Location ${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
  }

  void _navigateToCreateTapu() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateTapuScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF131F2B),
        body: RefreshIndicator(
          onRefresh: _loadUserTapus,
          child: SingleChildScrollView(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "My Tapus",
                          style: text18W700White(context),
                        ),
                        GestureDetector(
                          onTap: _navigateToCreateTapu,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Color(0xFF253743),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Image.network(
                                Images.addTapuImg,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Loading state
                    if (_isLoading)
                      Center(
                        child: CircularProgressIndicator(
                          color: AppColors.bgGroundYellow,
                        ),
                      ),

                    // Loading details state
                    if (!_isLoading &&
                        _isLoadingDetails &&
                        _tapuCards.isNotEmpty)
                      Column(
                        children: [
                          ListView.separated(
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 80.0),
                            itemCount: _tapuCards.length,
                            itemBuilder: (context, index) {
                              final cardData = _tapuCards[index];
                              return GestureDetector(
                                onTap: () {
                                  // Find the original Tapus object by ID
                                  final originalTapu =
                                      _originalTapus.firstWhere(
                                    (tapu) => tapu.id == cardData.id,
                                    orElse: () => Tapus(
                                      // Fallback if not found
                                      id: cardData.id,
                                      name: cardData.tapuName,
                                      avatarUrl: cardData.ownerAvatarUrl,
                                      centerPinImageUrl: cardData.mainImageUrl,
                                      centerCoordinates: MapCoordinates(
                                        latitude: 0.0,
                                        longitude: 0.0,
                                      ),
                                      totalPins: cardData.pinCount,
                                      emojis: cardData.emojis,
                                      location: cardData
                                          .locationName, // Include location
                                    ),
                                  );

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TapuDetailScreen(tapu: originalTapu),
                                    ),
                                  );
                                },
                                child: HomeTapuCard(
                                  data: cardData,
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: AppColors.bgGroundYellow,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Loading detailed statistics...',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
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
                              onPressed: _loadUserTapus,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      ),

                    // Empty state - show create tapu option
                    if (!_isLoading && _error == null && _tapuCards.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            SizedBox(height: 50),
                            Icon(
                              Icons.add_location_alt,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Tapus yet',
                              style: text18W700White(context),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create your first Tapu to get started',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _navigateToCreateTapu,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.bgGroundYellow,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                'Create Tapu',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Tapus list
                    if (!_isLoading && _error == null && _tapuCards.isNotEmpty)
                      ListView.separated(
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 80.0),
                        itemCount: _tapuCards.length,
                        itemBuilder: (context, index) {
                          final cardData = _tapuCards[index];
                          return GestureDetector(
                            onTap: () {
                              // Navigate to tapu detail screen
                              // Find the original Tapus object by ID
                              final originalTapu = _originalTapus.firstWhere(
                                (tapu) => tapu.id == cardData.id,
                                orElse: () => Tapus(
                                  // Fallback if not found
                                  id: cardData.id,
                                  name: cardData.tapuName,
                                  avatarUrl: cardData.ownerAvatarUrl,
                                  centerPinImageUrl: cardData.mainImageUrl,
                                  centerCoordinates: MapCoordinates(
                                    latitude: 0.0,
                                    longitude: 0.0,
                                  ),
                                  totalPins: cardData.pinCount,
                                  emojis: cardData.emojis,
                                ),
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TapuDetailScreen(tapu: originalTapu),
                                ),
                              );
                            },
                            child: HomeTapuCard(
                              data: cardData,
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
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
        ));
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
