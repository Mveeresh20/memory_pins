# iOS Google Maps Setup Guide

## Current Status
✅ **Fixed**: Info.plist API key placeholder  
❌ **Needs Action**: Google Cloud Console configuration  
❌ **Needs Action**: API key restrictions for iOS  

## What Was Fixed

### 1. Info.plist API Key
- **Before**: `YOUR_GOOGLE_MAPS_API_KEY_HERE`
- **After**: `AIzaSyCUKmzzfYOtY2MuKtIBTobiNI07sYH3F_F`

### 2. AppDelegate.swift
- ✅ Already correctly configured with the API key

## What You Need to Do

### Step 1: Update Google Cloud Console

1. **Go to [Google Cloud Console](https://console.cloud.google.com/)**
2. **Navigate to APIs & Services > Credentials**
3. **Find your API key**: `AIzaSyCUKmzzfYOtY2MuKtIBTobiNI07sYH3F_E`
4. **Click on the API key to edit it**
5. **Under "Application restrictions":**
   - Select **"iOS apps"**
   - Add Bundle ID: `com.example.memoryPinsApp`
6. **Under "API restrictions":**
   - Select **"Restrict key"**
   - Enable these APIs:
     - Maps SDK for iOS
     - Places API
     - Geocoding API
     - Directions API
7. **Save the changes**

### Step 2: Enable Required APIs

In your Google Cloud project, make sure these APIs are enabled:
- Maps SDK for iOS
- Places API
- Geocoding API
- Directions API

### Step 3: Test the Configuration

#### For iOS Simulator:
```bash
flutter run -d ios
```

#### For iOS Device (Debug):
```bash
flutter run -d ios
```

#### For iOS Device (Release):
```bash
flutter run -d ios --release
```

#### For Production Build:
```bash
flutter build ios --release
```

## Troubleshooting

### If Maps Don't Load on iOS:

1. **Check API Key Restrictions**
   - Ensure iOS apps are selected
   - Verify bundle ID: `com.example.memoryPinsApp`

2. **Check API Quotas**
   - Ensure you haven't exceeded daily limits
   - Enable billing if required

3. **Check Network**
   - Ensure device has internet connection
   - Check if corporate firewall blocks Google services

4. **Check Location Permissions**
   - Ensure location permissions are granted
   - Check if GPS is enabled

### Common Error Messages:

- **"Google Maps API key not found"**: Check Info.plist and AppDelegate.swift
- **"This API project is not authorized"**: Enable required APIs in Google Cloud Console
- **"API key not valid"**: Check API key restrictions and bundle ID
- **"Quota exceeded"**: Check usage limits in Google Cloud Console

## Bundle ID Information

- **iOS Bundle ID**: `com.example.memoryPinsApp`
- **Android Package Name**: `com.example.memory_pins_app`
- **API Key**: `AIzaSyCUKmzzfYOtY2MuKtIBTobiNI07sYH3F_E`

## Testing Checklist

- [ ] Google Cloud Console updated with iOS restrictions
- [ ] Required APIs enabled
- [ ] Info.plist has correct API key
- [ ] AppDelegate.swift has correct API key
- [ ] iOS simulator test passes
- [ ] iOS device test passes
- [ ] Release build test passes
- [ ] Maps load correctly
- [ ] Location services work
- [ ] Pins display on map

## Production Considerations

### For App Store Release:
1. **Create proper provisioning profiles**
2. **Use production bundle ID** (not `com.example.memoryPinsApp`)
3. **Update Google Cloud Console** with production bundle ID
4. **Test thoroughly** on physical devices

### Security Best Practices:
1. **Restrict API key** to specific bundle IDs
2. **Enable API restrictions** to only required APIs
3. **Monitor usage** in Google Cloud Console
4. **Set up billing alerts** to avoid unexpected charges

## Support

If you continue to have issues:
1. Check Google Cloud Console error logs
2. Verify all configuration steps
3. Test with a simple Google Maps example
4. Contact Google Cloud support if needed 