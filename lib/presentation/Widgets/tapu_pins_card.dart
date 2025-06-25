import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/tapu_pins_item.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:memory_pins_app/utills/Constants/ui.dart';

class TapuPinsCard extends StatelessWidget {

  final TapuPinsItem tapuPins;
  const TapuPinsCard({super.key, required this.tapuPins});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Colors.white.withOpacity(0.2)),
        borderRadius: UI.borderRadius16,
        color: AppColors.frameBgColor,
      ),
      child:

          // Dark background color from screenshot

          Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Location, Flag, Send Icon
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
                          tapuPins.location,
                          style: text14W400White(context),
                        ),
                      ),
                      SizedBox(
                        width: 4,
                      ),
                      Image.asset(
                        Images.trackImage,
                        height: 20,
                      )
                    ]
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    NavigationService.pushNamed('/pin-detail');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderColor1),
                      color: AppColors.bgGroundYellow,
                      boxShadow: [
                       AppColors.backShadow,
                      ],
                      shape: BoxShape.circle,
                      
                    ),
                    child: ClipOval(
                        child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(
                        Images.sendIcon,
                        height: 20,
                        fit: BoxFit.contain,
                      ),
                    )),
                  ),
                ),

                // Pushes the send icon to the right
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
                    tapuPins.title,
                    style: text18W700White(context),
                  ),
                ),
                SizedBox(
                  width: 4,
                ),
                if (tapuPins.emoji != null)
                  Image.network(
                    tapuPins.emoji!,
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
                  '${tapuPins.photoCount} Photos',
                  style: text14W500White(context),
                ),
                const SizedBox(width: 16.0),
                Image.asset(
                  Images.audioIcon,
                  height: 20,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '${tapuPins.audioCount} Audios',
                  style: text14W500White(context),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Image Previews
            Row(
              spacing: 8,
              children: [
                ...tapuPins.imageUrls.asMap().entries.take(4).map((entry) {
                  final idx = entry.key;
                  final url = entry.value;
                  // If this is the 4th image and there are more images, overlay the number
                  if (idx == 3 && tapuPins.imageUrls.length > 4) {
                    double imageSize = MediaQuery.of(context).size.width * 0.18;
                    return Container(
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
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
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
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: Center(
                                child: Text(
                                  '${tapuPins.imageUrls.length - 3}+',
                                  style: GoogleFonts.nunitoSans(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.035,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return _buildPreviewImage(url, context);
                  }
                }).toList(),
              ],
            ),
            const SizedBox(height: 16.0),

            // Views and Plays Count
            Row(
              mainAxisAlignment: MainAxisAlignment.end, // Align to the right
              children: [
                Text(
                  '${tapuPins.viewsCount} Views',
                  style: GoogleFonts.nunitoSans(
                      color: AppColors.bgGroundYellow,
                      fontSize: width * 0.03,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 16.0),
                Text(
                  '${tapuPins.playsCount} Plays',
                  style: GoogleFonts.nunitoSans(
                      color: AppColors.bgGroundYellow,
                      fontSize: width * 0.03,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildPreviewImage(String imageUrl, BuildContext context) {
    double imageSizeWidth = MediaQuery.of(context).size.width * 0.18;
    double imageSizeHeight = MediaQuery.of(context).size.width * 0.18;

    return Container(
      decoration: BoxDecoration(
          borderRadius: UI.borderRadius8,
          border: Border.all(width: 1, color: Colors.white.withOpacity(0.5))),
      child: ClipRRect(
        borderRadius: UI.borderRadius8,
        child: Image.network(
          imageUrl,
          height: imageSizeHeight,
          width: imageSizeWidth,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: imageSizeHeight,
            width: imageSizeWidth,
            color: Colors.grey[700],
            child: const Icon(Icons.image, color: Colors.white54, size: 30),
          ),
        ),
      ),
    );
  }

}