// lib/services/geometry_factory.dart
import '../models/models.dart';
import 'name_generator.dart';

/// Handles creation of geometric objects
class GeometryFactory {
  final NameGenerator _nameGenerator = NameGenerator();

  /// Creates a free point that can be moved
  GPoint createFreePoint(double x, double y, {String? name}) {
    final point = GPoint.withCoordinates(x, y);
    point.name = name ?? _nameGenerator.generatePointName();
    return point;
  }

  /// Creates a line between two points
  GLine createLine(GPoint p1, GPoint p2) {
    final line = GLine(p1, p2);
    line.name = _nameGenerator.generateLineName();
    return line;
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
