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
  double distanceToPoint(GPoint point) {
    final closestPoint = getClosestPoint(point);
    return closestPoint.distanceTo(point);
  }

  @override
  GPoint getClosestPoint(GPoint toPoint) {
    final radius = getRadius();
    if (radius <= 1e-10) {
      return center; // Treat as a point if radius is zero/negligible
    }

    final double distFromCenter = center.distanceTo(toPoint);
    if (distFromCenter <= 1e-10) {
      // If the point is at the center, any point on the circumference is equally close.
      // We can pick one based on the first defining point or an arbitrary vector.
      if (points.isNotEmpty) {
        return points.first;
      } else {
        return GPoint.withCoordinates(center.x + radius, center.y);
      }
    }

    // Vector from center to the point
    final dx = toPoint.x - center.x;
    final dy = toPoint.y - center.y;

    // Scale this vector to the radius length
    final scale = radius / distFromCenter;
    final closestX = center.x + dx * scale;
    final closestY = center.y + dy * scale;

    return GPoint.withCoordinates(closestX, closestY);
  }

  @override
  String toString() => name ?? getDescription();
}
