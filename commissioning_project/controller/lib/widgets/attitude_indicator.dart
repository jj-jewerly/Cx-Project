import 'dart:math';

import 'package:flutter/material.dart';

class AttitudeIndicator extends StatelessWidget {
  final double roll;
  final double pitch;
  final double size;

  const AttitudeIndicator({
    super.key,
    required this.roll,
    required this.pitch,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AttitudePainter(
          roll: roll,
          pitch: pitch,
          skyColor: const Color(0xFF4A90D9),
          groundColor: const Color(0xFF8B6914),
          lineColor: Colors.white,
        ),
      ),
    );
  }
}

class _AttitudePainter extends CustomPainter {
  final double roll;
  final double pitch;
  final Color skyColor;
  final Color groundColor;
  final Color lineColor;

  _AttitudePainter({
    required this.roll,
    required this.pitch,
    required this.skyColor,
    required this.groundColor,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Clip to circle
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: radius)));

    // Rotate canvas by roll
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-roll * pi / 180);

    // Pitch offset (pixels per degree)
    final pitchOffset = pitch * (radius / 30);

    // Sky
    canvas.drawRect(
      Rect.fromLTWH(-radius * 2, -radius * 2 + pitchOffset, radius * 4, radius * 2),
      Paint()..color = skyColor,
    );

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(-radius * 2, pitchOffset, radius * 4, radius * 2),
      Paint()..color = groundColor,
    );

    // Horizon line
    canvas.drawLine(
      Offset(-radius * 2, pitchOffset),
      Offset(radius * 2, pitchOffset),
      Paint()
        ..color = lineColor
        ..strokeWidth = 2,
    );

    // Pitch ladder lines
    final ladderPaint = Paint()
      ..color = lineColor.withAlpha(150)
      ..strokeWidth = 1;

    for (final deg in [10, 20, -10, -20]) {
      final y = pitchOffset - deg * (radius / 30);
      final halfWidth = radius * (deg.abs() == 10 ? 0.25 : 0.35);
      canvas.drawLine(Offset(-halfWidth, y), Offset(halfWidth, y), ladderPaint);
    }

    canvas.restore(); // roll rotation

    // Fixed aircraft reference (center crosshair)
    final refPaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Left wing
    canvas.drawLine(
      Offset(center.dx - radius * 0.4, center.dy),
      Offset(center.dx - radius * 0.15, center.dy),
      refPaint,
    );
    // Right wing
    canvas.drawLine(
      Offset(center.dx + radius * 0.15, center.dy),
      Offset(center.dx + radius * 0.4, center.dy),
      refPaint,
    );
    // Center dot
    canvas.drawCircle(center, 4, Paint()..color = Colors.yellow);

    // Roll indicator arc at top
    final arcPaint = Paint()
      ..color = lineColor.withAlpha(120)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.85),
      -pi * 0.83,
      pi * 0.66,
      false,
      arcPaint,
    );

    // Roll pointer triangle
    final rollRad = -roll * pi / 180;
    final pointerTip = Offset(
      center.dx + sin(rollRad) * radius * 0.85,
      center.dy - cos(rollRad) * radius * 0.85,
    );
    final pointerBase1 = Offset(
      center.dx + sin(rollRad - 0.08) * radius * 0.92,
      center.dy - cos(rollRad - 0.08) * radius * 0.92,
    );
    final pointerBase2 = Offset(
      center.dx + sin(rollRad + 0.08) * radius * 0.92,
      center.dy - cos(rollRad + 0.08) * radius * 0.92,
    );

    canvas.drawPath(
      Path()
        ..moveTo(pointerTip.dx, pointerTip.dy)
        ..lineTo(pointerBase1.dx, pointerBase1.dy)
        ..lineTo(pointerBase2.dx, pointerBase2.dy)
        ..close(),
      Paint()..color = Colors.white,
    );

    canvas.restore(); // clip

    // Outer ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey.shade700
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _AttitudePainter oldDelegate) {
    return roll != oldDelegate.roll || pitch != oldDelegate.pitch;
  }
}
