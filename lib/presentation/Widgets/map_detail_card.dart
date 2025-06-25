// widgets/map_detail_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/map_cordinates.dart';


import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
// Import your models

class MapDetailCard extends StatelessWidget {
  final MapDetailCardData data;
  final VoidCallback? onClose; // Callback for when the card is closed/minimized

  const MapDetailCard({
    Key? key,
    required this.data,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12.0, top: 8.0),
              height: 4.0,
              width: 48.0,
              decoration: BoxDecoration(
                color: Color(0xFFD4D4D4),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
              decoration: BoxDecoration(
                color: Color(0xFF253743),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16.0)),
              ),
              child: Column(
                spacing: 16,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Distance Row
                  Row(
                    children: [
                      SizedBox(
                        width: 4,
                      ),
                      Image.asset(
                        Images.trackImage,
                        height: 20,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${data.distance} ${data.distanceUnit} From',
                        style: text14W400White(context),
                      ),
                      // Pushes "Goa Drift" to the right
                    ],
                  ),

                 

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
                        data.title,
                        style: text18W700White(context),
                      ),
                    ],
                  ),

                  // Counts Row (Pins, Images, Audios)
                  Row(
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
                      Flexible(
                        child: Text(
                          '${data.pinCount} Pins',
                          style: text14W800Yellow(context),
                        ),
                      ),

                      SizedBox(width: 20,),
                      Image.asset(
                        Images.photolibrary,
                        height: 20,
                      ),
                      const SizedBox(width: 4.0),
                      Flexible(
                        child: Text(
                          '${data.imageCount} Images',
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
                          '${data.audioCount} Audios',
                          style: text14W600White(context),
                        ),
                      ),
                    ],
                  ),

                  // Reaction Emojis (now as images)
                  Wrap(
                    spacing: 8.0, // horizontal space between images
                    runSpacing: 4.0, // vertical space between lines of images
                    children: data.reactionEmojis
                        .map((imgUrl) => Image.network(
                              imgUrl,
                              width: 30,
                              height: 30,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.error, size: 30),
                            ))
                        .toList(),
                  ),
                  

                  // Views Count
                  Text(
                    '${data.viewsCount} Views',
                    style: GoogleFonts.nunitoSans(
                    color: AppColors.bgGroundYellow,
                    fontSize: MediaQuery.of(context).size.width * 0.03,
                    fontWeight: FontWeight.w700
                  )
                  ),
                  SizedBox(height: 8,),
                   // Padding before bottom nav
                ],

                ),

                
         ] ),
            ),
          ),
        ],
      ),
    );
  }
}
