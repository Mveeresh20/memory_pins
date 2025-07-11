import 'package:firebase_auth/firebase_auth.dart';


class ProfileDetails {
  String? userName;
  String? email;
  
  String? imageProfile;
  String? mobileNumber;

  ProfileDetails({
    this.userName,
    this.email,
    
    this.imageProfile,
    this.mobileNumber,
  });

 
  ProfileDetails.fromMap(Map<String, dynamic> map) {
    userName = map['userName'];
    email = map['email'];
    
    imageProfile = map['imageProfile'];
    mobileNumber = map['mobileNumber'];
  }

 
  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'email': email,
      
      'imageProfile': imageProfile,
      'mobileNumber': mobileNumber,
    };
  }
}

// 2. UserService Class

