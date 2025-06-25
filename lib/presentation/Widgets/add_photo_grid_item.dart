import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart'; // Make sure to import it

// ... (rest of your code, e.g., the AddPhotoGridItem)

class AddPhotoGridItem extends StatelessWidget {
  final VoidCallback onTap;

  const AddPhotoGridItem({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder( // Correct usage: parameters directly here
        borderType: BorderType.RRect, // This is a direct parameter
        radius: const Radius.circular(16), // This is a direct parameter
        dashPattern: const [8, 4], // This is a direct parameter
        strokeWidth: 2, // This is a direct parameter
        color: Colors.white, // This is a direct parameter
        child: Center(
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }
}

// Example of how to add dotted_border to your pubspec.yaml
// dependencies:
//   flutter:
//     sdk: flutter
//   dotted_border: ^2.0.0+2 # Always check pub.dev for the latest version