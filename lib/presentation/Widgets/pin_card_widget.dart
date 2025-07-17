// widgets/pin_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/models/pin_item.dart';
import 'package:memory_pins_app/models/pin_detail.dart';
import 'package:memory_pins_app/presentation/Pages/pin_detail_screen.dart';
import 'package:memory_pins_app/presentation/Widgets/pin_detail_popup.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:memory_pins_app/utills/Constants/ui.dart';
import 'package:provider/provider.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';

class PinCard extends StatelessWidget {
  final PinItem pin; // The dynamic data for this card
  final Pin? originalPin; // Add original pin for navigation

  const PinCard({
    Key? key,
    required this.pin,
    this.originalPin, // Make it optional for backward compatibility
  }) : super(key: key);

  // Convert Pin to PinDetail for navigation (same as SavedPinCard)
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
    print('Showing pin detail popup for: ${pin.title}');

    if (originalPin != null) {
      final pinDetail = _convertPinToPinDetail(originalPin!);
      showPinDetailPopup(context, pinDetail, originalPin: originalPin);
    }
  }

  // Handle send icon tap - same as SavedPinCard
  void _handleSendTap(BuildContext context) {
    print('Send icon tapped!');
    _navigateToPinDetail(context);
  }

  // Handle delete pin
  void _handleDeletePin(BuildContext context) async {
    if (originalPin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot delete pin: Pin data not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF253743),
          title: Text(
            'Delete Pin',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Are you sure you want to delete "${originalPin!.title}"? This action cannot be undone.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        final pinProvider = Provider.of<PinProvider>(context, listen: false);
        final success = await pinProvider.deletePin(originalPin!.id);

        // Check if context is still mounted before showing snackbar
        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pin deleted successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete pin'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        // Check if context is still mounted before showing snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting pin: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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
      child: Padding(
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
                            pin.location,
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
                      ]),
                ),

                GestureDetector(
                  onTap: () => _handleSendTap(context),
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
                    pin.title,
                    style: text18W700White(context),
                  ),
                ),
                SizedBox(
                  width: 4,
                ),
                if (pin.emoji != null)
                  Image.network(
                    pin.emoji!,
                    height: 20,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 20,
                      width: 20,
                      color: Colors.grey[700],
                      child: const Icon(Icons.emoji_emotions,
                          color: Colors.white54, size: 16),
                    ),
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
                  // If this is the 4th image and there are more images, overlay the number
                  if (idx == 3 && pin.imageUrls.length > 4) {
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
                              errorBuilder: (context, error, stackTrace) {
                                // Suppress console errors for network image failures
                                return Container(
                                  height: imageSize,
                                  width: imageSize,
                                  color: Colors.grey[700],
                                  child: const Icon(Icons.image,
                                      color: Colors.white54, size: 30),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: imageSize,
                                  width: imageSize,
                                  color: Colors.grey[800],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white54),
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              height: imageSize,
                              width: imageSize,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: Center(
                                child: Text(
                                  '${pin.imageUrls.length - 3}+',
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => _handleDeletePin(context),
                  child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.bgGroundYellow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 20,
                        ),
                      )),
                ),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.end, // Align to the right
                  children: [
                    Text(
                      '${pin.viewsCount} Views',
                      style: GoogleFonts.nunitoSans(
                          color: AppColors.bgGroundYellow,
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 16.0),
                    Text(
                      '${pin.playsCount} Plays',
                      style: GoogleFonts.nunitoSans(
                          color: AppColors.bgGroundYellow,
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            )

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
          errorBuilder: (context, error, stackTrace) {
            // Suppress console errors for network image failures
            return Container(
              height: imageSizeHeight,
              width: imageSizeWidth,
              color: Colors.grey[700],
              child: const Icon(Icons.image, color: Colors.white54, size: 30),
            );
          },
          // Add loadingBuilder to handle loading states gracefully
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: imageSizeHeight,
              width: imageSizeWidth,
              color: Colors.grey[800],
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMoreImagesOverlay(int remaining, BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.18,
      height: MediaQuery.of(context).size.width * 0.18,
      decoration: BoxDecoration(
          borderRadius: UI.borderRadius8,
          border: Border.all(width: 1, color: Colors.white.withOpacity(0.5))),
      child: Center(
        child: Text(
          '$remaining+',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
