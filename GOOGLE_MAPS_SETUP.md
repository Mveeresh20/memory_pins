# Google Maps Setup Guide

## Overview
Your Flutter app now includes a real-time Google Maps integration on the home screen, replacing the static background image with an interactive map that displays pins and user location.

## Features Added
- **Real-time Google Maps**: Interactive map showing user location and nearby pins
- **Pin Markers**: Red markers for pins, blue marker for user location
- **Map Controls**: Zoom in/out and location centering buttons
- **Location Services**: Automatic location detection and permission handling
- **Pin Interaction**: Tap on map markers to view pin details

## Setup Requirements

### 1. Google Maps API Key
You need to obtain a Google Maps API key and configure it in your project:

#### For Android:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Places API (if you plan to add location search)
4. Create credentials (API Key)
5. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` in `android/app/src/main/AndroidManifest.xml` with your actual API key

#### For iOS:
1. In the same Google Cloud Console project, enable:
   - Maps SDK for iOS
   - Places API (if needed)
2. Add the API key to `ios/Runner/AppDelegate.swift`:
   ```swift
   import Flutter
   import UIKit
   import GoogleMaps

   @main
   @objc class AppDelegate: FlutterAppDelegate {
     override func application(
       _ application: UIApplication,
       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
       GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
       GeneratedPluginRegistrant.register(with: self)
       return super.application(application, didFinishLaunchingWithOptions: launchOptions)
     }
   }
   ```

### 2. Location Permissions
The app already includes the necessary location permissions in the Android manifest. For iOS, add these to `ios/Runner/Info.plist`:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to location to show nearby pins and your current position on the map.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs access to location to show nearby pins and your current position on the map.</string>
```

## How It Works

### HomeMapWidget
- **Location Detection**: Automatically gets user's current location
- **Pin Display**: Shows all nearby pins as red markers on the map
- **User Location**: Shows user's location as a blue marker
- **Interactive Controls**: Zoom in/out and center on location buttons

### Map Features
- **Auto-fit Bounds**: Automatically adjusts map view to show all pins
- **Marker Info Windows**: Tap markers to see pin title and location
- **Smooth Animations**: Camera movements are animated for better UX
- **Error Handling**: Graceful fallback if location services are unavailable

### Integration with Existing Code
- **Pin Provider**: Uses existing pin data from your Firebase integration
- **Location Service**: Leverages your existing location service
- **UI Consistency**: Maintains your existing UI design and color scheme

## Testing
1. Run the app on a device with location services enabled
2. Grant location permissions when prompted
3. The home screen should now show a Google Map instead of the static background
4. Your location should appear as a blue marker
5. Nearby pins should appear as red markers
6. Test the zoom and location buttons

## Troubleshooting
- **Map not loading**: Check your Google Maps API key configuration
- **No location**: Ensure location permissions are granted
- **No pins showing**: Verify your Firebase integration is working and pins have valid coordinates
- **Performance issues**: The map automatically optimizes marker display and camera movements

## Next Steps
- Customize marker icons to match your app's design
- Add clustering for many pins in the same area
- Implement location search functionality
- Add different map styles (satellite, terrain, etc.) 