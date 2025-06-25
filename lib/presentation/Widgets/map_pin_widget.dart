import 'package:flutter/material.dart';
import 'package:memory_pins_app/models/pin.dart'; // Make sure this path is correct

class MapPinWidget extends StatelessWidget {
  final Pin pin;
  final Function(Pin)? onTap; // Callback for when the pin is tapped

  const MapPinWidget({
    Key? key,
    required this.pin,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // IMPORTANT: These values (left, top) are still dummy values based on
      // the screenshot's approximate layout. In a real map integration
      // (e.g., with Maps_flutter or flutter_map), these values would be
      // calculated dynamically using the map's controller and projection
      // from the pin's actual latitude and longitude.
      left: pin.latitude, // Using latitude for left for dummy positioning
      top: pin.longitude, // Using longitude for top for dummy positioning
      child: GestureDetector(
        onTap: () => onTap?.call(pin),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none, // Allow children to overflow
              children: [
                // --- Main Circular Pin Image ---
                Container(
                  width: 60, // Size of the circular image
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    // Use Image.network here for the main pin image
                    child: Image.network(
                      pin.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.lightBlueAccent, // Loading indicator color
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // This is crucial: display an error icon if image fails
                        print('Error loading pin image: ${pin.imageUrl} - $error');
                        return const Icon(Icons.location_off, color: Colors.red, size: 40); // Visual error
                      },
                    ),
                  ),
                ),
                // --- Mood Icon/Emoji ---
                Positioned(
                  bottom: -5, // Position relative to the main pin image
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: ClipOval(
                      // Use Image.network here for the mood icon
                      child: Image.network(
                        pin.moodIconUrl,
                        width: 18,
                        height: 18,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.blueAccent),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Crucial: display a broken image icon or a fallback emoji
                          print('Error loading mood icon: ${pin.moodIconUrl} - $error');
                          return const Icon(Icons.sentiment_dissatisfied, color: Colors.orange, size: 18); // Fallback emoji icon
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // --- Small Dot Indicator ---
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.greenAccent[400],
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}