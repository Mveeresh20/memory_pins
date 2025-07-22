import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/saved_pin_item.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/models/pin_detail.dart';
import 'package:memory_pins_app/presentation/Pages/pin_detail_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/pin_detail_popup.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:memory_pins_app/utills/Constants/ui.dart';
import 'package:memory_pins_app/utills/Constants/image_picker_util.dart'; // Add this import

class SavedPinCard extends StatelessWidget {
  final SavedPinItem pins;
  final Pin? originalPin; // Add original pin for navigation

  const SavedPinCard({
    super.key,
    required this.pins,
    this.originalPin, // Make it optional for backward compatibility
  });

  // Helper method to convert image filename to full URL
  String _getImageUrl(String filename) {
    final imagePickerUtil = ImagePickerUtil();
    // Use the filename as-is (Firebase stores full path, AWS also stores with "images/" prefix)
    return imagePickerUtil.getUrlForUserUploadedImage(filename);
  }

  // Convert Pin to PinDetail for navigation
  PinDetail _convertPinToPinDetail(Pin pin) {
    // Convert image filenames to full URLs for PhotoItem list
    List<PhotoItem> photos = pin.imageUrls.map((filename) {
      final fullUrl = _getImageUrl(filename);
      return PhotoItem(imageUrl: fullUrl);
    }).toList();

    // Convert audio URLs to AudioItem list
    List<AudioItem> audios = [];
    for (int i = 0; i < pin.audioUrls.length; i++) {
      audios.add(AudioItem(
        audioUrl: pin.audioUrls[i],
        duration: '${(i + 1) * 2}:${(i + 1) * 10}',
      ));
    }

    // Use the actual description from the pin, with fallback
    String description = (pin.description?.isNotEmpty == true)
        ? pin.description!
        : 'A beautiful memory captured at ${pin.location}. This pin contains ${pin.photoCount} photos and ${pin.audioCount} audio recordings.';

    return PinDetail(
      title: pin.title,
      description: description,
      audios: audios,
      photos: photos,
    );
  }

  void _navigateToPinDetail(BuildContext context) {
    if (originalPin != null) {
      final pinDetail = _convertPinToPinDetail(originalPin!);
      showPinDetailPopup(context, pinDetail, originalPin: originalPin);
    }
  }

  // Handle send icon tap - same as home screen
  void _handleSendTap(BuildContext context) {
    print('Send icon tapped!');
    _navigateToPinDetail(context);
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: () => _navigateToPinDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            Images.trackImage,
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
                        ]),
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
                        onTap: () => _handleSendTap(context),
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
              // Top Row: Location, Flag, Send Icon

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
                            pins.title,
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

                    // Image Previews
                    Row(
                      spacing: 8,
                      children: [
                        ...pins.imageUrls.asMap().entries.take(4).map((entry) {
                          final idx = entry.key;
                          final filename = entry.value;
                          final fullUrl = _getImageUrl(
                              filename); // Convert filename to full URL
                          // If this is the 4th image and there are more images, overlay the number
                          if (idx == 3 && pins.imageUrls.length > 4) {
                            double imageSize =
                                MediaQuery.of(context).size.width * 0.18;
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: UI.borderRadius8,
                                border: Border.all(
                                    width: 1,
                                    color: Colors.white.withOpacity(0.5)),
                              ),
                              child: ClipRRect(
                                borderRadius: UI.borderRadius8,
                                child: Stack(
                                  children: [
                                    Image.network(
                                      fullUrl,
                                      height: imageSize,
                                      width: imageSize,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
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
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width *
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
                            return _buildPreviewImage(fullUrl, context);
                          }
                        }).toList(),
                      ],
                    ),

                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.end, // Align to the right
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
                  ]),

              // Pin Title and Emoji

              // Views and Plays Count
            ],
          ),
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
