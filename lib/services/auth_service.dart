import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:memory_pins_app/presentation/Pages/home_screen.dart';
import 'package:memory_pins_app/presentation/Pages/onboarding3.dart';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {

  final String TABLE_NAME = '478_users';
  final String PROFILE_DETAILS_TABLE = 'profileDetails';

  final FirebaseAuth _auth = FirebaseAuth.instance;

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
          '478_users/$userId/profileDetails',
        );

        // Create initial profile details
        final profileDetails = {
          'userName':
              name ??
              email.split('@')[0], // Use part of email if name not provided
          'email': email,
          'imageProfile': '', // Empty string for default profile image
          'gender': '', // Empty string for gender
        };

        await userRef.set(profileDetails);
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Sign up error:${e.message}");
      return null;
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Sign in error: ${e.message}");
      return null;
    }
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
}
