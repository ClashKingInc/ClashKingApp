import 'package:flutter/material.dart';

class LeftPointingTriangle extends StatelessWidget {
  final Color color;
  final double height;
  final double width;

  const LeftPointingTriangle({
    Key? key,
    this.color = Colors.black,
    this.height = 50.0, // Default height for the triangle
    this.width = 50.0, // Default width for the triangle
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height), // Size of the triangle
      painter: _LeftPointingTrianglePainter(color: color),
    );
  }
}

class _LeftPointingTrianglePainter extends CustomPainter {
  final Color color;

  _LeftPointingTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path()
      ..moveTo(size.width, 0) // Top right corner
      ..lineTo(0, size.height / 2) // Middle left corner
      ..lineTo(size.width, size.height) // Bottom right corner
      ..close(); // Automatically draws a line to the start point to close the path
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
