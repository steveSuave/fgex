// lib/models/circle.dart
import 'dart:math' as math;
import 'geometric_object.dart';
import 'point.dart';

enum CircleType {
  pointBased, // Point circle - center + point on circle (formerly PCIRCLE = 0)
  radius, // Radius circle (formerly RCIRCLE = 1)
  special, // Special circle (formerly SCIRCLE = 2)
  threePoint, // Circle through three points
}

class GCircle extends GeometricObject {
  CircleType circleType;
  GPoint center;
  List<GPoint> points;

  GCircle(this.center, {this.circleType = CircleType.pointBased, int? id})
    : points = [],
      super(GeometricObjectType.circle, id: id);

  GCircle.withPoint(
    this.center,
    GPoint pointOnCircle, {
    this.circleType = CircleType.pointBased,
    int? id,
  }) : points = [pointOnCircle],
       super(GeometricObjectType.circle, id: id);

  GCircle.threePoint(this.center, List<GPoint> threePoints, {int? id})
    : points = List.from(threePoints),
      circleType = CircleType.threePoint,
      super(GeometricObjectType.circle, id: id);

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
    return 'Circle $center';
  }

  @override
  String toString() => name ?? getDescription();
}
