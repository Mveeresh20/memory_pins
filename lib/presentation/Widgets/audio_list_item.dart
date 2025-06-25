import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:memory_pins_app/models/pin_detail.dart';
import 'package:memory_pins_app/presentation/Pages/pin_detail_screen.dart';
import 'package:memory_pins_app/utills/Constants/app_colors.dart';

class AudioListItem extends StatelessWidget {
  final AudioItem audio;

  const AudioListItem({Key? key, required this.audio}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        
           Container(

            decoration: BoxDecoration(
              color: AppColors.bgGroundYellow,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderColor1, width: 1),
              boxShadow: [
                AppColors.backShadow,
              ]

            ),
            child: Padding(
              padding: const EdgeInsets.all(13.0),
              child: Icon(Icons.play_arrow_rounded, color: Colors.white),
            )),

            SizedBox(width: 12),
         
        
        Expanded(
          // This will contain the waveform.
          // For a real app, this would be a custom painter or a package like flutter_sound or just_audio
          child: Container(
            height: 40, // Height of the waveform area
            // Replace this with actual waveform rendering
            decoration: BoxDecoration(
              
            ),
            child: CustomPaint(
              painter: WaveformPainter(), // Replace with a real waveform painter
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          audio.duration,
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }
}

class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Draw some sample lines to represent a waveform
    for (int i = 0; i < size.width; i += 5) {
      double height = (i % 2 == 0) ? size.height * 0.6 : size.height * 0.4;
      canvas.drawLine(Offset(i.toDouble(), size.height / 2 - height / 2),
          Offset(i.toDouble(), size.height / 2 + height / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // Only repaint if data changes
  }
}