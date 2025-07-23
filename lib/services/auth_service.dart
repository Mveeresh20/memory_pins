import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:memory_pins_app/presentation/Pages/home_screen.dart';
import 'package:memory_pins_app/presentation/Pages/onboarding3.dart';
import 'package:memory_pins_app/services/edit_profile_provider.dart';
import 'package:memory_pins_app/providers/pin_provider.dart';
import 'package:memory_pins_app/providers/tapu_provider.dart';
import 'package:memory_pins_app/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final String TABLE_NAME = 'memory_pins';
  final String PROFILE_DETAILS_TABLE = 'profileDetails';

  final String firebasepath = 'memory_pins';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<void> performLogout(BuildContext context) async {
    try {
      print('Starting logout process...');

      // Clear all caches and data
      await _clearAllCaches();

      // Clear all provider states
      await _clearAllProviders(context);

      // Clear saved auth token
      await _clearAuthToken();

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      print('Logout completed successfully');

      // Navigate to login only if context is still valid
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

  // Clear caches when new user logs in
  static Future<void> clearCachesOnLogin(BuildContext context) async {
    try {
      print('Clearing caches for new user login...');

      // Clear all provider states
      await _clearAllProviders(context);

      // Force refresh hidden content for new user
      try {
        final pinProvider = Provider.of<PinProvider>(context, listen: false);
        await pinProvider.forceRefreshHiddenContent();
        print('Hidden content refreshed for new user');
      } catch (e) {
        print('Error refreshing hidden content on login: $e');
      }

      print('Caches cleared for new user login');
    } catch (e) {
      print('Error clearing caches on login: $e');
    }
  }

  static Future<void> _clearAllCaches() async {
    try {
      // Clear track data cache

      // Clear image cache

      print('All caches cleared successfully');
    } catch (e) {
      print('Error clearing caches: $e');
    }
  }

  // Clear all provider states
  static Future<void> _clearAllProviders(BuildContext context) async {
    try {
      if (!context.mounted) return;

      // Clear EditProfileProvider
      final editProfileProvider = Provider.of<EditProfileProvider>(
        context,
        listen: false,
      );
      editProfileProvider.profileDetails = null;
      editProfileProvider.profilePicture = '';
      editProfileProvider.firstNameController.clear();
      editProfileProvider.lastNameController?.clear();
      editProfileProvider.emailTextController.clear();
      editProfileProvider.selectedGender = null;
      editProfileProvider.notifyListeners();

      // Clear PinProvider cache and hidden content
      try {
        final pinProvider = Provider.of<PinProvider>(context, listen: false);
        await pinProvider.clearAllCaches();
        print('PinProvider cache cleared successfully');
      } catch (e) {
        print('Error clearing PinProvider: $e');
      }

      // Clear TapuProvider cache and hidden content
      try {
        final tapuProvider = Provider.of<TapuProvider>(context, listen: false);
        await tapuProvider.clearAllCaches();
        print('TapuProvider cache cleared successfully');
      } catch (e) {
        print('Error clearing TapuProvider: $e');
      }

      // Clear UserProvider
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.clearUserData();
        print('UserProvider cache cleared successfully');
      } catch (e) {
        print('Error clearing UserProvider: $e');
      }

      print('All providers cleared successfully');
    } catch (e) {
      print('Error clearing providers: $e');
    }
  }

  // Clear auth token from SharedPreferences
  static Future<void> _clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('authToken');
      await prefs.remove('userId');
      print('Auth token cleared successfully');
    } catch (e) {
      print('Error clearing auth token: $e');
    }
  }

  Future<User?> signUp(String email, String password, {String? name}) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save user profile details to Realtime Database
      if (result.user != null) {
        final userId = result.user!.uid;
        final userRef = FirebaseDatabase.instance.ref(
          'memory_pins/$userId/profileDetails',
        );

        // Create initial profile details
        final profileDetails = {
          'userName': name ??
              email.split('@')[0], // Use part of email if name not provided
          'email': email,
          'imageProfile': '', // Empty string for default profile image
          'mobileNumber': 'xxxxxxxxxx', // Add fallback for mobile number
          'createdAt': ServerValue.timestamp,
          'lastLogin': ServerValue.timestamp,
          'authProvider': 'email',
          'isGuest': false,

          // Empty string for gender
        };

        await userRef.set(profileDetails);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Sign up error:${e.message}");
      return null;
    }
  }

  Future<void> _saveAuthToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await user.getIdToken();
      if (token == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('authToken', token);
      await prefs.setString('userId', user.uid);
      print('Auth token saved successfully');
    } catch (e) {
      print('Error saving auth token: $e');
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login
      if (result.user != null) {
        final userId = result.user!.uid;
        final userRef = FirebaseDatabase.instance
            .ref(firebasepath)
            .child(userId)
            .child('profileDetails');

        await userRef.update({'lastLogin': ServerValue.timestamp});

        // Save auth token
        await _saveAuthToken();
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Sign in error: ${e.message}");
      throw _handleAuthError(e);
    }
  }

  String _handleAuthError(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password provided';
        case 'email-already-in-use':
          return 'An account already exists with this email';
        case 'weak-password':
          return 'Password is too weak. Please use a stronger password';
        case 'invalid-email':
          return 'Please enter a valid email address';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled';
        case 'network-request-failed':
          return 'Network error. Please check your connection';
        default:
          return e.message ?? 'An unknown error occurred';
      }
    }
    return e.toString();
  }

  Future<void> signInAnonymously(BuildContext context) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      User? user = userCredential.user;

      if (user != null) {
        print("Signed in anonymously with UID: ${user.uid}");

        // ✅ Navigate to HomeScreen (replace with your actual screen)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      print("Anonymous sign-in failed: $e");
    }
  }

  Future<UserCredential?> signInWithApple() async {
    if (!Platform.isIOS) {
      print("Apple Sign-In is only available on iOS.");
      return null;
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  // Get current user's username from Firebase
  Future<String?> getCurrentUserUsername() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final userRef = FirebaseDatabase.instance
          .ref(firebasepath)
          .child(user.uid)
          .child('profileDetails');

      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data['userName'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting current user username: $e');
      return null;
    }
  }

  // Get username by userId
  Future<String?> getUsernameByUserId(String userId) async {
    try {
      final userRef = FirebaseDatabase.instance
          .ref(firebasepath)
          .child(userId)
          .child('profileDetails');

      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data['userName'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting username by userId: $e');
      return null;
    }
  }

  // Get profile image URL by userId
  Future<String?> getProfileImageUrlByUserId(String userId) async {
    try {
      final userRef = FirebaseDatabase.instance
          .ref(firebasepath)
          .child(userId)
          .child('profileDetails');

      final snapshot = await userRef.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data['profileImageUrl'] as String?;
      }
      return null;
    } catch (e) {
      print('Error getting profile image URL by userId: $e');
      return null;
    }
  }
}
