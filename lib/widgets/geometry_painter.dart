import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/geometry_engine.dart';
import '../constants/geometry_constants.dart';

// lib/widgets/geometry_painter.dart
class GeometryPainter extends CustomPainter {
  final GeometryEngine engine;
  final List<GPoint> selectedPoints;
  final List<GeometricObject> selectedObjects;
  final GPoint? hoveredPoint;

  GeometryPainter({
    required this.engine,
    required this.selectedPoints,
    required this.selectedObjects,
    this.hoveredPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw lines
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = GeometryConstants.defaultStrokeWidth
      ..style = PaintingStyle.stroke;

    final selectedLinePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = GeometryConstants.defaultStrokeWidth * 2
      ..style = PaintingStyle.stroke;

    for (final line in engine.lines) {
      final isSelected = selectedObjects.contains(line);
      _drawLine(canvas, line, size, isSelected ? selectedLinePaint : linePaint);
    }

    // Draw circles
    final circlePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = GeometryConstants.defaultStrokeWidth
      ..style = PaintingStyle.stroke;

    final selectedCirclePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = GeometryConstants.defaultStrokeWidth * 2
      ..style = PaintingStyle.stroke;

    for (final circle in engine.circles) {
      final radius = circle.getRadius();
      if (radius > 0) {
        final isSelected = selectedObjects.contains(circle);
        canvas.drawCircle(
          Offset(circle.center.x, circle.center.y),
          radius,
          isSelected ? selectedCirclePaint : circlePaint,
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
      double radius = GeometryConstants.pointRadius;

      if (point == hoveredPoint) {
        paint = hoveredPointPaint;
        radius = GeometryConstants.hoveredPointRadius;
      } else if (selectedPoints.contains(point)) {
        paint = selectedPointPaint;
        radius = GeometryConstants.selectedPointRadius;
      }

      canvas.drawCircle(Offset(point.x, point.y), radius, paint);

      // Draw point name
      final textPainter = TextPainter(
        text: TextSpan(
          text: point.toString(),
          style: TextStyle(
            color: Colors.black,
            fontSize: GeometryConstants.pointNameFontSize,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          point.x + GeometryConstants.pointNameOffset,
          point.y + GeometryConstants.pointNameVerticalOffset,
        ),
      );
    }
  }

  /// Draws a line based on its type (infinite, ray, or segment)
  void _drawLine(Canvas canvas, GLine line, Size size, Paint paint) {
    if (line.points.length < 2) return;

    final endpoints = line.getDrawingEndpoints(size.width, size.height);
    if (endpoints.length < 2) return;

    canvas.drawLine(
      Offset(endpoints[0].x, endpoints[0].y),
      Offset(endpoints[1].x, endpoints[1].y),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant GeometryPainter oldDelegate) {
    return true;
  }
}
