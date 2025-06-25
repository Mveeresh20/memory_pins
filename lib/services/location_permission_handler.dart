import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionHandler {
  static Future<bool> requestLocationPermission( ) async {
    // First check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showLocationServicesDialog( );
      return false;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await _showLocationSettingsDialog( );
      return false;
    }

    return true;
  }

  static Future<void> _showLocationServicesDialog( ) async {
    return Get.dialog(
     
     AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Please enable location services to use this feature. '
            'You can enable it in your device settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Get.back();
                await Geolocator.openLocationSettings();
              },
            ),
          ],
        
       
    ));
  }

  static Future<void> _showLocationSettingsDialog( ) async {
   Get.dialog(
     
      
      AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is required to use this feature. '
            'Please enable it in your device settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Get.back();
              },
            ),
            TextButton(
              child: const Text('Open Settings'),
              onPressed: () async {
                Get.back();
                await Geolocator.openLocationSettings();
              },
            ),
          ],
        
    ));
  }

  static Future<void> showLocationServicesDialog( ) async {
    return _showLocationServicesDialog( );
  }

  static Future<void> showLocationSettingsDialog( ) async {
    return _showLocationSettingsDialog( );
  }
} 