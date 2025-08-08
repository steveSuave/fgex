// lib/services/intersection_calculator.dart
import 'dart:math' as math;
import '../models/models.dart';
import '../constants/geometry_constants.dart';
import '../exceptions/geometry_exceptions.dart';

/// Calculates intersections between geometric objects
class IntersectionCalculator {
  /// Calculates intersection point between two lines
  GPoint? calculateLineLineIntersection(GLine line1, GLine line2) {
    if (line1.points.length < 2) {
      throw InvalidConstructionException(
        'Line ${line1.name ?? line1.id} must have at least 2 points for intersection calculation',
      );
    }
    if (line2.points.length < 2) {
      throw InvalidConstructionException(
        'Line ${line2.name ?? line2.id} must have at least 2 points for intersection calculation',
      );
    }

    final p1 = line1.points[0];
    final p2 = line1.points[1];
    final p3 = line2.points[0];
    final p4 = line2.points[1];

    // Calculate intersection using determinants
    final denom = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
    if (denom.abs() < GeometryConstants.parallelLinesTolerance) {
      return null; // Parallel or coincident lines - no unique intersection
    }

    if (!denom.isFinite) {
      throw IntersectionCalculationException(
        'Invalid line parameters resulted in non-finite denominator',
      );
    }

    final t1 =
        ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) / denom;
    final t2 =
        -((p1.x - p2.x) * (p1.y - p3.y) - (p1.y - p2.y) * (p1.x - p3.x)) /
        denom;

    final intersectionX = p1.x + t1 * (p2.x - p1.x);
    final intersectionY = p1.y + t1 * (p2.y - p1.y);

    // Check if intersection is valid for each line type
    if (!_isIntersectionValidForLine(line1, t1) ||
        !_isIntersectionValidForLine(line2, t2)) {
      return null;
    }

    return GPoint.withCoordinates(intersectionX, intersectionY);
  }

  /// Check if intersection parameter t is valid for the given line type
  bool _isIntersectionValidForLine(GLine line, double t) {
    switch (line.variant) {
      case LineVariant.infinite:
        return true; // Infinite lines accept any intersection
      case LineVariant.ray:
        return t >= 0; // Rays only accept positive direction
      case LineVariant.segment:
        return t >= 0 &&
            t <= 1; // Segments only accept points between endpoints
    }
  }

  /// Calculates intersection points between a line and a circle
  List<GPoint> calculateLineCircleIntersections(GLine line, GCircle circle) {
    if (line.points.length < 2) {
      throw InvalidConstructionException(
        'Line ${line.name ?? line.id} must have at least 2 points for intersection calculation',
      );
    }

    final p1 = line.points[0];
    final p2 = line.points[1];
    final center = circle.center;
    final radius = circle.getRadius();

    if (radius <= 0) {
      throw InvalidGeometricObjectException(
        'Circle ${circle.name ?? circle.id} must have positive radius for intersection calculation',
      );
    }

    if (!radius.isFinite) {
      throw InvalidGeometricObjectException(
        'Circle ${circle.name ?? circle.id} has invalid radius: $radius',
      );
    }

    // Line direction vector
    var dx = p2.x - p1.x;
    var dy = p2.y - p1.y;
    final length = math.sqrt(dx * dx + dy * dy);

    if (length == 0) {
      throw InvalidConstructionException(
        'Line points are identical - cannot calculate direction',
      );
    }

    // Normalize direction vector
    dx /= length;
    dy /= length;

    // Vector from line start to circle center
    final fx = center.x - p1.x;
    final fy = center.y - p1.y;

    // Project onto line
    final t = fx * dx + fy * dy;
    final closestX = p1.x + t * dx;
    final closestY = p1.y + t * dy;

    // Distance from center to line
    final distanceToLine = math.sqrt(
      (center.x - closestX) * (center.x - closestX) +
          (center.y - closestY) * (center.y - closestY),
    );

    if (distanceToLine > radius) return []; // No intersection

    // Calculate intersection points
    final discriminant = radius * radius - distanceToLine * distanceToLine;
    if (discriminant < 0) {
      throw IntersectionCalculationException(
        'Negative discriminant in intersection calculation',
      );
    }
    final halfChord = math.sqrt(discriminant);

    // Calculate t parameters for both intersections
    final t1 = (t - halfChord) / length;
    final t2 = (t + halfChord) / length;

    final intersection1 = GPoint.withCoordinates(
      closestX - halfChord * dx,
      closestY - halfChord * dy,
    );

    final intersection2 = GPoint.withCoordinates(
      closestX + halfChord * dx,
      closestY + halfChord * dy,
    );

    // Filter intersections based on line type
    List<GPoint> validIntersections = [];

    if (_isIntersectionValidForLine(line, t1)) {
      validIntersections.add(intersection1);
    }

    if (distanceToLine < radius && _isIntersectionValidForLine(line, t2)) {
      validIntersections.add(intersection2);
    }

    return validIntersections;
  }

  /// Calculates intersection points between two circles
  List<GPoint> calculateCircleCircleIntersections(
    GCircle circle1,
    GCircle circle2,
  ) {
    final center1 = circle1.center;
    final center2 = circle2.center;
    final r1 = circle1.getRadius();
    final r2 = circle2.getRadius();

    if (r1 <= 0 || r2 <= 0) {
      throw InvalidGeometricObjectException(
        'Both circles must have positive radius for intersection calculation',
      );
    }

    if (!r1.isFinite || !r2.isFinite) {
      throw InvalidGeometricObjectException(
        'Circles have invalid radii: $r1, $r2',
      );
    }

    // Distance between centers
    final dx = center2.x - center1.x;
    final dy = center2.y - center1.y;
    final d = math.sqrt(dx * dx + dy * dy);

    // Check for special cases
    if (d > r1 + r2) {
      return []; // Circles are separate, no intersection
    }

    if (d < (r1 - r2).abs()) {
      return []; // One circle is inside the other, no intersection
    }

    if (d == 0 && r1 == r2) {
      throw IntersectionCalculationException(
        'Circles are identical - infinite intersections',
      );
    }

    // Calculate intersection points
    final a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);
    final h = math.sqrt(r1 * r1 - a * a);

    // Point on line between centers
    final px = center1.x + a * dx / d;
    final py = center1.y + a * dy / d;

    if (h.abs() < 1e-10) {
      // Single intersection (tangent circles)
      return [GPoint.withCoordinates(px, py)];
    }

    // Two intersection points
    final intersection1 = GPoint.withCoordinates(
      px + h * dy / d,
      py - h * dx / d,
    );

    final intersection2 = GPoint.withCoordinates(
      px - h * dy / d,
      py + h * dx / d,
    );

    return [intersection1, intersection2];
  }
}
