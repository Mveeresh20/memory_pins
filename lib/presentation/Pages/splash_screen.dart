import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  void _initializeApp() async {
    // Wait for 2 seconds before checking user authentication
    Timer(const Duration(seconds: 2), () {
      _checkUserAuthenticationAndNavigate();
    });
  }

  void _checkUserAuthenticationAndNavigate() async {
    try {
      // Check if Firebase user is logged in
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (mounted) {
        if (currentUser != null) {
          // User is logged in, navigate to home screen
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // User is not logged in, navigate to onboarding
          Navigator.pushReplacementNamed(context, '/onboarding1');
        }
      }
    } catch (e) {
      print('Error checking authentication: $e');
      // In case of error, navigate to onboarding
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding1');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3.0,
        ),
      ),
    );
  }
}
