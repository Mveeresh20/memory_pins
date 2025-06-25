import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_pins_app/utills/Constants/ui.dart';

class SignInButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final bool iconFirst;
  final bool isWhiteBackground;

  const SignInButton({
    super.key,
    required this.text,
    required this.icon,
    this.iconFirst = false,
    this.isWhiteBackground=false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: UI.borderRadius16,
        color: isWhiteBackground? Colors.white:null,

        gradient: isWhiteBackground?null:
        LinearGradient(
          colors: [Color(0xFFF5C253), Color(0xFFEBA145)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              iconFirst
                  ? [
                    Icon(icon, size: 22, color: Colors.black),
                    SizedBox(width: 8),
                    Text(
                      text,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ]
                  : [
                    Text(
                      text,
                      style: GoogleFonts.nunitoSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(icon, size: 18, color: Colors.black),
                  ],
        ),
      ),
    );
  }
}
