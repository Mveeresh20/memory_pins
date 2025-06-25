import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppColors {
  // Primary color used f
  //or buttons and selected items
  static const Color transparent = Colors.transparent;
  static const Color colorWhite = Color(0xFFFFFFFF);

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color primary = Color(0xFF3376DA);
  static const Color secondary = CupertinoColors.systemGreen;

  // Background colors
  static const Color scaffoldBackground = Color(0xFF1E2C37);
  static const Color appBarBackground = Color(0xFF1E2C37);
  static const Color cardBackground = Color(0xFF13212C);

  static const Color cardLightBackground = Color(0xFF344552);

  static const Color background = CupertinoColors.systemBackground;
  static const Color surface = CupertinoColors.systemBackground;

  // Text colors
  static const Color primaryText = Colors.white;
  static const Color secondaryText = Color(0x66FFFFFF); // 40% opacity
  static const Color text = CupertinoColors.label;
  static const Color textSecondary = CupertinoColors.secondaryLabel;

  // Border and Error colors
  static const Color borderColor = Color(0x4DFFFFFF); // 30% opacity
  static const Color error = CupertinoColors.systemRed;

  static const TextStyle textWhite = TextStyle(color: Colors.white);

  static const Color grey = CupertinoColors.systemGrey;

  // Additional color variations
  static Color primaryWithOpacity(double opacity) =>
      Color(0xFF3376DA).withOpacity(opacity);
  static Color whiteWithOpacity(double opacity) =>
      Colors.white.withOpacity(opacity);

  static const Color frameBgColor = Color(0xFF253743);
  static const Color bgGroundYellow = Color(0xFFF5BF4D);

  static  BoxShadow backShadow = BoxShadow(color: Color(0xFF9254DE),blurRadius:0.32 );

  static const Color borderColor1 = Color(0xFFB37FFB);
}
