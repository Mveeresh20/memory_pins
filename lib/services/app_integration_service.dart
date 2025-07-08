import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:memory_pins_app/providers/tapu_provider.dart';
import 'package:memory_pins_app/providers/user_provider.dart';
import 'package:memory_pins_app/services/firebase_service.dart';
import 'package:memory_pins_app/services/media_service.dart';
import 'package:memory_pins_app/models/pin.dart';
import 'package:memory_pins_app/models/tapus.dart';
import 'package:memory_pins_app/utills/Constants/image_picker_util.dart';
import 'package:memory_pins_app/utills/Constants/audio_picker_util.dart';

class AppIntegrationService {
  final FirebaseService _firebaseService = FirebaseService();
  final MediaService _mediaService = MediaService();
  final ImagePickerUtil _imagePickerUtil = ImagePickerUtil();
  final AudioPickerUtil _audioPickerUtil = AudioPickerUtil();

  /// Initialize all providers
  Future<void> initializeProviders(BuildContext context) async {
    try {
      await context.read<PinProvider>().initialize();
      await context.read<TapuProvider>().initialize();
      await context.read<UserProvider>().initialize();
    } catch (e) {
      print('Error initializing providers: $e');
    }
  }

  /// Create a pin with media uploads
  Future<bool> createPinWithMedia({
    required BuildContext context,
    required String title,
    required String description,
    required String mood,
    required List<File> imageFiles,
    required List<File> audioFiles,
    double? latitude,
    double? longitude,
  }) async {
    try {
      print('=== APP INTEGRATION SERVICE DEBUG ===');
      print(
          'Creating pin with ${imageFiles.length} images and ${audioFiles.length} audios');

      final pinProvider = context.read<PinProvider>();

      // Upload images to AWS
      print('Uploading ${imageFiles.length} images...');
      final imageUrls = await _mediaService.uploadImagesDirectly(imageFiles);
      print('Image uploads completed: ${imageUrls.length} URLs');

      // Upload audios to AWS
      print('Uploading ${audioFiles.length} audios...');
      final audioUrls = await _mediaService.uploadAudiosDirectly(audioFiles);
      print('Audio uploads completed: ${audioUrls.length} URLs');
      print('Audio URLs: $audioUrls');

      // Create pin in Firebase
      final success = await pinProvider.createPin(
        title: title,
        description: description,
        mood: mood,
        photoUrls: imageUrls,
        audioUrls: audioUrls,
        latitude: latitude,
        longitude: longitude,
      );

      return success;
    } catch (e) {
      print('Error creating pin with media: $e');
      return false;
    }
  }

  /// Create a tapu with media uploads
  Future<bool> createTapuWithMedia({
    required BuildContext context,
    required String title,
    required String description,
    required String mood,
    required List<File> imageFiles,
    required List<String> pinIds,
  }) async {
    try {
      final tapuProvider = context.read<TapuProvider>();

      // Upload images to AWS
      final imageUrls = await _mediaService.uploadImagesDirectly(imageFiles);

      // Create tapu in Firebase
      final success = await tapuProvider.createTapu(
        title: title,
        description: description,
        mood: mood,
        photoUrls: imageUrls,
        pinIds: pinIds,
      );

      return success;
    } catch (e) {
      print('Error creating tapu with media: $e');
      return false;
    }
  }

  /// Pick and upload images using existing image picker
  Future<List<String>> pickAndUploadImages(BuildContext context) async {
    final List<String> uploadedUrls = [];

    _imagePickerUtil.showImageSourceSelection(
      context,
      (String fileName) {
        // Success callback
        final imageUrl = _imagePickerUtil.getUrlForUserUploadedImage(fileName);
        uploadedUrls.add(imageUrl);
      },
      (String error) {
        // Failure callback
        print('Image upload failed: $error');
      },
    );

    return uploadedUrls;
  }

  /// Upload audio file using existing audio picker
  Future<String?> uploadAudioFile(
      String audioFilePath, BuildContext context) async {
    try {
      String? uploadedUrl;

      await _audioPickerUtil.uploadAudioToS3(
        audioFilePath,
        context,
        (String fileName) {
          // Success callback
          uploadedUrl = _audioPickerUtil.getUrlForUploadedAudio(fileName);
        },
        (String error) {
          // Failure callback
          print('Audio upload failed: $error');
        },
      );

      return uploadedUrl;
    } catch (e) {
      print('Error uploading audio file: $e');
      return null;
    }
  }

  /// Save a pin for the current user
  Future<void> savePin(BuildContext context, String pinId) async {
    try {
      await context.read<PinProvider>().savePin(pinId);
    } catch (e) {
      print('Error saving pin: $e');
    }
  }

  /// Unsave a pin for the current user
  Future<void> unsavePin(BuildContext context, String pinId) async {
    try {
      await context.read<PinProvider>().unsavePin(pinId);
    } catch (e) {
      print('Error unsaving pin: $e');
    }
  }

  /// Check if pin is saved by current user
  Future<bool> isPinSaved(BuildContext context, String pinId) async {
    try {
      return await context.read<PinProvider>().isPinSaved(pinId);
    } catch (e) {
      print('Error checking if pin is saved: $e');
      return false;
    }
  }

  /// Increment pin views
  Future<void> incrementPinViews(BuildContext context, String pinId) async {
    try {
      await context.read<PinProvider>().incrementPinViews(pinId);
    } catch (e) {
      print('Error incrementing pin views: $e');
    }
  }

  /// Set filter radius for pins
  void setFilterRadius(BuildContext context, double radius) {
    context.read<PinProvider>().setFilterRadius(radius);
  }

  /// Set filter type for pins
  void setFilterType(BuildContext context, String type) {
    context.read<PinProvider>().setFilterType(type);
  }

  /// Get user's pins
  List<Pin> getUserPins(BuildContext context) {
    return context.read<PinProvider>().userPins;
  }

  /// Get user's saved pins
  List<Pin> getSavedPins(BuildContext context) {
    return context.read<PinProvider>().savedPins;
  }

  /// Get nearby pins
  List<Pin> getNearbyPins(BuildContext context) {
    return context.read<PinProvider>().filteredPins;
  }

  /// Get user's tapus
  List<Tapus> getUserTapus(BuildContext context) {
    return context.read<TapuProvider>().userTapus;
  }

  /// Load tapu pins
  Future<void> loadTapuPins(BuildContext context, String tapuId) async {
    try {
      await context.read<TapuProvider>().loadTapuPins(tapuId);
    } catch (e) {
      print('Error loading tapu pins: $e');
    }
  }

  /// Get tapu pins
  List<Pin> getTapuPins(BuildContext context) {
    return context.read<TapuProvider>().tapuPins;
  }

  /// Sign in user
  Future<bool> signInUser(
      BuildContext context, String email, String password) async {
    try {
      return await context.read<UserProvider>().signIn(
            email: email,
            password: password,
          );
    } catch (e) {
      print('Error signing in user: $e');
      return false;
    }
  }

  /// Sign up user
  Future<bool> signUpUser(BuildContext context, String email, String password,
      {String? name}) async {
    try {
      return await context.read<UserProvider>().signUp(
            email: email,
            password: password,
            name: name,
          );
    } catch (e) {
      print('Error signing up user: $e');
      return false;
    }
  }

  /// Sign out user
  Future<void> signOutUser(BuildContext context) async {
    try {
      await context.read<UserProvider>().signOut();
    } catch (e) {
      print('Error signing out user: $e');
    }
  }

  /// Update user profile
  Future<bool> updateUserProfile(
    BuildContext context, {
    String? name,
    String? profileImage,
    String? gender,
  }) async {
    try {
      return await context.read<UserProvider>().updateProfile(
            name: name,
            profileImage: profileImage,
            gender: gender,
          );
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  /// Get current user info
  Map<String, dynamic>? getCurrentUserProfile(BuildContext context) {
    return context.read<UserProvider>().userProfile;
  }

  /// Check if user is authenticated
  bool isUserAuthenticated(BuildContext context) {
    return context.read<UserProvider>().isAuthenticated;
  }

  /// Get user display name
  String getUserDisplayName(BuildContext context) {
    return context.read<UserProvider>().displayName;
  }

  /// Get user email
  String getUserEmail(BuildContext context) {
    return context.read<UserProvider>().email;
  }

  /// Get user profile image
  String getUserProfileImage(BuildContext context) {
    return context.read<UserProvider>().profileImage;
  }

  /// Get distance between two points
  double getDistance(BuildContext context, double lat1, double lon1,
      double lat2, double lon2) {
    return context.read<PinProvider>().getDistance(lat1, lon1, lat2, lon2);
  }

  /// Get formatted distance string
  String getFormattedDistance(BuildContext context, double distanceInKm) {
    return context.read<PinProvider>().getFormattedDistance(distanceInKm);
  }

  /// Refresh all data
  Future<void> refreshAllData(BuildContext context) async {
    try {
      await context.read<PinProvider>().refresh();
      await context.read<TapuProvider>().refresh();
    } catch (e) {
      print('Error refreshing data: $e');
    }
  }

  /// Show loading state
  void showLoading(BuildContext context) {
    // You can implement a loading overlay here
    print('Loading...');
  }

  /// Hide loading state
  void hideLoading(BuildContext context) {
    // You can hide the loading overlay here
    print('Loading complete');
  }

  /// Show error message
  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show success message
  void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
