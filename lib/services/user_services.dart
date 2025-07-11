import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static UserService? _instance;

  static UserService get instance {
    _instance ??= UserService();
    return _instance!;
  }

  // Method to get the current user's ID
  String? getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }
}
