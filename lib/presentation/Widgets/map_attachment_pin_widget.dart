// lib/presentation/Widgets/map_attachment_pin_widget.dart

import 'package:flutter/material.dart';

import 'package:memory_pins_app/models/tapuattachment.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';

class MapAttachmentPinWidget extends StatelessWidget {
  final TapuAttachment attachment;
  final VoidCallback? onTap;

  const MapAttachmentPinWidget(
      {super.key, required this.attachment, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 70,
               // Adjust size as per screenshot
              height: 70, // Adjust size as per screenshot
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                
                border: Border.all(color: Colors.white
                .withOpacity(0.5), width: 1),
               
                image: DecorationImage(
                  image: NetworkImage(attachment.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Inside your MapAttachmentPinWidget build method, replacing the existing 'if (attachment.profileImageUrlPin != null)' block:

            if (attachment.profileImageUrlPin != null &&
                attachment.profileImageUrlPin!.isNotEmpty)
              Positioned(
                bottom: 0, // Adjust to position the profile image
                right: 0, // Adjust to position the profile image
                child: Container(
                   // Define a size for the profile image
                  decoration: BoxDecoration(
                    color: Colors.white, // Background color for the circle
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black.withOpacity(0.2), width: 1),
                    // Use DecorationImage with NetworkImage to display the profile image
                    
                
                    
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(Images.redPinIcon, height: 20, fit: BoxFit.contain,),
                  ),
                  // No child Text widget here, as we are displaying an image
                ),
              ),
          ],
        ),
        // You might add the distance text below the pin if needed, similar to screenshot
        // Text('3KM', style: TextStyle(color: Colors.black, fontSize: 10)),
      ],
    );
  }
}
