import 'package:flutter/material.dart';
import 'package:memory_pins_app/utills/Constants/ui.dart';

class OnboardingNextButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;

  const OnboardingNextButton({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: UI.borderRadius80,
        boxShadow: [BoxShadow(
          color: Color(0xFF9254DE).withOpacity(0.32),
      
          blurRadius: 16,
          spreadRadius: 0,





       ) ],

        gradient: LinearGradient(
          colors: [Color(0xFFF5C253), Color(0xFFEBA145)],
          begin: Alignment.bottomLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          
          
          width: 0.5, color: Color(0xFF1474DF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black,
                fontFamily: "Montserrat",
              ),
            ),
            SizedBox(width: 8),
            Icon(icon, size: 16, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
