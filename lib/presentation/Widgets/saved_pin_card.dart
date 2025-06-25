import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/saved_pin_item.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:memory_pins_app/utills/Constants/ui.dart';

class SavedPinCard extends StatelessWidget {
  final SavedPinItem pins;
  const SavedPinCard({super.key, required this.pins});

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
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                
                children: [
            
                  Image.network(
                    Images.mapMarketImg,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
            
                  SizedBox(
                    width: 4,
                  ),
                  Flexible(
                    child: Text(
                      pins.location,
                      style: text14W400White(context),
                    ),
                  ),
                  
                  
                ]
              ),
            ),

            SizedBox(height: 16),

            Column(

              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
              children: [
                Image.asset(
                  Images.locationRedIcon,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                Flexible(
                  child: Text(
                    "\"${pins.title}\"",
                    style: text18W700White(context),
                  ),
                ),
                SizedBox(
                  width: 4,
                ),
                if (pins.emoji != null)
                  Image.network(
                    pins.emoji!,
                    height: 20,
                    fit: BoxFit.contain,
                  )
              ],
            ),
           

            // Photos and Audios Count
            Row(
              children: [
                Image.asset(
                  Images.photolibrary,
                  height: 20,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '${pins.photoCount} Attachments',
                  style: text14W500White(context),
                ),
                const SizedBox(width: 16.0),
                Image.asset(
                  Images.audioIcon,
                  height: 20,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '${pins.audioCount} Audios',
                  style: text14W500White(context),
                ),
              ],
            ),
           

            Row(
              mainAxisAlignment: MainAxisAlignment.start, // Align to the right
              children: [
                Text(
                  '${pins.viewsCount} Views',
                  style: GoogleFonts.nunitoSans(
                      color: AppColors.bgGroundYellow,
                      fontSize: width * 0.03,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 16.0),
                Text(
                  '${pins.playsCount} Plays',
                  style: GoogleFonts.nunitoSans(
                      color: AppColors.bgGroundYellow,
                      fontSize: width * 0.03,
                      fontWeight: FontWeight.w700),
                ),
              ],
            ),

            // Image Previews
            Row(
              spacing: 8,
              children: [
                ...pins.imageUrls.asMap().entries.take(4).map((entry) {
                  final idx = entry.key;
                  final url = entry.value;
                  // If this is the 4th image and there are more images, overlay the number
                  if (idx == 3 && pins.imageUrls.length > 4) {
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
                                  '${pins.imageUrls.length - 3}+',
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
            


              ]
            ),

            // Pin Title and Emoji
            

            // Views and Plays Count
            
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