// lib/screens/my_tapus_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/home_tapu_card_data.dart';
import 'package:memory_pins_app/presentation/Pages/create_pin_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/home_tapu_card.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart'; // For bottom nav bar colors

class MyTapusScreen extends StatefulWidget {
  const MyTapusScreen({Key? key}) : super(key: key);

  @override
  State<MyTapusScreen> createState() => _MyTapusScreenState();
}

class _MyTapusScreenState extends State<MyTapusScreen> {
  // Dummy data for Tapu cards on this screen
  List<HomeTapuCardData> _tapuCards = [];

  @override
  void initState() {
    super.initState();
    _tapuCards = _getDummyTapuCards();
  }

  List<HomeTapuCardData> _getDummyTapuCards() {
    return [
      HomeTapuCardData(
        id: 'new_jersey_id',
        locationName: 'New Jersey',
        tapuName: 'Goa Drift', // స్క్రీన్‌షాట్‌లో ఇలా ఉంది
        mainImageUrl: Images.myTapuImg1, // ఉదాహరణ URL
        ownerAvatarUrl: Images.childUmbrella, // ఉదాహరణ URL
        emojis: [
          Images.umbrellaImg,
          Images.childUmbrella,
          Images.umbrellaImg
        ], // ఉదాహరణ ఎమోజిలు
        pinCount: 3, // "3 Pins"
        imageCount: 4, // 4 Images
        imageCount_text: 4, // for the text "4 Images"
        audioCount: 2, // "2 Audios"
        viewsCount: 34, // "34 Views"
        playsCount: 12, // "12 Plays"
        previewImageUrls: [
          Images.myTapuImg1,
          Images.myTapuImg2,
        ],
        reactionEmojis: [
          Images.dancingImg,
          Images.confusionImg,
          Images.dancingImg
        ],
      ),
      HomeTapuCardData(
        id: 'washington_dc_id',
        locationName: 'Washington DC',
        tapuName: 'Sunset Goodbye', // స్క్రీన్‌షాట్‌లో ఇలా ఉంది
        mainImageUrl: Images.myTapuImg2, // ఉదాహరణ URL
        ownerAvatarUrl: Images.childUmbrella, // ఉదాహరణ URL
        emojis: [Images.childUmbrella, Images.umbrellaImg], // ఉదాహరణ ఎమోజిలు
        pinCount: 7, // "7 Photos"
        imageCount:
            9, // "9 Photos" in the detail card, but "4 Images" on home card. Let's use 9 for consistency if it refers to total attachments.
        imageCount_text: 4, // For the text "4 Images" as seen in screenshot
        audioCount: 2, // "2 Audios"
        viewsCount: 500, // "500 Views"
        playsCount: 5, // "05Plays"
        previewImageUrls: [
          Images.myTapuImg1,
          Images.myTapuImg2,
        ],
        reactionEmojis: [
          Images.confusionImg,
          Images.dancingImg,
          Images.confusionImg
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFF131F2B), // Dark background for the screen

        body: SingleChildScrollView(
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
                      Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Color(0xFF253743)),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.network(
                              Images.addTapuImg,
                              fit: BoxFit.contain,
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ListView.separated(
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 80.0),
                    itemCount: _tapuCards.length,
                    itemBuilder: (context, index) {
                      final cardData = _tapuCards[index];
                      return HomeTapuCard(
                        data: cardData,
                        // onViewTapu: () { },
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        ),
        // --- Bottom Navigation Bar ---
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
