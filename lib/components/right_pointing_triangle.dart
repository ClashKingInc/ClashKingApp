import 'package:flutter/material.dart';

class RightPointingTriangle extends StatelessWidget {
  final Color color;
  final double height;
  final double width;

  const RightPointingTriangle({
    super.key,
    this.color = Colors.black,
    this.height = 50.0, // Default height for the triangle
    this.width = 50.0, // Default width for the triangle
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height), // Size of the triangle
      painter: _RightPointingTrianglePainter(color: color),
    );
  }
}

class _RightPointingTrianglePainter extends CustomPainter {
  final Color color;

  _RightPointingTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path()
      ..moveTo(0, 0) // Top left corner
      ..lineTo(size.width, size.height / 2) // Middle right corner
      ..lineTo(0, size.height) // Bottom left corner
      ..close(); // Automatically draws a line to the start point to close the path

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
