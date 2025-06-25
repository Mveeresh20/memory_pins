// lib/presentation/Widgets/dotted_circle_painter.dart

import 'package:flutter/material.dart';
import 'dart:ui'; // For PathMetric and PathMetricIterator

class DottedCirclePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double dashLength;
  final double gapLength;
  final double strokeWidth;
  final Color color;

  DottedCirclePainter({
    required this.center,
    required this.radius,
    this.dashLength = 10,
    this.gapLength = 5,
    this.strokeWidth = 1,
    this.color = Colors.black,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0) return; // Avoid drawing invalid circles

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // CORRECTED LINES HERE:
    final Path path = Path(); // 1. Create the Path object
    path.addOval(Rect.fromCircle(center: center, radius: radius)); // 2. Add the oval to the path


    Path drawPath = Path();
    for (PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        drawPath.addPath(
          metric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }
    canvas.drawPath(drawPath, paint);
  }

  @override
  bool shouldRepaint(covariant DottedCirclePainter oldDelegate) {
    return oldDelegate.center != center ||
        oldDelegate.radius != radius ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.gapLength != gapLength ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.color != color;
  }
}