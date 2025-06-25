import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

class NetworkHelper {
  static Future<bool> checkNetwork() async {
    bool networkResults = true;

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        networkResults = true;
      }
    } catch (e) {
      networkResults = false;
    }
    return networkResults;
  }

  static Future<void> checkAndPerformAction(
      BuildContext context, Future<void> Function() action) async {
    bool network = await NetworkHelper
        .checkNetwork(); // Assuming this is your method to check network
    if (network) {
      // If network is available, perform the provided action
      await action();
    } else {
      // If network is not available, show a SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please check your network connection."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
