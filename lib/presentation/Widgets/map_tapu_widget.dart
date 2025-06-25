import 'package:flutter/material.dart';
import 'package:memory_pins_app/models/tapu.dart';

class MapTapuWidget extends StatelessWidget {
  final Tapu tapu;
  final Function(Tapu)? onTap;
  const MapTapuWidget({super.key, required this.tapu, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      // IMPORTANT: These values (left, top) are still dummy values based on
      // the screenshot's approximate layout. In a real map integration
      // (e.g., with Maps_flutter or flutter_map), these values would be
      // calculated dynamically using the map's controller and projection
      // from the pin's actual latitude and longitude.
      left: tapu.latitude, // Using latitude for left for dummy positioning
      top: tapu.longitude, // Using longitude for top for dummy positioning
      child: GestureDetector(
        onTap: () => onTap?.call(tapu),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none, // Allow children to overflow
              children: [
                // --- Main Pin Image (now rectangular) ---
                Container(
                  width: 60, // Size of the image
                  height: 60,
                  decoration: BoxDecoration(
                    // Optional: add rounded corners
                   
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black,
                        blurRadius: 33,
                        
                        offset: Offset(0, 4)
                      ),
                    ],
                   
                  ),
                  child: ClipRRect(
                    
                    // Match the container's radius
                    // Use Image.network here for the main pin image
                    child: Image.network(
                      tapu.imageUrl,
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
                            color: Colors
                                .lightBlueAccent, // Loading indicator color
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        // This is crucial: display an error icon if image fails
                        print(
                            'Error loading pin image: ${tapu.imageUrl} - $error');
                        return const Icon(Icons.location_off,
                            color: Colors.red, size: 40); // Visual error
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
                      shape: BoxShape.circle,
                      color: Colors.white,
                       // Square with rounded corners
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: ClipOval(
                     
                      // Use Image.network here for the mood icon
                      child: Image.network(
                        tapu.moodIconUrl,
                        width: 18,
                        height: 18,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: Colors.blueAccent),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Crucial: display a broken image icon or a fallback emoji
                          print(
                              'Error loading mood icon: ${tapu.moodIconUrl} - $error');
                          return const Icon(Icons.sentiment_dissatisfied,
                              color: Colors.orange,
                              size: 18); // Fallback emoji icon
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
           
          ],
        ),
      ),
    );
  }
}
