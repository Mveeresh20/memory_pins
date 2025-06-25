import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/presentation/Pages/Login_page.dart';
import 'package:memory_pins_app/presentation/Widgets/onboarding_next_button.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/text.dart';

class Onboarding3 extends StatefulWidget {
  const Onboarding3({super.key});

  @override
  State<Onboarding3> createState() => _Onboarding3State();
}

class _Onboarding3State extends State<Onboarding3> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 2;
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

  // Page indicator widget
  Widget _buildPageIndicator() {
    List<Widget> list = [];
    for (int i = 0; i < _numPages; i++) {
      list.add(_indicator(i == _currentPage));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: list);
  }

  // Individual indicator dot
  Widget _indicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: isActive ? 10.0 : 8.0,
      width: isActive ? 10.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFCC29) : Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: isActive ? Border.all(color: Colors.black, width: 1) : null,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15212F),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skip button at the top right
            Padding(
              padding: const EdgeInsets.only(top: 25, right: 24),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    child: Text(
                      "Skip",
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Phone image with overlayed content
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Phone image with rounded corners
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image.network(
                        Images.onboarding3Img,
                        // adjust as needed
                        // adjust as needed
                        fit: BoxFit.cover,
                      ),
                    ),

                    // Gradient overlay at the bottom of the phone image
                    // ... (your existing code)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,

                      height: MediaQuery.of(context).size.height * 0.45,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(32),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFF131F2B),
                            ],

                            stops: const [0.0, 0.35],
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        bottom: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center, // Center the container horizontally
                            mainAxisSize:
                                MainAxisSize
                                    .min, // Make the Row only as wide as its children
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
                                  child:
                                      _buildPageIndicator(), // This is the Row of indicators
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            Lorempsum.onboarding3Title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            Lorempsum.onboarding3Description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunitoSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),
                          InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginPage(),
                                ),
                              );
                            },
                            child: const OnboardingNextButton(
                              text: "Continue",
                              icon: Icons.arrow_forward_sharp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:memory_pins_app/presentation/Pages/Login_page.dart';
// import 'package:memory_pins_app/presentation/Widgets/onboarding_next_button.dart';
// import 'package:memory_pins_app/utills/Constants/images.dart';
// import 'package:memory_pins_app/utills/Constants/text.dart';

// class Onboarding3 extends StatefulWidget {
//   const Onboarding3({super.key});

//   @override
//   State<Onboarding3> createState() => _Onboarding3State();
// }

// class _Onboarding3State extends State<Onboarding3> {
//   final PageController _pageController = PageController(initialPage: 0);
//   int _currentPage = 2;
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
//         borderRadius: BorderRadius.circular(12.0),
//         border: isActive ? Border.all(color: Colors.black, width: 1) : null,
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF15212F),
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(right: 24, top:20 ),
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
        
//             Expanded(
//               child: Stack(
//                 children: [
//                   // Background Image
//                   Positioned.fill(
//                     child: Image.network(Images.onboarding3Img, fit: BoxFit.cover),
//                   ),
              
//                   // Gradient Overlay
//                   Positioned.fill(
//                     child: Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           end: Alignment.bottomCenter,
//                           colors: [
//                             Color(0xFF15212F).withOpacity(0.2),
//                             Color(0xFF15212F).withOpacity(0.9),
//                           ],
//                           stops: [0.0, 0.7],
//                         ),
//                       ),
//                     ),
//                   ),
              
//                   // Main Content
//                   SafeArea(
//                     child: Column(
//                       children: [
//                         // Skip Button
//                         Spacer(flex: 12),
//                         _buildPageIndicator(),
//                         Spacer(flex: 1),
              
//                         Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 14),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Text(
//                                 Lorempsum.onboarding2Title,
//                                 textAlign: TextAlign.center,
//                                 style: GoogleFonts.poppins(
//                                   fontSize: 24,
//                                   fontWeight: FontWeight.w900,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               SizedBox(height: 12),
//                               Text(
//                                 Lorempsum.onboarding2Description,
//                                 textAlign: TextAlign.center,
//                                 style: GoogleFonts.nunitoSans(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w700,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
              
//                         Padding(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 16,
//                           ).copyWith(bottom: 62),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               SizedBox(height: 32),
//                               InkWell(
//                                 onTap: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) => Onboarding3(),
//                                     ),
//                                   );
//                                 },
//                                 child: OnboardingNextButton(
//                                   text: "Continue",
//                                   icon: Icons.arrow_forward_sharp,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

