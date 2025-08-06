import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/geometry_engine.dart';

// lib/widgets/geometry_painter.dart
class GeometryPainter extends CustomPainter {
  final GeometryEngine engine;
  final List<GPoint> selectedPoints;
  final GPoint? hoveredPoint;

  GeometryPainter({
    required this.engine,
    required this.selectedPoints,
    this.hoveredPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw lines
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final line in engine.lines) {
      if (line.points.length >= 2) {
        final p1 = line.points[0];
        final p2 = line.points[1];
        canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), linePaint);
      }
    }

    // Draw circles
    final circlePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final circle in engine.circles) {
      final radius = circle.getRadius();
      if (radius > 0) {
        canvas.drawCircle(
          Offset(circle.center.x, circle.center.y),
          radius,
          circlePaint,
        );
      }
    }

    // Draw points
    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final selectedPointPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final hoveredPointPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    for (final point in engine.points) {
      Paint paint = pointPaint;
      double radius = 3;

      if (point == hoveredPoint) {
        paint = hoveredPointPaint;
        radius = 4;
      } else if (selectedPoints.contains(point)) {
        paint = selectedPointPaint;
        radius = 4;
      }

      canvas.drawCircle(Offset(point.x, point.y), radius, paint);

      // Draw point name
      final textPainter = TextPainter(
        text: TextSpan(
          text: point.toString(),
          style: TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(point.x + 8, point.y - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
