import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:memory_pins_app/services/auth_service.dart';
import 'package:memory_pins_app/services/firebase_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();

  // State variables
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  // Getters
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _currentUser?.uid;

  // Initialize provider
  Future<void> initialize() async {
    await _checkAuthState();
  }

  // Check authentication state
  Future<void> _checkAuthState() async {
    try {
      _currentUser = FirebaseAuth.instance.currentUser;
      _isAuthenticated = _currentUser != null;

      if (_isAuthenticated) {
        await _loadUserProfile();
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to check auth state: $e';
      notifyListeners();
    }
  }

  // Load user profile from Firebase
  Future<void> _loadUserProfile() async {
    try {
      if (_currentUser == null) return;

      // You'll need to implement getUserProfile in FirebaseService
      // _userProfile = await _firebaseService.getUserProfile(_currentUser!.uid);

      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user profile: $e';
      notifyListeners();
    }
  }

  // Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _authService.signUp(email, password, name: name);

      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        await _loadUserProfile();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Sign up failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Sign up error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final user = await _authService.signIn(email, password);

      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        await _loadUserProfile();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Sign in failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Sign in error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in anonymously
  Future<bool> signInAnonymously() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Use Firebase Auth directly instead of the service method that requires context
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      _currentUser = userCredential.user;
      _isAuthenticated = _currentUser != null;

      _isLoading = false;
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      _error = 'Anonymous sign in error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final credential = await _authService.signInWithApple();

      if (credential != null) {
        _currentUser = credential.user;
        _isAuthenticated = _currentUser != null;
        await _loadUserProfile();

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Apple sign in failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Apple sign in error: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await FirebaseAuth.instance.signOut();

      _currentUser = null;
      _userProfile = null;
      _isAuthenticated = false;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Sign out error: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? profileImage,
    String? gender,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_currentUser == null) {
        _error = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // You'll need to implement updateUserProfile in FirebaseService
      // await _firebaseService.updateUserProfile(
      //   _currentUser!.uid,
      //   name: name,
      //   profileImage: profileImage,
      //   gender: gender,
      // );

      // Reload user profile
      await _loadUserProfile();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get user statistics
  Map<String, dynamic> getUserStatistics() {
    // You'll need to implement this based on your data structure
    return {
      'totalPins': 0, // Calculate from user's pins
      'totalTapus': 0, // Calculate from user's tapus
      'totalSavedPins': 0, // Calculate from saved pins
      'totalViews': 0, // Calculate from user's pins
      'joinDate': _currentUser?.metadata.creationTime?.toIso8601String() ?? '',
    };
  }

  // Check if user has completed onboarding
  bool get hasCompletedOnboarding {
    // You'll need to implement this based on your onboarding logic
    return _userProfile?['hasCompletedOnboarding'] ?? false;
  }

  // Mark onboarding as completed
  Future<void> markOnboardingCompleted() async {
    try {
      if (_currentUser != null) {
        // You'll need to implement this in FirebaseService
        // await _firebaseService.updateUserProfile(
        //   _currentUser!.uid,
        //   hasCompletedOnboarding: true,
        // );

        await _loadUserProfile();
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to mark onboarding completed: $e';
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get user display name
  String get displayName {
    return _userProfile?['userName'] ??
        _currentUser?.displayName ??
        _currentUser?.email?.split('@')[0] ??
        'User';
  }

  // Get user email
  String get email {
    return _currentUser?.email ?? '';
  }

  // Get user profile image
  String get profileImage {
    return _userProfile?['imageProfile'] ?? '';
  }

  // Get user gender
  String get gender {
    return _userProfile?['gender'] ?? '';
  }

  // Check if user is anonymous
  bool get isAnonymous {
    return _currentUser?.isAnonymous ?? false;
  }

  // Get user creation date
  DateTime? get creationDate {
    return _currentUser?.metadata.creationTime;
  }

  // Get user last sign in date
  DateTime? get lastSignInDate {
    return _currentUser?.metadata.lastSignInTime;
  }

  // Clear user data (for logout)
  void clearUserData() {
    print('UserProvider - Clearing user data...');

    _currentUser = null;
    _userProfile = null;
    _isLoading = false;
    _error = null;
    _isAuthenticated = false;

    print('UserProvider - User data cleared successfully');
    notifyListeners();
  }
}
