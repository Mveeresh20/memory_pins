import 'dart:developer';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:memory_pins_app/aws/aws_fields.dart' as AppConstant;
import 'package:memory_pins_app/services/auth_service.dart';
import 'package:memory_pins_app/services/profile_details.dart';
import 'package:memory_pins_app/services/user_services.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';

class EditProfileProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasError = false;
  bool _isInBuildPhase = false;

  bool get isLoading => _isLoading;
  bool get hasError => _hasError;

  // Methods to control build phase notifications
  void setBuildPhase(bool inBuildPhase) {
    _isInBuildPhase = inBuildPhase;
  }

  void setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      if (!_isInBuildPhase) {
        notifyListeners();
      }
    }
  }

  void setError(bool value) {
    if (_hasError != value) {
      _hasError = value;
      if (!_isInBuildPhase) {
        notifyListeners();
      }
    }
  }

  FocusNode? firstNameFocusNode;
  TextEditingController firstNameController = TextEditingController();
  String? validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name cannot be empty';
    }
    return null;
  }

  FocusNode? mobileNumberFocusNode;
  TextEditingController mobileNumberController = TextEditingController();
  String? validateMobileNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mobile number cannot be empty';
    }
    return null;
  }

  FocusNode? lastNameFocusNode;
  TextEditingController? lastNameController = TextEditingController();
  String? validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last Name cannot be empty';
    }
    return null;
  }

  FocusNode? emailFocusNode;
  TextEditingController emailTextController = TextEditingController();
  String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email cannot be empty';
    } else if (!RegExp(emailRegex).hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  FocusNode? recurrenceNode;
  String? selectedGender;
  String? validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a gender';
    }
    return null;
  }

  ProfileDetails? _profileDetails;

  ProfileDetails? get profileDetails => _profileDetails;

  set profileDetails(ProfileDetails? value) {
    _profileDetails = value;
    if (!_isInBuildPhase) {
      notifyListeners();
    }
  }

  String? _profilePicture = '';

  String? get profilePicture => _profilePicture;

  set profilePicture(String? value) {
    _profilePicture = value;
    if (!_isInBuildPhase) {
      notifyListeners();
    }
  }

  // Get the full image URL for display
  String getProfileImageUrl() {
    if (_profilePicture == null || _profilePicture!.isEmpty) {
      return Images.noprofileImg;
    }
    try {
      // If the profile picture is already a full URL, return it
      if (_profilePicture!.startsWith('http')) {
        return _profilePicture!;
      }
      // Otherwise, construct the URL using the correct base URL
      return "${AppConstant.baseUrlToUploadAndFetchUsersImage}/${_profilePicture!}";
    } catch (e) {
      print("Error getting image URL: $e");
      return Images.noprofileImg;
    }
  }

  // Get the full image URL for display with different default for specific screens
  String getProfileImageUrlForScreens() {
    if (_profilePicture == null || _profilePicture!.isEmpty) {
      return Images.profileImg; // Different default for home, map, tapu screens
    }
    try {
      // If the profile picture is already a full URL, return it
      if (_profilePicture!.startsWith('http')) {
        return _profilePicture!;
      }
      // Otherwise, construct the URL using the correct base URL
      return "${AppConstant.baseUrlToUploadAndFetchUsersImage}/${_profilePicture!}";
    } catch (e) {
      print("Error getting image URL: $e");
      return Images.profileImg; // Different default for home, map, tapu screens
    }
  }

  Future<void> updateUserProfile(String imagePath, BuildContext context) async {
    setLoading(true);
    try {
      String? userId = UserService().getCurrentUserId();
      if (userId == null) {
        throw Exception('User is not authenticated');
      }

      // Update in Firebase
      DatabaseReference ref = FirebaseDatabase.instance
          .ref(AuthService().firebasepath)
          .child(userId)
          .child('profileDetails');

      // Store only the relative path (e.g., users/profile/profile_1234567890.jpg)
      await ref.update({'imageProfile': imagePath});

      // Update local state
      profilePicture = imagePath;
      notifyListeners();

      if (context.mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text("Profile picture updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error updating profile: $e");
      if (context.mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text("Error updating profile picture: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setLoading(false);
    }
  }

  Future<String?> fetchUserProfileImage() async {
    String? userId = UserService().getCurrentUserId();
    if (userId != null) {
      DatabaseReference ref = FirebaseDatabase.instance
          .ref(AuthService().firebasepath)
          .child(userId)
          .child('profileDetails');
      DatabaseEvent event = await ref.once();

      DataSnapshot snapshot = event.snapshot;

      final data = snapshot.value;
      if (data is! Map) {
        return null;
      }
      Map<String, dynamic> userData = Map<String, dynamic>.from(data);

      ProfileDetails profileDetails = ProfileDetails.fromMap(userData);

      profilePicture = profileDetails.imageProfile ?? '';
      emailTextController.text = profileDetails.email ?? '';
      mobileNumberController.text = profileDetails.mobileNumber ?? 'xxxxxxxxxx';

      // Extract profile details
      firstNameController.text = '${profileDetails.userName}';
      notifyListeners();
      if (snapshot.exists) {
        // Fetch the 'imageProfile' from the snapshot
        log('imageProfile ->1 $profilePicture');

        return snapshot.child('imageProfile').value as String?;
      } else {
        print('User profile not found');
        return null;
      }
    } else {
      print('User is not authenticated');
      return null;
    }
  }

  Future<void> updateUserProfileDetails(BuildContext context) async {
    setLoading(true);

    try {
      String? userId = UserService().getCurrentUserId();
      if (userId == null) {
        if (context.mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('User is not authenticated')),
          );
        }
        setLoading(false);
        return;
      }

      // First fetch the existing profile details to get the current image
      DatabaseReference ref = FirebaseDatabase.instance
          .ref(AuthService().firebasepath)
          .child(userId)
          .child('profileDetails');
      DatabaseEvent event = await ref.once();
      DataSnapshot snapshot = event.snapshot;

      String? existingImageProfile;
      if (snapshot.exists) {
        final data = snapshot.value;
        if (data is Map) {
          Map<String, dynamic> userData = Map<String, dynamic>.from(data);
          existingImageProfile = userData['imageProfile'] as String?;
        }
      }

      // Create the profile details object with the existing image OR the current provider image
      var profileDetails = ProfileDetails(
        userName: firstNameController.text,
        email: emailTextController.text,
        mobileNumber: mobileNumberController.text.isNotEmpty &&
                mobileNumberController.text != 'xxxxxxxxxx'
            ? mobileNumberController.text
            : 'xxxxxxxxxx',
        imageProfile: existingImageProfile ?? profilePicture,
      );

      // Update the user's profile details in Firebase
      await ref.update(profileDetails.toMap());
      setLoading(false);

      // Return to the previous screen with a result of true
      if (context.mounted) {
        Navigator.pop(context, true);
      }

      if (context.mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      setLoading(false);
      if (context.mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<ProfileDetails?> fetchUserProfileDetails() async {
    try {
      // Set build phase to true to prevent notifications during build
      setBuildPhase(true);
      setError(false);

      String? userId = UserService().getCurrentUserId();
      if (userId == null) {
        log('User is not authenticated');
        setBuildPhase(false);
        setError(true);
        return null;
      }
      if (userId == null) {
        log('User is not authenticated');
        setLoading(false);
        setError(true);
        return null;
      }

      DatabaseReference ref = FirebaseDatabase.instance
          .ref(AuthService().firebasepath)
          .child(userId)
          .child('profileDetails');
      final event = await ref.once();
      final snapshot = event.snapshot;

      if (!snapshot.exists) {
        log('No profile data found - creating default profile for guest user');

        // Create default profile for guest users
        final defaultProfile = ProfileDetails(
          userName: 'Guest User',
          email: 'email',
          mobileNumber: 'Mobile Number',
          imageProfile: '',
        );

        // Save the default profile to database
        await ref.set(defaultProfile.toMap());

        // Set the profile details
        profileDetails = defaultProfile;

        // Update controllers
        firstNameController.text = defaultProfile.userName ?? '';
        emailTextController.text = defaultProfile.email ?? '';
        profilePicture = defaultProfile.imageProfile;
        mobileNumberController.text =
            defaultProfile.mobileNumber ?? 'xxxxxxxxxx';

        // Reset build phase and notify listeners
        setBuildPhase(false);
        notifyListeners();
        return defaultProfile;
      }

      final data = snapshot.value;
      if (data == null || data is! Map) {
        log('Invalid data format');
        setLoading(false);
        setError(true);
        return null;
      }

      Map<String, dynamic> userData = Map<String, dynamic>.from(data);
      profileDetails = ProfileDetails.fromMap(userData);

      firstNameController.text = profileDetails?.userName ?? '';
      emailTextController.text = profileDetails?.email ?? '';
      profilePicture = profileDetails?.imageProfile;
      mobileNumberController.text =
          profileDetails?.mobileNumber ?? 'xxxxxxxxxx';

      // Reset build phase and notify listeners
      setBuildPhase(false);
      notifyListeners();
      return profileDetails;
    } catch (e) {
      log('Error fetching profile details: $e');
      setBuildPhase(false);
      setError(true);
      return null;
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      // Clear track data cache
      //      TrackService().clearTracks();

      // Clear image cache
      await _clearImageCache();

      // Clear provider state
      profileDetails = null;
      profilePicture = '';
      firstNameController.clear();
      lastNameController?.clear();
      emailTextController.clear();
      mobileNumberController.clear();
      notifyListeners();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Navigate to login/signup only if context is still valid
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      print('Error during logout: $e');
      // Even if there's an error, try to navigate if context is still valid
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  // Method to clear all cached images
  Future<void> _clearImageCache() async {
    try {
      // Clear the default cache manager
      await DefaultCacheManager().emptyCache();

      // Also clear any custom cache if you have one
      // If you're using a custom cache manager, clear it here too

      print('Image cache cleared successfully');
    } catch (e) {
      print('Error clearing image cache: $e');
    }
  }

  // Method to clear cache when switching users (call this on login)
  Future<void> clearCacheOnUserSwitch() async {
    await _clearImageCache();
    // Reset profile data
    profileDetails = null;
    profilePicture = '';
    firstNameController.clear();
    lastNameController?.clear();
    emailTextController.clear();
    mobileNumberController.clear();
    notifyListeners();
  }

  /// Update only the user's name and email (no gender required)
  Future<void> updateUserNameAndEmail(
    String name,
    String email,
    String phone,
    BuildContext context,
  ) async {
    setLoading(true);
    try {
      String? userId = UserService().getCurrentUserId();
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is not authenticated')),
        );
        setLoading(false);
        return;
      }
      DatabaseReference ref = FirebaseDatabase.instance
          .ref(AuthService().firebasepath)
          .child(userId)
          .child('profileDetails');

      // Update all fields including mobile number
      await ref.update({
        'userName': name,
        'email': email,
        'mobileNumber': phone.isNotEmpty && phone != 'xxxxxxxxxx'
            ? phone
            : 'xxxxxxxxxx', // Save mobile number with fallback
      });

      // Update provider state
      firstNameController.text = name;
      emailTextController.text = email;
      mobileNumberController.text = phone;

      if (_profileDetails != null) {
        _profileDetails!.userName = name;
        _profileDetails!.email = email;
        _profileDetails!.mobileNumber =
            phone.isNotEmpty && phone != 'xxxxxxxxxx' ? phone : 'xxxxxxxxxx';
      }

      notifyListeners();
      setLoading(false);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back after successful update
        Navigator.pop(context, true);
      }
    } catch (e) {
      setLoading(false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    firstNameController.dispose();
    lastNameController?.dispose();
    emailTextController.dispose();
    super.dispose();
  }
}
