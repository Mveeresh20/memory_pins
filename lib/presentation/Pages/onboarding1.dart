import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/presentation/Pages/Login_page.dart';
import 'package:memory_pins_app/presentation/Pages/onboarding2.dart';
import 'package:memory_pins_app/presentation/Widgets/onboarding_next_button.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/text.dart';

class Onboarding1 extends StatefulWidget {
  const Onboarding1({super.key});

  @override
  State<Onboarding1> createState() => _Onboarding1State();
}

class _Onboarding1State extends State<Onboarding1> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  final int _numPages = 3;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });
  }

  Widget _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < _numPages; i++) {
      list.add(_indicator(i == _currentPage));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: list);
  }

  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: isActive ? 10.0 : 8.0,
      width: isActive ? 10.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFCC29) : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(12.0)),
        border: isActive ? Border.all(color: Colors.black, width: 1) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF131F2B),
      body: SafeArea(
        child: SingleChildScrollView( // Added SingleChildScrollView for overflow handling
          child: Column(
            children: [
              Padding(
                // Use a percentage of screen width for horizontal padding if desired
                padding: EdgeInsets.only(right: screenWidth * 0.04, top: screenHeight * 0.03),
                child: Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                     NavigationService.pushNamed('/login');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFF1E2D3C),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Text(
                          "Skip",
                          style: GoogleFonts.nunitoSans(
                            fontSize: screenWidth * 0.04, // Dynamic font size
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.05), // Dynamic height

              // Wrap Image with Flexible or adjust its size based on screen dimensions
              Image.network(
                Images.onboarding1Img,
                fit: BoxFit.contain,
                height: screenHeight * 0.43, // Example: Image takes 40% of screen height
                 // Example: Image takes 90% of screen width
              ),
              SizedBox(height: screenHeight * 0.03), // Dynamic height

              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          color: const Color(0xFF1E2D2C),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: _buildPageIndicator(),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.04), // Dynamic height
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // Dynamic horizontal padding
                    child: Text(
                      Lorempsum.onboarding1Title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunitoSans(
                        fontSize: screenWidth * 0.06, // Dynamic font size
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // Dynamic horizontal padding
                    child: Text(
                      Lorempsum.onboarding1Description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunitoSans(
                        fontSize: screenWidth * 0.04, // Dynamic font size
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04), // Dynamic height

                  InkWell(
                    onTap: () {
                      NavigationService.pushNamed('/onboarding2');
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04), // Dynamic horizontal padding
                      child: const OnboardingNextButton(
                        text: "Get Started",
                        icon: Icons.arrow_forward_sharp,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:memory_pins_app/presentation/Pages/Login_page.dart';
// import 'package:memory_pins_app/presentation/Pages/onboarding2.dart';
// import 'package:memory_pins_app/presentation/Widgets/onboarding_next_button.dart';
// import 'package:memory_pins_app/utills/Constants/images.dart';
// import 'package:memory_pins_app/utills/Constants/text.dart';

// class Onboarding1 extends StatefulWidget {
//   const Onboarding1({super.key});

//   @override
//   State<Onboarding1> createState() => _Onboarding1State();
// }

// class _Onboarding1State extends State<Onboarding1> {
//   final PageController _pageController = PageController(initialPage: 0);
//   int _currentPage = 0;
//   final int _numPages = 3;

//   @override
//   void initState() {
//     super.initState();
//     _pageController.addListener(() {
//       setState(() {
//         _currentPage = _pageController.page?.round() ?? 0;
//       });
//     });
//   }

//   Widget _buildPageIndicator() {
//     List<Widget> list = [];
//     for (int i = 0; i < _numPages; i++) {
//       list.add(_indicator(i == _currentPage));
//     }
//     return Row(mainAxisAlignment: MainAxisAlignment.center, children: list);
//   }

//   Widget _indicator(bool isActive) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 150),
//       margin: const EdgeInsets.symmetric(horizontal: 4.0),
//       height: isActive ? 10.0 : 8.0,
//       width: isActive ? 10.0 : 8.0,
//       decoration: BoxDecoration(
//         color: isActive ? const Color(0xFFFFCC29) : Colors.white,
//         borderRadius: const BorderRadius.all(Radius.circular(12.0)),
//         border: isActive ? Border.all(color: Colors.black, width: 1) : null,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF131F2B),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(right: 16, top: 24),
//               child: Align(
//                 alignment: Alignment.topRight,
//                 child: GestureDetector(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => LoginPage()),
//                     );
//                   },
//                   child: Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       color: Color(0xFF1E2D3C),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 4,
//                         horizontal: 8,
//                       ),
//                       child: Text(
//                         "Skip",
//                         style: GoogleFonts.nunitoSans(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w700,
//                           color: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             SizedBox(height: 40),

//             Image.network(Images.onboarding1Img, fit: BoxFit.contain),
//             SizedBox(height: 30),

//             Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Row(
//                   mainAxisAlignment:
//                       MainAxisAlignment
//                           .center, // Center the container horizontally
//                   mainAxisSize:
//                       MainAxisSize
//                           .min, // Make the Row only as wide as its children
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(34),
//                         color: const Color(0xFF1E2D2C),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 6,
//                           vertical: 4,
//                         ),
//                         child:
//                             _buildPageIndicator(), // This is the Row of indicators
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 32),
//                 Text(
//                   Lorempsum.onboarding1Title,
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.nunitoSans(
//                     fontSize: 24,
//                     fontWeight: FontWeight.w900,
//                     color: Colors.white,
//                   ),
//                 ),
//                 Text(
//                   Lorempsum.onboarding1Description,
//                   textAlign: TextAlign.center,
//                   style: GoogleFonts.nunitoSans(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.white,
//                   ),
//                 ),
//                 SizedBox(height: 32),

//                 InkWell(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => Onboarding2()),
//                     );
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 16),
//                     child: OnboardingNextButton(
//                       text: "Get Started",
//                       icon: Icons.arrow_forward_sharp,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
