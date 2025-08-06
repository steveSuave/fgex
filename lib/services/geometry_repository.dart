// lib/services/geometry_repository.dart
import 'dart:math' as math;
import '../models/models.dart';
import '../constants/geometry_constants.dart';

/// Manages storage and retrieval of geometric objects
class GeometryRepository {
  final List<GPoint> _points = [];
  final List<GLine> _lines = [];
  final List<GCircle> _circles = [];
  final List<Constraint> _constraints = [];

  // Getters for immutable access
  List<GPoint> get points => List.unmodifiable(_points);
  List<GLine> get lines => List.unmodifiable(_lines);
  List<GCircle> get circles => List.unmodifiable(_circles);
  List<Constraint> get constraints => List.unmodifiable(_constraints);

  /// Adds a point if it doesn't already exist
  void addPoint(GPoint point) {
    if (!_points.contains(point)) {
      _points.add(point);
    }
  }

  /// Adds a line if it doesn't already exist
  void addLine(GLine line) {
    if (!_lines.contains(line)) {
      _lines.add(line);
    }
  }

  /// Adds a circle if it doesn't already exist
  void addCircle(GCircle circle) {
    if (!_circles.contains(circle)) {
      _circles.add(circle);
    }
  }

  /// Adds a constraint
  void addConstraint(Constraint constraint) {
    _constraints.add(constraint);
  }

  /// Finds a line that contains both points
  GLine? findLine(GPoint p1, GPoint p2) {
    for (final line in _lines) {
      if (line.containsBothPoints(p1, p2)) {
        return line;
      }
    }
    return null;
  }

  /// Finds the closest point to the given coordinates within tolerance
  GPoint? selectPointAt(
    double x,
    double y, {
    double tolerance = GeometryConstants.pointSelectionTolerance,
  }) {
    for (final point in _points) {
      final distance = math.sqrt(
        (point.x - x) * (point.x - x) + (point.y - y) * (point.y - y),
      );
      if (distance <= tolerance) {
        return point;
      }
    }
    return null;
  }

  /// Clears all stored objects
  void clear() {
    _points.clear();
    _lines.clear();
    _circles.clear();
    _constraints.clear();
  }
}
