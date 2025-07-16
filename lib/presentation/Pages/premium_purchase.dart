import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/utills/Constants/label_text_style.dart';

class PremiumPurchase extends StatefulWidget {
  const PremiumPurchase({super.key});

  @override
  State<PremiumPurchase> createState() => _PremiumPurchaseState();
}

class _PremiumPurchaseState extends State<PremiumPurchase> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return Scaffold(

      body :   Stack(
     children: [
      // Background Image (Top 65% of screen)
      Positioned(
       top: 0,
       left: 0,
       right: 0,
       height: screenSize.height * 0.65,
       child: Image.asset(
        'assets/images/premium.png', // Make sure this path is correct in your pubspec.yaml
        fit: BoxFit.cover,
       ),
      ),
      // Darker Background for the bottom part
      Positioned(
       top: screenSize.height * 0.35, // Overlap slightly with the image for a smooth transition
       left: 0,
       right: 0,
       bottom: 0,
       child: Container(
        decoration: BoxDecoration(
         gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
           Colors.black.withOpacity(0.0), // Start transparent
           const Color(0xFF1A1A2E), // Dark color similar to the screenshot
          ],
          stops: const [0.0, 0.4], // Adjust stop to control gradient fade
         ),
         color: const Color(0xFF15212F), // Solid dark color for the lower part
        ),
       ),
      ),
      // Content Overlay
      Positioned.fill(
       child: SafeArea(
        child: Column(
         children: [
          // Top Bar (Arrow Button and Subscription Text)
          Padding(
           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
           child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
             GestureDetector(
              onTap: () {
               Navigator.pop(context); // Example: Go back
              },
              child: Container(
               padding: const EdgeInsets.all(8.0),
               decoration: BoxDecoration(
                color: Color(0xFF253743), // Semi-transparent white
                borderRadius: BorderRadius.circular(8.0),
               ),
               child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
               ),
              ),
             ),
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
               color: Color(0xFF0F172A).withOpacity(0.5), // Semi-transparent white
               borderRadius: BorderRadius.circular(36.0),
               border: Border.all(color: Color(0xFF0F172A).withOpacity(0.06), width: 1),
               boxShadow: [
                BoxShadow(
                 color: Colors.black.withOpacity(0.3),
                 blurRadius: 12,
                 offset: const Offset(2, 12),
                ),
               ],
              ),
              child:  Text(
               'Subscription',
               style: text18W700White(context),
              ),
             ),
             // Placeholder for right-side elements if any
             const SizedBox(width: 40), // To balance the row with the back button
            ],
           ),
          ),
          const Spacer(), // Pushes content to the bottom
          // "Get Premium" Text
          Align(
           alignment: Alignment.center,
           child: Stack(
            children: [
             // Blurred/Silver border effect (simulated with multiple text shadows)
             Text(
      'Get Premium',
      style: GoogleFonts.montserrat(
        fontStyle: FontStyle.italic,
        fontSize: 40,
        fontWeight: FontWeight.w900,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = Colors.black,
      ),
    ),
    // Fill (yellow) + Shadow
    Text(
      'Get Premium',
      style: GoogleFonts.montserrat(
        fontStyle: FontStyle.italic,
        fontSize: 40,
        fontWeight: FontWeight.w900,
        color: Color(0xFFF5C253),
        shadows: [
          Shadow(
            blurRadius: 52.0,
            color: Colors.black.withOpacity(0.7),
            offset: Offset(0, 4),
          ),
        ],
      ),
    ),
            ],
           ),
          ),
          SizedBox(height: screenSize.height * 0.02), // Spacing
          // Key Features Text
          Padding(
           padding: const EdgeInsets.symmetric(horizontal: 24.0),
           child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
             'Key Features:',
             style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
             ),
            ),
           ),
          ),
          SizedBox(height: screenSize.height * 0.01), // Spacing
          // Feature List Container
          Padding(
           padding: const EdgeInsets.symmetric(horizontal: 24.0),
           child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
             color:Color(0xFF1E3347).withOpacity(0.4), // Slightly transparent dark
             borderRadius: BorderRadius.circular(16.0),
             boxShadow: [
              BoxShadow(
               color: Colors.black.withOpacity(0.6),
               blurRadius: 12,
               offset: const Offset(2, 12),
              ),
             ],
             
            ),
            child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
              _buildFeatureItem(
               context,
               
               '🔓 Unlimited Pin Drops',
               'Free users may have a monthly limit; premium users can drop as many pins as they want.',
              ),
              const SizedBox(height: 15),
              _buildFeatureItem(
               context,
               // Changed from mountain icon to a more common one
               '🏔️ Unlimited & Private Tapus',
               'Create as many Tapus as you want – and choose whether they\'re public, private',
              ),
             ],
            ),
           ),
          ),
          SizedBox(height: screenSize.height * 0.03), // Spacing
          // One Time Purchase Button
          Padding(
           padding: const EdgeInsets.symmetric(horizontal: 24.0),
           child: GestureDetector(
            onTap: () {
             // Handle one-time purchase
             print('One Time Purchase tapped!');
            },
            child: Container(
             padding: const EdgeInsets.symmetric(vertical: 12.0),
             decoration: BoxDecoration(
              gradient: const LinearGradient(
               colors: [
                Color(0xFF2FFA65), // Lighter green
                Color(0xFF00B02F), // Darker green
               ],
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: Color(0xFFFFFFFF).withOpacity(0.4), width: 1),
              
             ),
             child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                child: Text(
                 'One Time Purchase',
                 textAlign: TextAlign.center,
                 style: GoogleFonts.nunitoSans(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                 ),
                ),
               ),
               Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Text(
                 '\$0.99',
                 style: GoogleFonts.manrope(
                  color: Colors.black,
                  fontSize: screenSize.width * 0.08,
                  fontWeight: FontWeight.w800,
                 ),
                ),
               ),
              ],
             ),
            ),
           ),
          ),
          SizedBox(height: screenSize.height * 0.02), // Spacing
          // Upgrade Now Button
          Padding(
           padding: const EdgeInsets.symmetric(horizontal: 24.0),
           child: GestureDetector(
            onTap: () {
             // Handle upgrade now
             print('Upgrade Now tapped!');
            },
            child: Container(
             width: double.infinity,
             padding: const EdgeInsets.symmetric(vertical: 16.0),
             decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF5C253),
              Color(0xFFEBA145),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ), // Orange/Gold color
              borderRadius: BorderRadius.circular(16.0),
             
             ),
             child:  Text(
              'Upgrade Now',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
               color: Colors.black,
               fontSize: 16,
               fontWeight: FontWeight.w700,
               decoration: TextDecoration.none, // Removed underline
              ),
             ),
            ),
           ),
          ),
          SizedBox(height: screenSize.height * 0.02), // Spacing
          // Restore Purchase Text
          GestureDetector(
           onTap: () {
            // Handle restore purchase
            print('Restore Purchase tapped!');
           },
           child: Text(
            'Restore Purchase',
            style: GoogleFonts.nunitoSans(
             color: Colors.white,
             fontSize: 16,
             fontWeight: FontWeight.w700,
             decoration: TextDecoration.underline,
             decorationColor: const Color(0xFFF5C253), // Yellow underline
             decorationThickness: 2,
            ),
           ),
          ),
          SizedBox(height: screenSize.height * 0.04), // Bottom padding
         ],
        ),
       ),
      ),
     ],
    ),
   );
    
  }
}

Widget _buildFeatureItem(
    BuildContext context,  String title, String description) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      
      
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 16,
                
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
