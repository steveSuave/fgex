// lib/services/geometry_factory.dart
import '../models/models.dart';
import 'name_generator.dart';

/// Handles creation of geometric objects
class GeometryFactory {
  final NameGenerator _nameGenerator = NameGenerator.instance;

  /// Creates a free point that can be moved
  GPoint createFreePoint(double x, double y, {String? name}) {
    final point = GPoint.withCoordinates(x, y);
    point.name = name ?? _nameGenerator.generatePointName();
    return point;
  }

  /// Creates an infinite line between two points
  GInfiniteLine createInfiniteLine(GPoint p1, GPoint p2) {
    final line = GInfiniteLine(p1, p2);
    line.name = _nameGenerator.generateLineName();
    return line;
  }

  /// Creates a ray from first point through second point
  GRay createRay(GPoint p1, GPoint p2) {
    final ray = GRay(p1, p2);
    ray.name = _nameGenerator.generateLineName();
    return ray;
  }

  /// Creates a line segment between two points
  GSegment createSegment(GPoint p1, GPoint p2) {
    final segment = GSegment(p1, p2);
    segment.name = _nameGenerator.generateLineName();
    return segment;
  }

  /// Creates a circle with center and a point on the circle
  GCircle createCircle(GPoint center, GPoint pointOnCircle) {
    final circle = GCircle.withPoint(center, pointOnCircle);
    circle.name = _nameGenerator.generateCircleName();
    return circle;
  }

  /// Creates a circle passing through three points
  GCircle createThreePointCircle(GPoint p1, GPoint p2, GPoint p3) {
    // Calculate the circumcenter using the perpendicular bisector method
    final center = _calculateCircumcenter(p1, p2, p3);

    // Create the circle with the calculated center and the three points
    final circle = GCircle.threePoint(center, [p1, p2, p3]);
    circle.name = _nameGenerator.generateCircleName();
    return circle;
  }

  /// Calculates the circumcenter of three points
  GPoint _calculateCircumcenter(GPoint p1, GPoint p2, GPoint p3) {
    final x1 = p1.x, y1 = p1.y;
    final x2 = p2.x, y2 = p2.y;
    final x3 = p3.x, y3 = p3.y;

    // Calculate using determinant formula
    final d = 2 * (x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2));

    final ux =
        ((x1 * x1 + y1 * y1) * (y2 - y3) +
            (x2 * x2 + y2 * y2) * (y3 - y1) +
            (x3 * x3 + y3 * y3) * (y1 - y2)) /
        d;

    final uy =
        ((x1 * x1 + y1 * y1) * (x3 - x2) +
            (x2 * x2 + y2 * y2) * (x1 - x3) +
            (x3 * x3 + y3 * y3) * (x2 - x1)) /
        d;

    return GPoint.withCoordinates(ux, uy);
  }

  /// Resets all name counters
  void reset() {
    _nameGenerator.reset();
  }
}
