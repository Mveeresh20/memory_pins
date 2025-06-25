import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF15212F),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
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
                      onTap: () {},
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 3,
                            color: Colors.black.withOpacity(0.2),
                          ),
                        ),
                        child: ClipOval(
                            child: Image.network(
                          Images.profilePageImg,
                          fit: BoxFit.cover,
                          height: 120,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.network(
                              Images.profilePageImg,
                              fit: BoxFit.cover,
                              height: 120,
                            );
                          },
                        )),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  
                  
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Name",
                            style: text16W600White(context),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D2B36),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              style: text14W600White(context),
                              controller: _nameController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(8),
                                hintText: "Enter your name",
                                hintStyle: text14W600White(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Email",
                            style: text16W600White(context),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D2B36),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              style: text14W600White(context),
                              controller: _emailController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(8),
                                hintText: "Enter your email",
                                hintStyle: text14W600White(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Phone Number",
                            style: text16W600White(context),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D2B36),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              style: text14W600White(context),
                              controller: _phoneController,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(8),
                                hintText: "Enter your phone number",
                                hintStyle: text14W600White(context),
                              ),
                            ),
                          )
                        ],
                      ),
                  SizedBox(height: 70),
                  Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFF5C253),
                              Color(0xFFEBA145),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: Text(
                          "Save Deatils",
                          style: GoogleFonts.nunitoSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black),
                        )),
                      ))
                  
                  
                    ],
                  ),
                ),
              )
             
            ]),
          ),
        ),
      ),
    );
  }
}
