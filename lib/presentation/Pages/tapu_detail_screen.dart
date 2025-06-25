import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/models/tapu.dart'; // Ensure this is the correct Tapu model
import 'package:memory_pins_app/models/map_coordinates.dart';
import 'package:memory_pins_app/models/tapuattachment.dart';
import 'package:memory_pins_app/models/tapus.dart'; // You seem to be using Tapus here too, ensure consistency
import 'package:memory_pins_app/presentation/Widgets/dotted_circular_painter.dart'; // Corrected import from previous `dotted_circle_painter.dart`
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/presentation/Widgets/map_attachment_pin_widget.dart';

import 'dart:math';

import 'package:memory_pins_app/utills/Constants/label_text_style.dart';

// Correcting the Tapu type if `widget.tapu` is truly `Tapus`
// If Tapus is a list/collection of Tapu, then adjust accordingly.
// For now, assuming Tapus is your main model that has `id`, `name`, `avatarUrl`, `centerPinImageUrl`, `totalPins`.
// If not, you might have a type mismatch in your `main.dart` or previous screen.
class TapuDetailScreen extends StatefulWidget {
  final Tapus tapu; // Changed from Tapu to Tapus as per your code

  const TapuDetailScreen({super.key, required this.tapu});

  @override
  State<TapuDetailScreen> createState() => _TapuDetailScreenState();
}

class _TapuDetailScreenState extends State<TapuDetailScreen> {
  List<TapuAttachment> _attachments = [];
  TapuAttachment? _selectedAttachmentForCard;

  static const double _kmToPixels = 60.0;
  static const double _pinSize = 60.0;
  static const double _centerPinSize = 80.0;
  static const List<double> _distanceCircleRadiiKm = [1.5, 2.5, 4.0];

  @override
  void initState() {
    super.initState();
    _attachments = _getDummyAttachmentsForTapu(widget.tapu.id);

    if (_attachments.isNotEmpty) {
      _selectedAttachmentForCard = _attachments.first;
    }
  }

  // Dummy data (adjusted for consistency with previous changes)
  List<TapuAttachment> _getDummyAttachmentsForTapu(String tapuId) {
    if (tapuId == 'johns_tapu') {
      // Assuming 'johns_tapu' is the ID you're passing
      return [
        TapuAttachment(
          id: 'attachment_sunset_goodbye',
          tapuId: 'johns_tapu',
          title: 'Sunset Goodbye',
          emoji: Images.dancingImg,
          imageUrl: Images.aeroplaneImg,
          coordinates:
              MapCoordinates(latitude: -2.0, longitude: -0.8), // Adjusted
          attachmentCount: 4,
          audioCount: 2,
          previewImageUrls: [
            Images.riverImg,
            Images.manWithRiver,
            Images.umbrellaImg,
            Images.childUmbrella,
            Images.riverImg,

          ],
          viewsCount: 34,
          profileImageUrlPin: Images.redPinIcon
        ),
        TapuAttachment(
          id: 'attachment_river_path',
          tapuId: 'johns_tapu',
          title: 'River Path',
          emoji: Images.confusionImg,
          imageUrl: Images.aeroplaneImg,
          coordinates:
              MapCoordinates(latitude: 0.4, longitude: 1.8), // Adjusted
          attachmentCount: 2,
          audioCount: 1,
          previewImageUrls: [Images.riverImg, Images.manWithRiver],
          viewsCount: 15,
        ),
        TapuAttachment(
          id: 'attachment_mountain_view',
          tapuId: 'johns_tapu',
          title: 'Mountain View',
          emoji: Images.dancingImg,
          imageUrl: Images.aeroplaneImg,
          coordinates:
              MapCoordinates(latitude: 3.5, longitude: 1.5), // Adjusted
          attachmentCount: 3,
          audioCount: 0,
          previewImageUrls: [
            Images.riverImg,
            Images.umbrellaImg,
            Images.childUmbrella
          ],
          viewsCount: 22,
          profileImageUrlPin: Images.redPinIcon
        ),
        TapuAttachment(
          id: 'attachment_smiley_place',
          tapuId: 'johns_tapu',
          title: 'Happy Place',
          emoji: Images.addIcon,
          imageUrl: Images.umbrellaImg,
          coordinates:
              MapCoordinates(latitude: 3.5, longitude: -1.5), // Adjusted
          attachmentCount: 1,
          audioCount: 1,
          previewImageUrls: [Images.childUmbrella],
          viewsCount: 10,
          profileImageUrlPin: Images.redPinIcon
        ),
      ];
    }
    return [];
  }

  double _getLeftPosition(MapCoordinates coords, Size screenSize) {
    return screenSize.width / 2 + (coords.longitude * _kmToPixels);
  }

  double _getTopPosition(MapCoordinates coords, Size screenSize) {
    return (screenSize.height / 2) + (coords.latitude * _kmToPixels);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final Offset mapCenter =
        Offset(screenSize.width / 2, screenSize.height / 2);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // --- Map Background Placeholder ---
          Positioned.fill(
            child: Image.network(
              Images.homeScreenBgImg,
              fit: BoxFit.cover,
              repeat: ImageRepeat.repeat,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
              ),
            ),
          ),

          // --- Dotted Distance Circles ---
          ..._distanceCircleRadiiKm.map((kmRadius) {
            return Positioned.fill(
              child: CustomPaint(
                painter: DottedCirclePainter(
                  // Renamed to DottedCirclePainter to match common Flutter naming
                  center: mapCenter,
                  radius: kmRadius * _kmToPixels,
                  dashLength: 8,
                  gapLength: 8,
                  strokeWidth: 1.5,
                  color: Colors.grey[400]!,
                ),
              ),
            );
          }).toList(),

          // --- Central Pin ---
          Positioned(
            left: mapCenter.dx - (_centerPinSize / 2),
            top: mapCenter.dy - (_centerPinSize / 2),
            child: GestureDetector(
              onTap: () {
                NavigationService.pushNamed('/pin-detail');
                setState(() {
                  _selectedAttachmentForCard = null;
                });
              },
              child: Container(
                width: _centerPinSize,
                height: _centerPinSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  image: DecorationImage(
                    image: NetworkImage(widget.tapu.centerPinImageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),

          // --- Dynamic Attachment Pins and Lines ---
          // Iterate through attachments to create each pin and its connecting line
          ..._attachments.map((attachment) {
            final double attachmentLeft =
                _getLeftPosition(attachment.coordinates, screenSize) -
                    (_pinSize / 2);
            final double attachmentTop =
                _getTopPosition(attachment.coordinates, screenSize) -
                    (_pinSize / 2);
            final Offset attachmentCenter = Offset(
                attachmentLeft + (_pinSize / 2),
                attachmentTop + (_pinSize / 2));

            return Stack(
              key: ValueKey(attachment.id), // Important for lists of widgets
              children: [
                // Line connecting central pin to attachment pin
                // This CustomPaint should NOT have a child: Container and should be Positioned.fill to draw on the whole stack.
                // We are removing the blocking container.
                Positioned.fill(
                  child: CustomPaint(
                    painter: LinePainter(
                      start: mapCenter,
                      end:
                          attachmentCenter, // Use the calculated center of the pin
                      color: Colors.grey[400]!,
                      strokeWidth: 2.0,
                    ),
                    // !!! VERY IMPORTANT: REMOVE THE 'child: Container(...)' HERE !!!
                    // It was blocking taps. CustomPaint does not need a child to draw.
                  ),
                ),
                // The attachment pin itself
                Positioned(
                  left: attachmentLeft,
                  top: attachmentTop,
                  child: MapAttachmentPinWidget(
                    attachment: attachment,
                    onTap: () {
                      NavigationService.pushNamed('/pin-detail');

                        // This onTap will now be received by MapAttachmentPinWidget's internal GestureDetector
                        print('Tapped on attachment: ${attachment.title}');
                      setState(() {
                        _selectedAttachmentForCard = attachment;
                      });
                    },
                  ),
                ),
              ],
            );
          }).toList(),

          // --- Distance Labels ---
          Positioned(
            left: _getLeftPosition(
                    MapCoordinates(latitude: -1.5, longitude: -0.3),
                    screenSize) +
                10,
            top: _getTopPosition(
                    MapCoordinates(latitude: -1.5, longitude: -0.3),
                    screenSize) -
                30,
            child: _buildDistanceLabel('1.5KM'),
          ),
          Positioned(
            left: _getLeftPosition(
                    MapCoordinates(latitude: 0.4, longitude: 2.0), screenSize) +
                50,
            top: _getTopPosition(
                    MapCoordinates(latitude: 0.4, longitude: 2.0), screenSize) -
                10,
            child: _buildDistanceLabel('2.5KM'),
          ),
          Positioned(
            left: _getLeftPosition(
                    MapCoordinates(latitude: 4.0, longitude: -0.5),
                    screenSize) -
                30,
            top: _getTopPosition(MapCoordinates(latitude: 4.0, longitude: -0.5),
                    screenSize) +
                10,
            child: _buildDistanceLabel('4.0KM'),
          ),

          // --- Top Bar (Custom AppBar) ---
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                       color: Color(0xFF253743),
                       borderRadius: BorderRadius.circular(8),
                        
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF0F172A).withOpacity(0.5),
                          border: Border.all(color: Color(0xFF0F172A).withOpacity(0.06)),
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            // BoxShadow(
                            //   blurRadius: 8,
                            //   offset: Offset(2, 12),
                            //   color: Color(0xFF0F172A).withOpacity(0.24),
                            //   spreadRadius: 0,
                            // )
                          ]
                        ),
                        child: Text(
                          widget.tapu.name,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      NavigationService.pushNamed('/profile');
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(widget.tapu.avatarUrl),
                      onBackgroundImageError: (exception, stackTrace) {
                        print('Error loading avatar image: $exception');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- Bottom Detail Card ---
          if (_selectedAttachmentForCard != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildDetailCard(_selectedAttachmentForCard!),
            ),
        ],
      ),
    );
  }

  Widget _buildDistanceLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[700]?.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailCard(TapuAttachment attachment) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.symmetric(),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F24),
       borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.tapu.name,
                style: text16W700White(context),
              ),
              Row(
                children: [
                  Image.asset(
                    Images.locationRedIcon,
                    width: 16,
                    height: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.tapu.totalPins} Pins',
                    style: text16W700White(context),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(

            decoration:BoxDecoration(
              color: Color(0xFF253743),
              borderRadius: BorderRadius.circular(16),
            ),

            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              
                children: [
              
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Flexible(
                    child: Row(children: [
                  Image.asset(
                    Images.locationRedIcon,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                  Text(
                    '"${attachment.title}"',
                    style: text18W700White(context),
                  ),
                  if (attachment.emoji != null) ...[
                    const SizedBox(width: 8),
                    Image.network(
                      attachment.emoji!,
                     fit: BoxFit.contain,
                     height: 20,
                    ),
                  ],
                ])),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor1),
                    color: AppColors.bgGroundYellow,
                    boxShadow: [
                      AppColors.backShadow,
                    ],
                    shape: BoxShape.circle,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      NavigationService.pushNamed('/pin-detail');
                    },
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
              ]),
                        
                        const SizedBox(height: 8),
                        Row(
              children: [
                Image.asset(
                  Images.photolibrary,
                  height: 20,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '${attachment.attachmentCount} Attachments',
                  style: text14W500White(context),
                ),
                const SizedBox(width: 16.0),
                Image.asset(
                  Images.audioIcon,
                  height: 20,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '${attachment.audioCount} Audios',
                  style: text14W500White(context),
                ),
              ],
                        ),
                        const SizedBox(height: 8),
                        Text(
              '${attachment.viewsCount} Views',
              style: text12W700Yellow(context),
                        ),
              
                        SizedBox(height: 16,),
                        
                        Row(
                          spacing: 8,
                children: attachment.previewImageUrls.asMap().entries.take(4).map((entry) {
                  final idx = entry.key;
                  final url = entry.value;
                  final hasMore = attachment.previewImageUrls.length > 4;
                  final isLastShown = idx == 3 && hasMore;
              
                  double imageSize = MediaQuery.of(context).size.width * 0.18;
              
                  return Container(
                   
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(width: 1, color: Colors.white.withOpacity(0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Stack(
                        children: [
              Image.network(
                url,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: imageSize,
                  height: imageSize,
                  color: Colors.grey[700],
                  child: const Icon(Icons.image, color: Colors.white54, size: 30),
                ),
              ),
              if (isLastShown)
                Container(
                  width: imageSize,
                  height: imageSize,
                  color: Colors.black.withOpacity(0.5),
                  child: Center(
                    child: Text(
                      '+${attachment.previewImageUrls.length - 3}',
                      style: GoogleFonts.nunitoSans(
                        color: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
                  
                ],
              ),
            )
          ),
             

        ],
      ),
    );
  }
}

// --- LinePainter Class (remains the same) ---
class LinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double strokeWidth;

  LinePainter({
    required this.start,
    required this.end,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return (oldDelegate as LinePainter).start != start ||
        (oldDelegate as LinePainter).end != end;
  }
}


// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:memory_pins_app/models/tapu.dart';

// import 'package:memory_pins_app/models/map_coordinates.dart';
// import 'package:memory_pins_app/models/tapuattachment.dart';
// import 'package:memory_pins_app/models/tapus.dart';
// import 'package:memory_pins_app/presentation/Widgets/dotted_circular_painter.dart';
// import 'package:memory_pins_app/utills/Constants/images.dart';
// import 'package:memory_pins_app/presentation/Widgets/map_attachment_pin_widget.dart';

// import 'dart:math';

// // (Ensure your Tapu, TapuAttachment, MapCoordinates models are defined correctly and imported from their respective model files)

// class TapuDetailScreen extends StatefulWidget {
//   final Tapus tapu;

//   const TapuDetailScreen({super.key, required this.tapu});

//   @override
//   State<TapuDetailScreen> createState() => _TapuDetailScreenState();
// }

// class _TapuDetailScreenState extends State<TapuDetailScreen> {
//   List<TapuAttachment> _attachments = [];
//   TapuAttachment? _selectedAttachmentForCard;

//   // --- ADJUSTED SCALING FACTOR AND RADII ---
//   // Reduce this value to make circles and lines shorter
//   static const double _kmToPixels = 60.0; // Changed from 100.0 to 60.0
//   static const double _pinSize = 60.0;
//   static const double _centerPinSize = 80.0;

//   // Radii for the dotted circles in KMs, based on your screenshot.
//   // Slightly adjusted if they were too large even with the new _kmToPixels.
//   static const List<double> _distanceCircleRadiiKm = [1.5, 2.5, 4.0]; // Adjusted values

//   @override
//   void initState() {
//     super.initState();
//     _attachments = _getDummyAttachmentsForTapu(widget.tapu.id);

//     if (_attachments.isNotEmpty) {
//       _selectedAttachmentForCard = _attachments.first;
//     }
//   }

//   // Dummy data provider for attachments based on Tapu ID
//   // ADJUSTED COORDINATES TO BE CLOSER TO THE CENTER
//   List<TapuAttachment> _getDummyAttachmentsForTapu(String tapuId) {
//     if (tapuId == 'johns_tapu') {
//       return [
//         TapuAttachment(
//           id: 'attachment_sunset_goodbye',
//           tapuId: 'johns_tapu',
//           title: 'Sunset Goodbye',
//           emoji: '😊',
//           imageUrl: Images.aeroplaneImg, // Top-left pin in screenshot
//           // Approx. 3KM from center, top-left direction
//           coordinates: MapCoordinates(latitude: -3.0, longitude: -1.0), // Use KM values, not 0-1 normalized
//           attachmentCount: 4,
//           audioCount: 2,
//           previewImageUrls: [
//             Images.riverImg, Images.manWithRiver, Images.umbrellaImg,
//             Images.childUmbrella, Images.riverImg, // 5+ for this one
//           ],
//           viewsCount: 34,
//         ),
//         TapuAttachment(
//           id: 'attachment_river_path',
//           tapuId: 'johns_tapu',
//           title: 'River Path',
//           emoji: '🏞',
//           imageUrl: Images.aeroplaneImg, // Right-middle pin in screenshot
//           // Approx. 2KM from center, right direction
//           coordinates: MapCoordinates(latitude: 0.5, longitude: 2.0), // Use KM values
//           attachmentCount: 2,
//           audioCount: 1,
//           previewImageUrls: [
//             Images.riverImg, Images.manWithRiver
//           ],
//           viewsCount: 15,
//         ),
//         TapuAttachment(
//           id: 'attachment_mountain_view',
//           tapuId: 'johns_tapu',
//           title: 'Mountain View',
//           emoji: '⛰',
//           imageUrl: Images.aeroplaneImg, // Bottom-right pin in screenshot
//           // Approx. 4.5KM from center, bottom-right direction
//           coordinates: MapCoordinates(latitude: 4.0, longitude: 2.0), // Use KM values
//           attachmentCount: 3,
//           audioCount: 0,
//           previewImageUrls: [
//             Images.riverImg, Images.umbrellaImg, Images.childUmbrella
//           ],
//           viewsCount: 22,
//         ),
//         TapuAttachment(
//           id: 'attachment_smiley_place',
//           tapuId: 'johns_tapu',
//           title: 'Happy Place',
//           emoji: '😁',
//           imageUrl: Images.umbrellaImg, // Bottom-left pin in screenshot
//           // Approx. 4.5KM from center, bottom-left direction
//           coordinates: MapCoordinates(latitude: 4.0, longitude: -2.0), // Use KM values
//           attachmentCount: 1,
//           audioCount: 1,
//           previewImageUrls: [
//             Images.childUmbrella
//           ],
//           viewsCount: 10,
//         ),
//       ];
//     }
//     return [];
//   }

//   // Calculate pixel position on screen based on conceptual KM coordinates
//   double _getLeftPosition(MapCoordinates coords, Size screenSize) {
//     return screenSize.width / 2 + (coords.longitude * _kmToPixels);
//   }

//   double _getTopPosition(MapCoordinates coords, Size screenSize) {
//     // If positive latitude moves pins UP and you want them to go DOWN, use minus:
//     // return (screenSize.height / 2) - (coords.latitude * _kmToPixels);
//     // Otherwise, keep as plus:
//     return (screenSize.height / 2) + (coords.latitude * _kmToPixels);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final Size screenSize = MediaQuery.of(context).size;
//     final Offset mapCenter = Offset(screenSize.width / 2, screenSize.height / 2);

//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       body: Stack(
//         children: [
//           // --- Map Background Placeholder ---
//           Positioned.fill(
//             child: Image.network(
//               Images.homeScreenBgImg,
//               fit: BoxFit.cover,
//               repeat: ImageRepeat.repeat,
//               loadingBuilder: (context, child, loadingProgress) {
//                 if (loadingProgress == null) return child;
//                 return Center(
//                   child: CircularProgressIndicator(
//                     value: loadingProgress.expectedTotalBytes != null
//                         ? loadingProgress.cumulativeBytesLoaded /
//                         loadingProgress.expectedTotalBytes!
//                         : null,
//                   ),
//                 );
//               },
//               errorBuilder: (context, error, stackTrace) => const Center(
//                 child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
//               ),
//             ),
//           ),

//           // --- Dotted Distance Circles ---
//           ..._distanceCircleRadiiKm.map((kmRadius) {
//             return Positioned.fill(
//               child: CustomPaint(
//                 painter: DottedCirclePainter(
//                   center: mapCenter,
//                   radius: kmRadius * _kmToPixels, // Convert KM to pixels for radius
//                   dashLength: 8,
//                   gapLength: 8,
//                   strokeWidth: 1.5,
//                   color: Colors.grey[400]!,
//                 ),
//               ),
//             );
//           }).toList(),

//           // --- Central Pin ---
//           Positioned(
//             left: mapCenter.dx - (_centerPinSize / 2),
//             top: mapCenter.dy - (_centerPinSize / 2),
//             child: GestureDetector(
//               onTap: () {
//                 setState(() {
//                   _selectedAttachmentForCard = null;
//                 });
//               },
//               child: Container(
//                 width: _centerPinSize,
//                 height: _centerPinSize,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 2),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.3),
//                       blurRadius: 5,
//                       offset: const Offset(0, 3),
//                     ),
//                   ],
//                   image: DecorationImage(
//                     image: NetworkImage(widget.tapu.centerPinImageUrl),
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//               ),
//             ),
//           ),

//           // --- Dynamic Attachment Pins and Lines ---
//           ..._attachments.map((attachment) {
//             final double attachmentLeft = _getLeftPosition(attachment.coordinates, screenSize) - (_pinSize / 2);
//             final double attachmentTop = _getTopPosition(attachment.coordinates, screenSize) - (_pinSize / 2);

//             return Stack(
//               children: [
//                 // Line connecting central pin to attachment pin
//                 Positioned(
//                   left: 0,
//                   top: 0,
//                   child: CustomPaint(
//                     painter: LinePainter(
//                       start: mapCenter,
//                       end: Offset(attachmentLeft + (_pinSize / 2), attachmentTop + (_pinSize / 2)),
//                       color: Colors.grey[400]!,
//                       strokeWidth: 2.0,
//                     ),
//                     child: Container(
//                       width: screenSize.width,
//                       height: screenSize.height,
//                     ),
//                   ),
//                 ),
//                 // The attachment pin itself
//                 Positioned(
//                   left: attachmentLeft,
//                   top: attachmentTop,
//                   child: MapAttachmentPinWidget(
//                     attachment: attachment,
//                     onTap: () {
//                       setState(() {
//                         print('Tapped on attachment: ${attachment.title}');
//                         _selectedAttachmentForCard = attachment;
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             );
//           }).toList(),

//           // --- Distance Labels ---
//           // Adjust these positions based on the new _kmToPixels and _distanceCircleRadiiKm
//           // and visual inspection. These are approximate for now.
//           Positioned(
//             left: _getLeftPosition(MapCoordinates(latitude: -1.5, longitude: -0.3), screenSize) + 10,
//             top: _getTopPosition(MapCoordinates(latitude: -1.5, longitude: -0.3), screenSize) - 30,
//             child: _buildDistanceLabel('1.5KM'), // Adjusted label to match new circle radius
//           ),
//           Positioned(
//             left: _getLeftPosition(MapCoordinates(latitude: 0.4, longitude: 2.0), screenSize) + 50,
//             top: _getTopPosition(MapCoordinates(latitude: 0.4, longitude: 2.0), screenSize) - 10,
//             child: _buildDistanceLabel('2.5KM'), // Adjusted label
//           ),
//           Positioned(
//             left: _getLeftPosition(MapCoordinates(latitude: 4.0, longitude: -0.5), screenSize) - 30,
//             top: _getTopPosition(MapCoordinates(latitude: 4.0, longitude: -0.5), screenSize) + 10,
//             child: _buildDistanceLabel('4.0KM'), // Adjusted label
//           ),

//           // --- Top Bar (Custom AppBar) ---
//           Positioned(
//             top: 60,
//             left: 0,
//             right: 0,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   GestureDetector(
//                     onTap: () {
//                       Navigator.pop(context);
//                     },
//                     child: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[700]?.withOpacity(0.8),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
//                     ),
//                   ),
//                   Expanded(
//                     child: Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 16),
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 20,
//                         vertical: 10,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[700]?.withOpacity(0.8),
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       child: Text(
//                         widget.tapu.name,
//                         textAlign: TextAlign.center,
//                         style: GoogleFonts.inter(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),
//                   CircleAvatar(
//                     radius: 20,
//                     backgroundImage: NetworkImage(widget.tapu.avatarUrl),
//                     onBackgroundImageError: (exception, stackTrace) {
//                       print('Error loading avatar image: $exception');
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),

//           // --- Bottom Detail Card ---
//           if (_selectedAttachmentForCard != null)
//             Align(
//               alignment: Alignment.bottomCenter,
//               child: _buildDetailCard(_selectedAttachmentForCard!),
//             ),
//         ],
//       ),
//     );
//   }

//   // (The rest of your helper methods: _buildDistanceLabel, _buildInfoChip, _buildDetailCard remain the same)
//   // ...

//   Widget _buildDistanceLabel(String text) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.grey[700]?.withOpacity(0.8),
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Text(
//         text,
//         style: GoogleFonts.inter(
//           color: Colors.white,
//           fontSize: 12,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoChip(IconData icon, String text) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, color: Colors.grey[400], size: 16),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: GoogleFonts.inter(
//             color: Colors.grey[400],
//             fontSize: 14,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildDetailCard(TapuAttachment attachment) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFF1D1F24),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.5),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 widget.tapu.name,
//                 style: GoogleFonts.inter(
//                   color: Colors.white,
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Row(
//                 children: [
//                   Image.asset(
//                     'assets/icons/pin_icon.png',
//                     width: 16,
//                     height: 16,
//                     color: Colors.white,
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     '${widget.tapu.totalPins} Pins',
//                     style: GoogleFonts.inter(
//                       color: Colors.white,
//                       fontSize: 16,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Image.asset(
//                 'assets/icons/red_pin_icon.png',
//                 width: 18,
//                 height: 18,
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Text(
//                           '"${attachment.title}"',
//                           style: GoogleFonts.inter(
//                             color: Colors.white,
//                             fontSize: 17,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         if (attachment.emoji != null) ...[
//                           const SizedBox(width: 8),
//                           Text(
//                             attachment.emoji!,
//                             style: const TextStyle(fontSize: 20),
//                           ),
//                         ],
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Wrap(
//                       spacing: 12.0,
//                       runSpacing: 4.0,
//                       children: [
//                         _buildInfoChip(
//                           Icons.image,
//                           '${attachment.attachmentCount} Attachments',
//                         ),
//                         _buildInfoChip(
//                           Icons.mic_none,
//                           '${attachment.audioCount} Audios',
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${attachment.viewsCount} Views',
//                       style: GoogleFonts.inter(
//                         color: Colors.white70,
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFFF5BF4D),
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 child: const Icon(Icons.send, color: Colors.white),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           SizedBox(
//             height: 70,
//             child: ListView.builder(
//               scrollDirection: Axis.horizontal,
//               itemCount: attachment.previewImageUrls.length,
//               itemBuilder: (context, index) {
//                 final imageUrl = attachment.previewImageUrls[index];
//                 final isLast = index == attachment.previewImageUrls.length - 1;

//                 if (isLast && attachment.previewImageUrls.length > 4) {
//                    return Container(
//                     margin: const EdgeInsets.only(right: 8),
//                     width: 70,
//                     height: 70,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(10),
//                       image: DecorationImage(
//                         image: NetworkImage(imageUrl),
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                     child: Center(
//                       child: Text(
//                         '${attachment.previewImageUrls.length - 4}+',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           backgroundColor: Colors.black54,
//                         ),
//                       ),
//                     ),
//                   );
//                 }

//                 return Container(
//                   margin: const EdgeInsets.only(right: 8),
//                   width: 70,
//                   height: 70,
//                   decoration: BoxDecoration(
//                     borderRadius: BorderRadius.circular(10),
//                     image: DecorationImage(
//                       image: NetworkImage(imageUrl),
//                       fit: BoxFit.cover,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // --- LinePainter Class ---
// // This should still be here, either at the end of this file or in its own file
// class LinePainter extends CustomPainter {
//   final Offset start;
//   final Offset end;
//   final Color color;
//   final double strokeWidth;

//   LinePainter({
//     required this.start,
//     required this.end,
//     required this.color,
//     required this.strokeWidth,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = color
//       ..strokeWidth = strokeWidth
//       ..strokeCap = StrokeCap.round;

//     canvas.drawLine(start, end, paint);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return (oldDelegate as LinePainter).start != start ||
//         (oldDelegate as LinePainter).end != end;
//   }
// }