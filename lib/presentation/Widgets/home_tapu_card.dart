// lib/presentation/Widgets/home_tapu_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/home_tapu_card_data.dart';
import 'package:memory_pins_app/presentation/Pages/tapu_pins.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart'; // Assuming you have these styles

class HomeTapuCard extends StatelessWidget {
  final HomeTapuCardData data;

  const HomeTapuCard({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF253743), // Dark background for the card
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Main Image Section with Location Overlay ---
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8), bottom: Radius.circular(40)),
                child: Image.network(
                  data.mainImageUrl,
                  height: 220, // Fixed height for the main image
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 220,
                      color: Colors.grey[800],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[800],
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.grey, size: 50),
                    ),
                  ),
                ),
              ),
              // Location overlay at top-left
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.06),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(2, 12),
                        ),
                      ]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(Images.mapMarketImg, height: 14),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          data.locationName,
                          style: GoogleFonts.nunitoSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          Images.locationRedIcon, // Assuming local asset
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data.tapuName,
                          style: text20W800White(context),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderColor1),
                        color: AppColors
                            .bgGroundYellow, // Yellow background for share icon
                        boxShadow: [
                          AppColors.backShadow,
                        ],
                        shape: BoxShape.circle,
                      ),
                      child: GestureDetector(
                        onTap: () {
                          NavigationService.pushNamed('/map-view');
                        },
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Image.asset(
                              Images.sendIcon, // Share icon
                              height: 20,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),

                // Content Counts (Pins/Photos, Images, Audios)
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: Colors.white),
                              child: ClipOval(
                                  child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Image.asset(
                                  Images.redPinIcon,
                                  height: 16,
                                ),
                              ))),
                          const SizedBox(width: 4.0),
                          Text(
                            '${data.pinCount} Pins', // Changed to Photos as seen in screenshots
                            style: text14W600White(
                                context), // Assuming white text style
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset(
                            Images.photolibrary, // Image library icon
                            height: 20,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '${data.imageCount_text} Images', // Dynamic 'X Images'
                            style: text14W600White(context),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Image.asset(
                            Images.audioIcon, // Audio icon
                            height: 20,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '${data.audioCount} Audios',
                            style: text14W600White(context),
                          ),
                        ],
                      )
                      // Pins/Photo
                    ]) //
                ,

                Wrap(
                  spacing: 8.0, // horizontal space between images
                  runSpacing: 4.0, // vertical space between lines of images
                  children: data.reactionEmojis
                      .map((imgUrl) => Image.network(
                            imgUrl,
                            width: 24,
                            height: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.error, size: 24),
                          ))
                      .toList(),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        '${data.viewsCount} Views',
                        style: text12W700Yellow(context),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Flexible(
                      child: Text(
                        '${data.playsCount} Plays',
                        style: text12W700Yellow(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tapu Name & Pin Icon Overlay

          // Preview Images Horizontal List

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: GestureDetector(
              onTap: () {
                // Navigate to Tapu Pins with the original Tapus data
                if (data.originalTapus != null) {
                  NavigationService.pushNamed('/tapu-pins',
                      arguments: data.originalTapus);
                } else {
                  // Fallback to named route if no Tapus data
                  NavigationService.pushNamed('/tapu-pins');
                }
              },
              child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: AppColors.bgGroundYellow,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: AppColors.borderColor1, width: 1),
                      boxShadow: [
                        AppColors.backShadow,
                      ]),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                        child: Text(
                      "View Tapu",
                      style: GoogleFonts.nunitoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black),
                    )),
                  )),
            ),
          ),
        ],
      ),
    );
  }
}
