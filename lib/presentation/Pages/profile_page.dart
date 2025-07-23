import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memory_pins_app/presentation/Widgets/profile_option_tile.dart';
import 'package:memory_pins_app/services/auth_service.dart';
import 'package:memory_pins_app/services/edit_profile_provider.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/services/inapppurchase_provider.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<EditProfileProvider>(
        context,
        listen: false,
      ).fetchUserProfileDetails(),
    );
  }

  File? _imageFile;

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery, // Or ImageSource.camera
      imageQuality: 85,
    );

    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
      });
    }
  }

  int selectedTileIndex = -1;
  @override
  Widget build(BuildContext context) {
    return Consumer<EditProfileProvider>(
      builder: (context, profileProvider, child) {
        final userName = profileProvider.profileDetails?.userName ?? "User";
        final email = profileProvider.profileDetails?.email ?? "Email";
        final userImage = profileProvider.profilePicture ?? Images.noprofileImg;
        final mobileNumber =
            profileProvider.profileDetails?.mobileNumber ?? "xxxxxxxxxx";

        // final userImage = profileProvider.getProfileImageUrl();

        return Scaffold(
          backgroundColor: Color(0xFF131F2B),
          body: SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                ).copyWith(top: 16),
                child: Column(
                  spacing: 22,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                NavigationService.pop();
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.frameBgColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(15),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Color(0xFF0F172A).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF0F172A).withOpacity(0.24),
                                blurRadius: 16,
                                offset: Offset(2, 12),
                              )
                            ],
                            border: Border.all(
                                width: 1,
                                color: Color(0xFF0F172A).withOpacity(0.06)),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 70),
                          child: Text(
                            "Profile",
                            textAlign: TextAlign.center,
                            style: text18W700White(context),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.frameBgColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            ClipOval(
                              child: Consumer<EditProfileProvider>(
                                builder: (context, provider, child) {
                                  final imageUrl =
                                      provider.getProfileImageUrl();
                                  return CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    height: 80,
                                    width: 80,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // ClipOval(
                            //     child: Image.network(
                            //   Images.profilePageImg,
                            //   fit: BoxFit.cover,
                            //   height: 80,
                            // )),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: text16W700White(context),
                                ),
                                Text(
                                  email,
                                  // profileProvider.profileDetails?.email ?? "",
                                  style: text12W400White(context),
                                ),
                                Text(
                                  mobileNumber,
                                  style: text12W400White(context),
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.frameBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            width: 1, color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Text(
                              "Profile",
                              style: text16W600White(context),
                            ),
                            ProfileOptionTile(
                                isSelected: selectedTileIndex == 0,
                                image: Images.editImg,
                                title: "Edit Profile",
                                onTap: () {
                                  setState(() {
                                    NavigationService.pushNamed(
                                        '/edit-profile');
                                    selectedTileIndex = 0;
                                  });
                                }),
                            ProfileOptionTile(
                                isSelected: selectedTileIndex == 1,
                                image: Images.editImg,
                                title: "Saved Pins",
                                onTap: () {
                                  NavigationService.pushNamed('/saved-pins');
                                  setState(() {
                                    selectedTileIndex = 1;
                                  });
                                }),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.frameBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            width: 1, color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Text(
                              "Your Subscription",
                              style: text16W600White(context),
                            ),
                            ProfileOptionTile(
                                isSelected: selectedTileIndex == 2,
                                image: Images.subscriptionImg,
                                title: "Upgrade to premium",
                                onTap: () {
                                  setState(() {
                                    selectedTileIndex = 2;
                                    NavigationService.pushNamed(
                                        '/premium-purchase');
                                  });
                                }),
                            ProfileOptionTile(
                                isSelected: selectedTileIndex == 3,
                                image: Images.restoreImg,
                                title: "Restore Purchase",
                                onTap: () async {
                                  final purchaseProvider =
                                      Provider.of<PurchaseProvider>(context,
                                          listen: false);
                                  if (purchaseProvider.products.isNotEmpty) {
                                    await purchaseProvider.restoreItem();
                                  }
                                  setState(() {
                                    selectedTileIndex = 3;
                                  });
                                }),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.frameBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            width: 1, color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 8,
                          children: [
                            Text(
                              "Account",
                              style: text16W600White(context),
                            ),
                            ProfileOptionTile(
                                isSelected: selectedTileIndex == 4,
                                showArrow: false,
                                image: Images.logoutImg,
                                title: "Logout",
                                onTap: () {
                                  setState(() {
                                    selectedTileIndex = 4;
                                    showLogoutDialog(context);
                                  });
                                }),
                            ProfileOptionTile(
                                isSelected: selectedTileIndex == 5,
                                showArrow: false,
                                image: Images.deleteImg,
                                title: "Delete Account",
                                onTap: () {
                                  setState(() {
                                    selectedTileIndex = 5;
                                    showDeleteAccountDialog(context);
                                  });
                                }),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 270,
            height: 122.5,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2730),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Title and subtitle
                Padding(
                  padding: const EdgeInsets.only(
                    top: 18,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 238,
                        child: Text(
                          "Logout",
                          style: const TextStyle(
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w600,
                            fontSize: 17,
                            height: 22 / 17,
                            letterSpacing: -0.41,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 238,
                        child: Text(
                          "Are you sure you want to log out?",
                          style: const TextStyle(
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            height: 18 / 13,
                            letterSpacing: -0.08,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Buttons
                Row(
                  children: [
                    // Not Now
                    SizedBox(
                      width: 134.75,
                      height: 44,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 8,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(14),
                            ),
                          ),
                          foregroundColor: const Color(0xFF007AFF),
                          backgroundColor: Colors.transparent,
                          textStyle: const TextStyle(
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                            fontSize: 17,
                            letterSpacing: -0.41,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text("Not Now"),
                      ),
                    ),
                    // Yes
                    SizedBox(
                      width: 134.75,
                      height: 44,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 11,
                            horizontal: 8,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(14),
                            ),
                          ),
                          foregroundColor: const Color(0xFFF23943),
                          backgroundColor: Colors.transparent,
                          textStyle: const TextStyle(
                            fontFamily: "Roboto",
                            fontWeight: FontWeight.w400,
                            fontSize: 17,
                            letterSpacing: -0.41,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await AuthService.performLogout(context);
                        },
                        child: const Text("Yes"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showDeleteAccountDialog(BuildContext context) {
    final TextEditingController passwordController = TextEditingController();
    bool showPasswordField = false;
    bool isLoading = false;
    String? errorText;

    void deleteAccount() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        // Clear image cache before deleting account
        await Provider.of<EditProfileProvider>(
          context,
          listen: false,
        ).clearCacheOnUserSwitch();

        // Remove user data from Realtime Database
        final userId = user.uid;
        await FirebaseDatabase.instance
            .ref(AuthService().firebasepath)
            .child(userId)
            .remove();
        // Delete user from Auth
        await user.delete();
        Navigator.of(context).pop();
        if (context.mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // Show password field for re-authentication
          showPasswordField = true;
          errorText = "Please re-enter your password to delete your account.";
        } else {
          errorText = e.message;
        }
        setState(() {});
      } catch (e) {
        errorText = e.toString();
        setState(() {});
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 270,
                height: showPasswordField ? 210 : 140.5,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2730),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Title and subtitle
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 18,
                        left: 16,
                        right: 16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 238,
                            child: Text(
                              "Delete Account",
                              style: const TextStyle(
                                fontFamily: "Roboto",
                                fontWeight: FontWeight.w600,
                                fontSize: 17,
                                height: 22 / 17,
                                letterSpacing: -0.41,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            width: 238,
                            child: Text(
                              "Are you sure you want to delete your account?",
                              style: const TextStyle(
                                fontFamily: "Roboto",
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                                height: 18 / 13,
                                letterSpacing: -0.08,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (showPasswordField) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: passwordController,
                              obscureText: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Enter your password",
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF232B34),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                          if (errorText != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              errorText!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Buttons
                    Row(
                      children: [
                        // Not Now
                        SizedBox(
                          width: 134.75,
                          height: 44,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 11,
                                horizontal: 8,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(14),
                                ),
                              ),
                              foregroundColor: const Color(0xFF007AFF),
                              backgroundColor: Colors.transparent,
                              textStyle: const TextStyle(
                                fontFamily: "Roboto",
                                fontWeight: FontWeight.w400,
                                fontSize: 17,
                                letterSpacing: -0.41,
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Not Now"),
                          ),
                        ),
                        // Yes
                        SizedBox(
                          width: 134.75,
                          height: 44,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 11,
                                horizontal: 8,
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(14),
                                ),
                              ),
                              foregroundColor: const Color(0xFFF23943),
                              backgroundColor: Colors.transparent,
                              textStyle: const TextStyle(
                                fontFamily: "Roboto",
                                fontWeight: FontWeight.w400,
                                fontSize: 17,
                                letterSpacing: -0.41,
                              ),
                            ),
                            onPressed: () async {
                              if (showPasswordField) {
                                setState(() => isLoading = true);
                                try {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  final email = user?.email;
                                  final cred = EmailAuthProvider.credential(
                                    email: email!,
                                    password: passwordController.text,
                                  );
                                  await user!.reauthenticateWithCredential(
                                    cred,
                                  );
                                  setState(() {
                                    showPasswordField = false;
                                    errorText = null;
                                  });
                                  deleteAccount();
                                } on FirebaseAuthException catch (e) {
                                  setState(() {
                                    errorText = e.message ??
                                        "Re-authentication failed.";
                                    isLoading = false;
                                  });
                                }
                              } else {
                                setState(() => isLoading = true);
                                deleteAccount();
                              }
                            },
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFFF23943),
                                    ),
                                  )
                                : const Text("Yes"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
