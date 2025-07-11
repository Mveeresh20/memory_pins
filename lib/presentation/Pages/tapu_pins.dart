import 'package:flutter/material.dart';
import 'package:memory_pins_app/models/tapu_pins_item.dart';
import 'package:memory_pins_app/presentation/Widgets/tapu_pins_card.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';

class TapuPins extends StatefulWidget {
  const TapuPins({super.key});

  @override
  State<TapuPins> createState() => _TapuPinsState();
}

class _TapuPinsState extends State<TapuPins> {

  final List<TapuPinsItem> _allPins = [
    TapuPinsItem(
      id: '1',
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
    TapuPinsItem(
      id: '2',

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
    TapuPinsItem(
      id: '3',

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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
        child: SingleChildScrollView(
          child: SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    
                    Center(child: Text("Goa Drift", 
                    textAlign: TextAlign.center,
                    style: text18W700White(context))),

                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(colors: [
                          Color(0xFFF5C253),
                          Color(0xFFEBA145)

                        ])

                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: GestureDetector(
                          onTap: () {
                            NavigationService.pushNamed('/tapu-detail');
                          },
                          child: Icon(Icons.map,color: Colors.white,)),
                      )),


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
                    return TapuPinsCard(
                        tapuPins: pin); // Pass the dynamic data to your card widget
                  },
                )


              ],
            ),
          ),
        ),
      ),
    );
  }
}
