import 'package:flutter/material.dart';

Future<void> showCustomDialog({
  required BuildContext context,
  required String title,
  required String title2,
  required String confirmText,
  required VoidCallback onConfirm,
  required String cancelText,
  VoidCallback? onCancel,
  Color backgroundColor = const Color(0xFF252F38),
  TextStyle? titleStyle,
  TextStyle? titleStyle2,
  double borderRadius = 14.0,
  EdgeInsets contentPadding = const EdgeInsets.all(16.0),
}) async {
  FocusScope.of(context).unfocus(); // Close any open keyboard

  return await showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: () => FocusScope.of(dialogContext).unfocus(),
          child: Align(
            alignment: Alignment.center,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: contentPadding,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: titleStyle ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          title2,
                          textAlign: TextAlign.center,
                          style: titleStyle2 ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: onCancel ??
                                    () {
                                  Navigator.of(dialogContext).pop();
                                },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11.0),
                              ),
                            ),
                            child: Text(cancelText),
                          ),
                          const SizedBox(width: 8.0),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                              onConfirm();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF12C4C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(11.0),
                              ),
                            ),
                            child: Text(confirmText),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
