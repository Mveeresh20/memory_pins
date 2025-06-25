import 'package:flutter/material.dart';
import 'package:memory_pins_app/presentation/Widgets/profile_option_tile.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

   int selectedTileIndex = -1;
  @override
  Widget build(BuildContext context) {
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        ClipOval(
                            child: Image.network(
                          Images.profilePageImg,
                          fit: BoxFit.cover,
                          height: 80,
                        )),
                        SizedBox(width: 8),
                        Column(
                          children: [
                            Text(
                              "John M",
                              style: text16W700White(context),
                            ),
                            Text(
                              "Johnm@gmail.com",
                              style: text12W400White(context),
                            ),
                            Text(
                              "+91 855XXXXXXX",
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
                        width: 1,
                        color:Colors.white.withOpacity(0.2)),
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
                                NavigationService.pushNamed('/edit-profile');
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
                        width: 1,
                        color:Colors.white.withOpacity(0.2)),
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
                            title: "Premium Purchase",
                            onTap: () {
                              setState(() {
                                selectedTileIndex = 2;
                              });
                            }),
                        ProfileOptionTile(
                          isSelected: selectedTileIndex == 3,
                            image: Images.restoreImg,
                            title: "Restore Purchase",
                            onTap: () {
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
                        width: 1,
                        color:Colors.white.withOpacity(0.2)),
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
                              });
                            }),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
