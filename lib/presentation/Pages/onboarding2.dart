import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/presentation/Pages/Login_page.dart';
import 'package:memory_pins_app/presentation/Pages/home_screen.dart';
import 'package:memory_pins_app/presentation/Pages/onboarding3.dart';
import 'package:memory_pins_app/presentation/Widgets/onboarding_next_button.dart';
import 'package:memory_pins_app/services/navigation_service.dart';
import 'package:memory_pins_app/utills/Constants/images.dart';
import 'package:memory_pins_app/utills/Constants/text.dart';

class Onboarding2 extends StatefulWidget {
  const Onboarding2({super.key});

  @override
  State<Onboarding2> createState() => _Onboarding2State();
}

class _Onboarding2State extends State<Onboarding2> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 1;
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
    return Scaffold(
      backgroundColor: const Color(0xFF15212F),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              Images.onboarding2Img,
              fit: BoxFit.cover, // Ensures the image covers the entire screen area
            ),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent, // Top of the screen is fully transparent
                    Colors.transparent, // Keep transparent for longer
                    const Color(0xFF15212F), // Start fading to dark
                    const Color(0xFF15212F), // Solid dark at the very bottom
                  ],
                  // Adjust stops based on Figma:
                  // - 0.0 to 0.5: Transparent (shows more of the top image)
                  // - 0.5 to 0.8: Fades from transparent to dark
                  // - 0.8 to 1.0: Solid dark
                  stops: const [0.0, 0.5, 0.65, 1.0], // - Adjusted to match Figma visual more closely
                ),
              ),
            ),
          ),

          // Main Content - Overlayed on top of the gradient and image
          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Padding(
                  padding: const EdgeInsets.only(right: 24, top: 20),
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Spacers to push content down and manage image visibility
                // Adjust these 'flex' values if the text and button are not positioned correctly
                const Spacer(flex: 30), // Reduced flex to make text higher up and allow more image show
                // ... inside your Column in SafeArea ...

Row(
  mainAxisAlignment: MainAxisAlignment.center, // Center the container horizontally
  mainAxisSize: MainAxisSize.min, // Make the Row only as wide as its children
  children: [
    Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        color: const Color(0xFF1E2D2C),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: _buildPageIndicator(), // This is the Row of indicators
      ),
    ),
  ],
),



// ... rest of your Column content ...,
                const Spacer(flex: 1), // Minor spacer

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Lorempsum.onboarding2Title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        Lorempsum.onboarding2Description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunitoSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // This Spacer pushes the button to the bottom and affects the overall vertical layout
                 // Flexible spacer to take available space

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ).copyWith(bottom: 45), // Keep bottom padding for the button
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 32), // Add spacing above button
                      InkWell(
                        onTap: () {
                          NavigationService.pushNamed('/onboarding3');
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
        ],
      ),
    );
  }
}