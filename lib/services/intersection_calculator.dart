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

    final t =
        ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) / denom;

    final intersectionX = p1.x + t * (p2.x - p1.x);
    final intersectionY = p1.y + t * (p2.y - p1.y);

    return GPoint.withCoordinates(intersectionX, intersectionY);
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

    final intersection1 = GPoint.withCoordinates(
      closestX - halfChord * dx,
      closestY - halfChord * dy,
    );

    final intersection2 = GPoint.withCoordinates(
      closestX + halfChord * dx,
      closestY + halfChord * dy,
    );

    if (distanceToLine < radius) {
      // Two intersections
      return [intersection1, intersection2];
    } else {
      // One intersection (tangent)
      return [intersection1];
    }
  }
}
