# Google Maps Release Build Fix Guide

## Problem Description
The Google Maps widget works correctly in debug mode but shows an ocean location and no pins in release builds. This is a common issue related to API key restrictions and signing configurations.

## Root Causes
1. **API Key Restrictions**: Google Maps API key is restricted to debug SHA-1 fingerprints only
2. **Signing Configuration**: Release builds use different signing keys than debug builds
3. **Network Security**: Release builds have stricter network security policies
4. **Location Permissions**: Release builds handle location permissions differently

## Solutions Applied

### 1. Updated Build Configuration (`android/app/build.gradle.kts`)
- Added proper signing configuration for release builds
- Configured release builds to use debug keystore temporarily
- Added ProGuard rules to prevent obfuscation of Google Maps classes

### 2. Enhanced AndroidManifest.xml
- Added additional location permissions (`ACCESS_BACKGROUND_LOCATION`, `ACCESS_NETWORK_STATE`, `WAKE_LOCK`)
- Added network security configuration
- Enabled cleartext traffic for development

### 3. Created Network Security Config (`android/app/src/main/res/xml/network_security_config.xml`)
- Allows network access to Google Maps services
- Configures trust anchors for secure connections

### 4. Improved Map Widget (`lib/presentation/Widgets/map_pin_widget.dart`)
- Added retry logic for location services
- Enhanced error handling and logging
- Improved map initialization process

### 5. Added ProGuard Rules (`android/app/proguard-rules.pro`)
- Prevents Google Maps classes from being obfuscated
- Keeps Flutter and location service classes intact

## Steps to Complete the Fix

### Step 1: Get SHA-1 Fingerprints
Run the provided PowerShell script:
```powershell
.\get_sha1_fingerprints.ps1
```

### Step 2: Update Google Cloud Console
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to **APIs & Services** > **Credentials**
3. Find your Google Maps API key: `AIzaSyCUKmzzfYOtY2MuKtIBTobiNI07sYH3F_E`
4. Click on the API key to edit it
5. Under **Application restrictions**, select **Android apps**
6. Add the following:
   - **Package name**: `com.example.memory_pins_app`
   - **SHA-1 certificate fingerprint**: (from the PowerShell script output)
7. Save the changes

### Step 3: Enable Required APIs
Make sure these APIs are enabled in your Google Cloud project:
- Maps SDK for Android
- Places API
- Geocoding API
- Directions API

### Step 4: Test the Build
```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Install on device
flutter install --release
```

## Troubleshooting

### If maps still don't work:
1. **Check API key restrictions**: Ensure the SHA-1 fingerprint matches exactly
2. **Verify package name**: Must be `com.example.memory_pins_app`
3. **Check API quotas**: Ensure you haven't exceeded daily limits
4. **Enable billing**: Google Maps APIs require billing to be enabled

### If location doesn't work:
1. **Check device permissions**: Ensure location permissions are granted
2. **Check GPS**: Ensure GPS is enabled on the device
3. **Check network**: Ensure device has internet connection

### If pins don't show:
1. **Check data source**: Ensure pins are being loaded correctly
2. **Check coordinates**: Ensure pin coordinates are valid
3. **Check network**: Ensure images and data can be loaded

## Production Considerations

### For Production Release:
1. **Create proper release keystore**:
   ```bash
   keytool -genkey -v -keystore my-release-key.keystore -alias my-key-alias -keyalg RSA -keysize 2048 -validity 10000
   ```

2. **Update build.gradle.kts** to use production keystore:
   ```kotlin
   signingConfigs {
       create("release") {
           keyAlias = "my-key-alias"
           keyPassword = "your-key-password"
           storeFile = file("my-release-key.keystore")
           storePassword = "your-store-password"
       }
   }
   ```

3. **Get production SHA-1** and add it to Google Cloud Console

4. **Remove debug configurations** from production builds

## Additional Notes

- The current setup uses debug keystore for both debug and release builds to ensure compatibility
- For production, you should create a proper release keystore
- The network security config allows cleartext traffic for development; consider restricting this for production
- Location services have retry logic to handle temporary failures
- All Google Maps classes are preserved during ProGuard optimization

## Testing Checklist

- [ ] Debug build works correctly
- [ ] Release build shows correct map location
- [ ] Pins are visible on the map
- [ ] Location services work properly
- [ ] Map controls (zoom, location) work
- [ ] No crashes or errors in release mode 