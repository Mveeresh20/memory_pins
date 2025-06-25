
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import 'package:flutter/material.dart';
showSuccessSnackaBar({
  required String title,
    required String message,
 
    VoidCallback? onDismiss,
}){
  
  Get.snackbar(
    title,
    message,
    snackStyle: SnackStyle.FLOATING,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: Colors.white,
    duration: const Duration(seconds: 2),
  );
}
class DialogHelper {
  static void showLoginRequiredDialog({
    required BuildContext context,
    required VoidCallback onLogin,
  }) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
    
        title: const Text('Login Required', ),
        content: const Text(
          'You need to be logged in to perform this action. Would you like to login now?'
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Login'),
            onPressed: () {
              Navigator.pop(ctx);
              onLogin();
            },
          ),
        ],
      ),
    );
  }

  static void showErrorDialog({
    required BuildContext context,
    String? title,
    String? message,
  }) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? 'Error'),
          content: Text(message ?? 'An error occurred'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  static void showSuccessDialog({
    required String title,
    required String message,
    bool autoClose=false,
    VoidCallback? onOKClicked,
  }) {
    Get.dialog(
      CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () {
              Get.back();
              onOKClicked?.call();
            },
          ),
        ],
      ),
      barrierDismissible: false,
      useSafeArea: true,
      transitionCurve: Curves.easeInOut,
      transitionDuration: const Duration(milliseconds: 200),
    );
  }

  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }
} 