import 'package:flutter/widgets.dart';

class SizeUtil {
  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  static double screenAspectRatio(BuildContext context) {
    return MediaQuery.sizeOf(context).aspectRatio;
  }
}
