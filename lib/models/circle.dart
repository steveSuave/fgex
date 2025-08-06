// lib/models/circle.dart
import 'dart:math' as math;
import 'geometric_object.dart';
import 'point.dart';

class GCircle extends GeometricObject {
  static const int PCIRCLE = 0; // Point circle (center + point on circle)
  static const int RCIRCLE = 1; // Radius circle  
  static const int SCIRCLE = 2; // Special circle
  
  int circleType;
  GPoint center;
  List<GPoint> points;
  
  GCircle(this.center, {this.circleType = PCIRCLE}) 
    : points = [],
      super(GeometricObject.CIRCLE);
  
  GCircle.withPoint(this.center, GPoint pointOnCircle, {this.circleType = PCIRCLE}) 
    : points = [pointOnCircle],
      super(GeometricObject.CIRCLE);
  
  void addPoint(GPoint point) {
    if (!points.contains(point)) {
      points.add(point);
    }
  }
  
  double getRadius() {
    if (points.isEmpty) return 0;
    var radiusPoint = points.first;
    var dx = center.x - radiusPoint.x;
    var dy = center.y - radiusPoint.y;
    return math.sqrt(dx * dx + dy * dy);
  }
  
  bool isPointOnCircle(GPoint point) {
    return points.contains(point);
  }
  
  String getDescription() {
    return 'Circle ${center}';
  }
  
  @override
  String toString() => name ?? getDescription();
}
