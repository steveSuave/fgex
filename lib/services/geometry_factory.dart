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

  /// Resets all name counters
  void reset() {
    _nameGenerator.reset();
  }
}
