import 'package:flutter/material.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';

class ProfileOptionTile extends StatelessWidget {
  final String image; // The leading icon for the option
  final String title; // The text title of the option
  final VoidCallback onTap; // Callback function when the tile is tapped
  final bool showArrow;
  final bool isSelected; // Whether to show the trailing arrow icon ('>')
  // Optional color for the trailing arrow icon

  const ProfileOptionTile({
    Key? key,
    required this.image,
    required this.title,
    required this.onTap,
    this.showArrow = true,
    this.isSelected = false, // Default to true (show arrow)
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine default colors if not provided
    // Lighter arrow for contrast

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Spacing between tiles

        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFF6944),
                    Color(0xFFFE5F38),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : const Color(0xFF131F2B),
          borderRadius:
              BorderRadius.circular(12.0), // Rounded corners for the tile
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Image.network(
                image,
                fit: BoxFit.contain,
                height: 24,
              ),
              const SizedBox(width: 16.0), // Space between icon and text
              Expanded(
                child: Text(
                  title,
                  style: text14W500White(context),
                ),
              ),
              if (showArrow) // Conditionally show the arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16.0,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
