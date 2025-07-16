import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/services/edit_profile_provider.dart';
import 'package:memory_pins_app/providers/user_provider.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/imageType.dart';
import 'package:memory_pins_app/utills/Constants/image_picker_util.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  File? _imageFile;

  @override
  void initState() {
    super.initState();
    // Delay profile loading to avoid build phase conflicts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserProfile();
    });
  }

  Future<void> _loadUserProfile() async {
    final provider = Provider.of<EditProfileProvider>(context, listen: false);
    await provider.fetchUserProfileDetails();
    setState(() {
      _nameController.text = provider.profileDetails?.userName ?? '';
      _emailController.text = provider.profileDetails?.email ?? '';
      // Add fallback for mobile number - show empty string if null
      _phoneController.text =
          provider.profileDetails?.mobileNumber ?? 'xxxxxxxxxx';
    });
  }

  Future<void> _pickImage() async {
    final provider = Provider.of<EditProfileProvider>(context, listen: false);

    ImagePickerUtil().showImageSourceSelection(
      context,
      (String imagePath) async {
        // Success callback
        await provider.updateUserProfile(imagePath, context);
        setState(() {
          _imageFile =
              null; // Clear local file since we're using the uploaded path
        });
      },
      (String error) {
        // Error callback
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      },
      imageType: ImageType.profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF15212F),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
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
                          width: 1, color: Color(0xFF0F172A).withOpacity(0.06)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 50),
                    child: Text(
                      "Edit Profile",
                      textAlign: TextAlign.center,
                      style: text18W700White(context),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      _pickImage();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          width: 3,
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      child: ClipOval(
                        child: Consumer<EditProfileProvider>(
                          builder: (context, provider, child) {
                            final imageUrl = provider.getProfileImageUrl();
                            return Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              height: 80,
                              width: 80,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.network(
                                  Images.profile,
                                  color: Colors.black12,
                                  fit: BoxFit.cover,
                                  height: 80,
                                  width: 80,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFCC29),
                        shape: BoxShape.circle,
                      ),
                      child: Image.network(
                        Images.editImg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Color(0xFF1D2B36),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16)
                    .copyWith(top: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Name",
                            style: text16W600White(context),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            style: text14W600White(context),
                            controller: _nameController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF1D2B36),
                              contentPadding: EdgeInsets.all(16),
                              hintText: "Enter your name",
                              hintStyle: text14W600White(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFFDAA520),
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFFDAA520),
                                  width: 1,
                                ),
                              ),
                              errorStyle: TextStyle(color: Color(0xFFDAA520)),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Email",
                            style: text16W600White(context),
                          ),
                          const SizedBox(height: 8),
                          Consumer<UserProvider>(
                            builder: (context, userProvider, child) {
                              final isGuest = userProvider.isAnonymous ?? false;
                              return TextFormField(
                                style: text14W600White(context),
                                controller: _emailController,
                                enabled:
                                    isGuest, // Enable email editing only for guest users
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFF1D2B36),
                                  contentPadding: EdgeInsets.all(16),
                                  hintText: isGuest
                                      ? "Enter your email"
                                      : "Email (cannot be changed)",
                                  hintStyle: text14W600White(context),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDAA520),
                                      width: 1,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Color(0xFFDAA520),
                                      width: 1,
                                    ),
                                  ),
                                  errorStyle:
                                      TextStyle(color: Color(0xFFDAA520)),
                                  // Add disabled state styling
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.white.withOpacity(0.1),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  const pattern =
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                                  final regex = RegExp(pattern);
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter an email';
                                  }
                                  if (!regex.hasMatch(value)) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Phone Number",
                            style: text16W600White(context),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            style: text14W600White(context),
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFF1D2B36),
                              contentPadding: EdgeInsets.all(16),
                              hintText: "Enter your phone number",
                              hintStyle: text14W600White(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFFDAA520),
                                  width: 1,
                                ),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFFDAA520),
                                  width: 1,
                                ),
                              ),
                              errorStyle: TextStyle(color: Color(0xFFDAA520)),
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';

                              if (trimmed.isEmpty) {
                                return 'Please enter a contact number';
                              }

                              if (trimmed.length != 10) {
                                return 'Mobile number must be 10 digits';
                              }

                              final phoneRegExp = RegExp(r'^[6-9]\d{9}$');
                              if (!phoneRegExp.hasMatch(trimmed)) {
                                return 'Enter a valid 10-digit mobile number';
                              }

                              return null;
                            },
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(
                                  10), // ⛔ Max 10 digits
                            ],
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 70),

                    Container(
                      width: double.infinity,
                      child: Consumer<EditProfileProvider>(
                        builder: (context, provider, child) {
                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFCC29),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(60),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: provider.isLoading
                                ? null
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      await provider.updateUserNameAndEmail(
                                        _nameController.text,
                                        _emailController.text,
                                        _phoneController.text,
                                        context,
                                      );
                                    }
                                  },
                            child: provider.isLoading
                                ? CircularProgressIndicator()
                                : Center(
                                    child: Text(
                                      "Update Details",
                                      style: GoogleFonts.nunitoSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),

                    // Container(
                    //     width: double.infinity,
                    //     decoration: BoxDecoration(
                    //         borderRadius: BorderRadius.circular(12),
                    //         gradient: LinearGradient(
                    //           colors: [
                    //             Color(0xFFF5C253),
                    //             Color(0xFFEBA145),
                    //           ],
                    //           begin: Alignment.topLeft,
                    //           end: Alignment.bottomRight,
                    //         )),
                    //     child: Padding(
                    //       padding: const EdgeInsets.symmetric(vertical: 16),
                    //       child: Center(
                    //           child: Text(
                    //         "Save Deatils",
                    //         style: GoogleFonts.nunitoSans(
                    //             fontSize: 18,
                    //             fontWeight: FontWeight.w700,
                    //             color: Colors.black),
                    //       )),
                    //     ))
                  ],
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
