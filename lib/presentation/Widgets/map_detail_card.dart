// widgets/map_detail_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/home_tapu_card_data.dart';
import 'package:memory_pins_app/models/tapu.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/models/map_coordinates.dart';
import 'package:memory_pins_app/presentation/Pages/tapu_detail_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/pin_detail_popup.dart';
import 'package:memory_pins_app/providers/tapu_provider.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:provider/provider.dart';

class MapDetailCard extends StatelessWidget {
  final Tapu tapu;
  final VoidCallback? onClose;
  final HomeTapuCardData?
      data; // Callback for when the card is closed/minimized

  const MapDetailCard({
    Key? key,
    required this.tapu,
    this.onClose,
    this.data,
  }) : super(key: key);

  void _navigateToTapuDetail(BuildContext context) {
    print('Navigating to Tapu Detail Screen for: ${tapu.title}');

    // Convert Tapu to Tapus for the detail screen
    final tapus = Tapus(
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
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TapuDetailScreen(tapu: tapus),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final tapuProvider = Provider.of<TapuProvider>(context, listen: false);
    final distanceText = tapuProvider.getTapuDistanceText(tapu);

    // Debug: Print the emojis being displayed
    print('MapDetailCard for "${tapu.title}":');
    print('  photoUrls (emojis): ${tapu.photoUrls}');
    print('  moodIconUrl: ${tapu.moodIconUrl}');

    return GestureDetector(
      onTap: () => _navigateToTapuDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF15212F), // Dark background from screenshot
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -3), // subtle shadow at the top
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF253743),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                  spacing: 16,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              distanceText,
                              style: text14W400White(context),
                            ),
                            SizedBox(
                              width: 4,
                            ),

                            const SizedBox(width: 4.0),

                            Image.asset(
                              Images.trackImage,
                              height: 20,
                            ),
                            // Pushes "Goa Drift" to the right
                          ],
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
                              onTap: () => _navigateToTapuDetail(context),
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
                    // Distance Row

                    Column(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.asset(
                              Images.locationRedIcon,
                              height: 20,
                            ),
                            Text(
                              tapu.title,
                              style: text18W700White(context),
                            ),
                          ],
                        ),

                        // Counts Row (Pins, Images, Audios)
                        Row(
                          children: [
                            Container(
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white),
                                child: ClipOval(
                                    child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Image.asset(
                                    Images.redPinIcon,
                                    height: 16,
                                  ),
                                ))),
                            const SizedBox(width: 4.0),
                            Flexible(
                              child: Text(
                                '${tapu.totalPins} Pins',
                                style: text14W800Yellow(context),
                              ),
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            Image.asset(
                              Images.photolibrary,
                              height: 20,
                            ),
                            const SizedBox(width: 4.0),
                            Flexible(
                              child: Text(
                                '${tapu.imageCount} Images', // Use actual calculated image count
                                style: text14W600White(context),
                              ),
                            ),
                            const SizedBox(width: 20.0),
                            Image.asset(
                              Images.audioIcon,
                              height: 20,
                            ),
                            const SizedBox(width: 4.0),
                            Flexible(
                              child: Text(
                                '${tapu.audioCount} Audios', // Use actual calculated audio count
                                style: text14W600White(context),
                              ),
                            ),
                          ],
                        ),

                        // Reaction Emojis (now as images)
                        Wrap(
                          spacing: 8.0, // horizontal space between images
                          runSpacing:
                              4.0, // vertical space between lines of images
                          children: tapu.photoUrls.isNotEmpty
                              ? tapu.photoUrls
                                  .map((imgUrl) => Image.network(
                                        imgUrl,
                                        width: 30,
                                        height: 30,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(Icons.error, size: 30),
                                      ))
                                  .toList()
                              : [
                                  Image.network(
                                    tapu.moodIconUrl,
                                    width: 30,
                                    height: 30,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Icon(Icons.error, size: 30),
                                  )
                                ],
                        ),

                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.end, // Align to the right
                          children: [
                            Text(
                              '${tapu.views} Views',
                              style: GoogleFonts.nunitoSans(
                                  color: AppColors.bgGroundYellow,
                                  fontSize: width * 0.03,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 16.0),
                            Text(
                              '${tapu.plays} Plays',
                              style: GoogleFonts.nunitoSans(
                                  color: AppColors.bgGroundYellow,
                                  fontSize: width * 0.03,
                                  fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),

                        // Views Count

                        // Padding before bottom nav
                      ],
                    ),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}
