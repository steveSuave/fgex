// lib/services/geometry_engine.dart
import 'dart:math' as math;
import 'package:flutter_geometry_expert/services/geometry_state_snapshot.dart';

import '../models/models.dart';
import '../exceptions/geometry_exceptions.dart';
import '../constants/geometry_constants.dart';
import 'geometry_factory.dart';
import 'geometry_repository.dart';
import 'intersection_calculator.dart';
import 'name_generator.dart';

/// Main engine that coordinates geometric operations
class GeometryEngine {
  final GeometryRepository _repository = GeometryRepository();
  final GeometryFactory _factory = GeometryFactory();
  final IntersectionCalculator _intersectionCalculator =
      IntersectionCalculator();
  final NameGenerator _nameGenerator = NameGenerator.instance;

  // Expose repository collections
  List<GPoint> get points => _repository.points;
  List<GLine> get lines => _repository.lines;
  List<GCircle> get circles => _repository.circles;
  List<Constraint> get constraints => _repository.constraints;

  /// Creates a free point that can be moved
  GPoint createFreePoint(double x, double y, {String? name}) {
    if (!x.isFinite || !y.isFinite) {
      throw InvalidGeometricObjectException(
        'Point coordinates must be finite numbers: ($x, $y)',
      );
    }

    final point = _factory.createFreePoint(x, y, name: name);
    _repository.addPoint(point);
    return point;
  }

  /// Creates a point constrained to lie on a line
  GPoint createPointOnLine(GLine line, double x, double y, {String? name}) {
    if (!x.isFinite || !y.isFinite) {
      throw InvalidGeometricObjectException(
        'Point coordinates must be finite numbers: ($x, $y)',
      );
    }

    // Project the point onto the line to ensure it lies on the line
    final projectedPoint = line.getClosestPoint(GPoint.withCoordinates(x, y));
    final point = _factory.createFreePoint(
      projectedPoint.x,
      projectedPoint.y,
      name: name,
    );

    // Add the point to the line and repository
    line.addPoint(point);
    _repository.addPoint(point);

    // Create onLine constraint
    final constraint = Constraint(ConstraintType.onLine, [point, line]);
    _repository.addConstraint(constraint);

    return point;
  }

  /// Creates a point constrained to lie on a circle
  GPoint createPointOnCircle(
    GCircle circle,
    double x,
    double y, {
    String? name,
  }) {
    if (!x.isFinite || !y.isFinite) {
      throw InvalidGeometricObjectException(
        'Point coordinates must be finite numbers: ($x, $y)',
      );
    }

    // Project the point onto the circle to ensure it lies on the circle
    final projectedPoint = circle.getClosestPoint(GPoint.withCoordinates(x, y));
    final point = _factory.createFreePoint(
      projectedPoint.x,
      projectedPoint.y,
      name: name,
    );

    // Add the point to the circle and repository
    circle.addPoint(point);
    _repository.addPoint(point);

    // Create onCircle constraint
    final constraint = Constraint(ConstraintType.onCircle, [point, circle]);
    _repository.addConstraint(constraint);

    return point;
  }

  /// Creates a point that is constrained to be the midpoint between two points
  GPoint createMidpoint(GPoint p1, GPoint p2) {
    if (p1 == p2) {
      throw InvalidConstructionException(
        'Cannot create midpoint with identical points',
      );
    }

    if (p1.isSameLocation(p2.x, p2.y)) {
      throw InvalidConstructionException(
        'Cannot create midpoint between points at same location: ${p1.name ?? p1.id} and ${p2.name ?? p2.id}',
      );
    }

    // Calculate midpoint coordinates
    final midX = (p1.x + p2.x) / 2;
    final midY = (p1.y + p2.y) / 2;

    // Check if a point already exists at this location
    final existingPoint = _repository.selectPointAt(
      midX,
      midY,
      tolerance: GeometryConstants.pointLocationTolerance,
    );

    if (existingPoint != null) {
      // Add constraint to existing point
      final constraint = Constraint(ConstraintType.midpoint, [
        existingPoint,
        p1,
        p2,
      ]);
      _repository.addConstraint(constraint);
      return existingPoint;
    }

    // Create new midpoint
    final midpoint = _factory.createFreePoint(midX, midY);

    // Add constraint
    final constraint = Constraint(ConstraintType.midpoint, [midpoint, p1, p2]);

    _repository.addConstraint(constraint);
    _repository.addPoint(midpoint);
    return midpoint;
  }

  /// Creates an infinite line between two points
  GInfiniteLine createInfiniteLine(GPoint p1, GPoint p2) {
    if (p1 == p2) {
      throw InvalidConstructionException(
        'Cannot create line with identical points',
      );
    }

    if (p1.isSameLocation(p2.x, p2.y)) {
      throw InvalidConstructionException(
        'Cannot create line between points at same location: ${p1.name ?? p1.id} and ${p2.name ?? p2.id}',
      );
    }

    // Check if line already exists
    final existingLine = _repository.findLine(p1, p2);
    if (existingLine is GInfiniteLine) {
      return existingLine;
    }

    final line = _factory.createInfiniteLine(p1, p2);
    _repository.addLine(line);
    return line;
  }

  /// Creates a ray from first point through second point
  GRay createRay(GPoint p1, GPoint p2) {
    if (p1 == p2) {
      throw InvalidConstructionException(
        'Cannot create ray with identical points',
      );
    }

    if (p1.isSameLocation(p2.x, p2.y)) {
      throw InvalidConstructionException(
        'Cannot create ray between points at same location: ${p1.name ?? p1.id} and ${p2.name ?? p2.id}',
      );
    }

    final ray = _factory.createRay(p1, p2);
    _repository.addLine(ray);
    return ray;
  }

  /// Creates a line segment between two points
  GSegment createSegment(GPoint p1, GPoint p2) {
    if (p1 == p2) {
      throw InvalidConstructionException(
        'Cannot create segment with identical points',
      );
    }

    if (p1.isSameLocation(p2.x, p2.y)) {
      throw InvalidConstructionException(
        'Cannot create segment between points at same location: ${p1.name ?? p1.id} and ${p2.name ?? p2.id}',
      );
    }

    final segment = _factory.createSegment(p1, p2);
    _repository.addLine(segment);
    return segment;
  }

  /// Creates an infinite line perpendicular to a given line through a point
  GInfiniteLine createPerpendicularLine(GPoint point, GLine line) {
    if (line.points.length < 2) {
      throw InvalidConstructionException('Line must have at least 2 points');
    }

    // Calculate the direction vector of the original line
    double dx = line.points[1].x - line.points[0].x;
    double dy = line.points[1].y - line.points[0].y;

    // Perpendicular direction vector (rotate 90 degrees)
    double perpDx = -dy;
    double perpDy = dx;

    // Normalize the perpendicular direction
    double length = math.sqrt(perpDx * perpDx + perpDy * perpDy);
    if (length < GeometryConstants.pointLocationTolerance) {
      throw InvalidConstructionException(
        'Cannot create perpendicular to degenerate line',
      );
    }

    perpDx /= length;
    perpDy /= length;

    // Create a second point on the perpendicular line
    double secondX =
        point.x + perpDx * 100; // Arbitrary distance for visualization
    double secondY = point.y + perpDy * 100;

    // Create a temporary point for line construction
    final tempPoint = _factory.createFreePoint(secondX, secondY, name: null);

    // Create the perpendicular line
    final perpLine = _factory.createInfiniteLine(point, tempPoint);

    // Create the perpendicular constraint
    final constraint = Constraint(ConstraintType.perpendicular, [
      perpLine,
      line,
    ]);

    _repository.addLine(perpLine);
    _repository.addConstraint(constraint);
    return perpLine;
  }

  /// Creates a circle with center and point on circumference
  GCircle createCircle(GPoint center, GPoint pointOnCircle) {
    if (center == pointOnCircle) {
      throw InvalidConstructionException(
        'Cannot create circle with center and point on circle being the same point',
      );
    }

    if (center.isSameLocation(pointOnCircle.x, pointOnCircle.y)) {
      throw InvalidConstructionException(
        'Cannot create circle with zero radius: center ${center.name ?? center.id} and point ${pointOnCircle.name ?? pointOnCircle.id} are at same location',
      );
    }

    final circle = _factory.createCircle(center, pointOnCircle);
    _repository.addCircle(circle);

    // NOTE: Do not constrain the defining points of the circle
    // The center and pointOnCircle should be free to drag and transform the circle

    return circle;
  }

  /// Creates a circle passing through three points
  GCircle createThreePointCircle(GPoint p1, GPoint p2, GPoint p3) {
    if (p1 == p2 || p2 == p3 || p1 == p3) {
      throw InvalidConstructionException(
        'Cannot create circle with identical points',
      );
    }

    if (p1.isSameLocation(p2.x, p2.y) ||
        p2.isSameLocation(p3.x, p3.y) ||
        p1.isSameLocation(p3.x, p3.y)) {
      throw InvalidConstructionException(
        'Cannot create circle through points at same locations',
      );
    }

    // Check if points are collinear
    final dx1 = p2.x - p1.x;
    final dy1 = p2.y - p1.y;
    final dx2 = p3.x - p1.x;
    final dy2 = p3.y - p1.y;
    final crossProduct = dx1 * dy2 - dy1 * dx2;

    if (crossProduct.abs() < 1e-10) {
      throw InvalidConstructionException(
        'Cannot create circle through collinear points',
      );
    }

    final circle = _factory.createThreePointCircle(p1, p2, p3);
    _repository.addCircle(circle);

    // NOTE: Do not constrain the defining points of the three-point circle
    // All three points should be free to drag and transform the circle

    return circle;
  }

  /// Creates intersection point between two lines
  GPoint? createLineLineIntersection(GLine line1, GLine line2) {
    if (line1 == line2) {
      throw InvalidConstructionException('Cannot intersect line with itself');
    }

    try {
      final intersection = _intersectionCalculator
          .calculateLineLineIntersection(line1, line2);
      if (intersection == null) return null;

      // Check if a point already exists at this location
      final existingPoint = _repository.selectPointAt(
        intersection.x,
        intersection.y,
        tolerance: GeometryConstants.pointLocationTolerance,
      );

      if (existingPoint != null) {
        // Use existing point instead of creating a new one
        line1.addPoint(existingPoint);
        line2.addPoint(existingPoint);

        // Add constraint
        final constraint = Constraint(ConstraintType.interLL, [
          existingPoint,
          line1,
          line2,
        ]);
        _repository.addConstraint(constraint);
        return existingPoint;
      }

      intersection.name = _nameGenerator.generatePointName();

      // Add point to both lines
      line1.addPoint(intersection);
      line2.addPoint(intersection);

      // Add constraint
      final constraint = Constraint(ConstraintType.interLL, [
        intersection,
        line1,
        line2,
      ]);
      _repository.addConstraint(constraint);
      _repository.addPoint(intersection);
      return intersection;
    } on GeometryException {
      rethrow;
    } catch (e) {
      throw IntersectionCalculationException(
        'Unexpected error during line-line intersection',
        e,
      );
    }
  }

  /// Creates intersection points between line and circle
  List<GPoint> createLineCircleIntersection(GLine line, GCircle circle) {
    try {
      final intersections = _intersectionCalculator
          .calculateLineCircleIntersections(line, circle);

      final resultPoints = <GPoint>[];
      for (final point in intersections) {
        // Check if a point already exists at this location
        final existingPoint = _repository.selectPointAt(
          point.x,
          point.y,
          tolerance: GeometryConstants.pointLocationTolerance,
        );

        if (existingPoint != null) {
          // Use existing point instead of creating a new one
          line.addPoint(existingPoint);
          circle.addPoint(existingPoint);

          final constraint = Constraint(ConstraintType.interLC, [
            existingPoint,
            line,
            circle,
          ]);
          _repository.addConstraint(constraint);
          resultPoints.add(existingPoint);
        } else {
          point.name = _nameGenerator.generatePointName();
          line.addPoint(point);
          circle.addPoint(point);
          _repository.addPoint(point);

          final constraint = Constraint(ConstraintType.interLC, [
            point,
            line,
            circle,
          ]);
          _repository.addConstraint(constraint);
          resultPoints.add(point);
        }
      }

      return resultPoints;
    } on GeometryException {
      rethrow;
    } catch (e) {
      throw IntersectionCalculationException(
        'Unexpected error during line-circle intersection',
        e,
      );
    }
  }

  /// Creates intersection points between two circles
  List<GPoint> createCircleCircleIntersection(
    GCircle circle1,
    GCircle circle2,
  ) {
    if (circle1 == circle2) {
      throw InvalidConstructionException('Cannot intersect circle with itself');
    }

    try {
      final intersections = _intersectionCalculator
          .calculateCircleCircleIntersections(circle1, circle2);

      final resultPoints = <GPoint>[];
      for (final point in intersections) {
        // Check if a point already exists at this location
        final existingPoint = _repository.selectPointAt(
          point.x,
          point.y,
          tolerance: GeometryConstants.pointLocationTolerance,
        );

        if (existingPoint != null) {
          // Use existing point instead of creating a new one
          circle1.addPoint(existingPoint);
          circle2.addPoint(existingPoint);

          final constraint = Constraint(ConstraintType.interCC, [
            existingPoint,
            circle1,
            circle2,
          ]);
          _repository.addConstraint(constraint);
          resultPoints.add(existingPoint);
        } else {
          point.name = _nameGenerator.generatePointName();
          circle1.addPoint(point);
          circle2.addPoint(point);
          _repository.addPoint(point);

          final constraint = Constraint(ConstraintType.interCC, [
            point,
            circle1,
            circle2,
          ]);
          _repository.addConstraint(constraint);
          resultPoints.add(point);
        }
      }

      return resultPoints;
    } on GeometryException {
      rethrow;
    } catch (e) {
      throw IntersectionCalculationException(
        'Unexpected error during circle-circle intersection',
        e,
      );
    }
  }

  /// Finds the closest point to given coordinates
  GPoint? selectPointAt(double x, double y, {double? tolerance}) {
    return _repository.selectPointAt(
      x,
      y,
      tolerance: tolerance ?? GeometryConstants.pointSelectionTolerance,
    );
  }

  /// Finds a line that contains the given coordinates within tolerance
  GLine? selectLineAt(double x, double y, {double? tolerance}) {
    final tol = tolerance ?? GeometryConstants.lineSelectionTolerance;

    for (final line in lines) {
      if (_isPointNearLine(line, x, y, tol)) {
        return line;
      }
    }
    return null;
  }

  /// Helper method to check if a point is near a line within tolerance
  bool _isPointNearLine(GLine line, double x, double y, double tolerance) {
    if (line.points.length < 2) return false;

    final p1 = line.points[0];
    final p2 = line.points[1];

    // Calculate distance from point to line
    final lineLength = _distanceBetween(p1.x, p1.y, p2.x, p2.y);
    if (lineLength == 0) return false;

    // Use cross product to find perpendicular distance to infinite line
    final crossProduct =
        ((y - p1.y) * (p2.x - p1.x) - (x - p1.x) * (p2.y - p1.y)).abs();
    final distanceToInfiniteLine = crossProduct / lineLength;

    // Check if point is close enough to the infinite line
    if (distanceToInfiniteLine > tolerance) return false;

    // Now check constraints based on line type
    switch (line.variant) {
      case LineVariant.infinite:
        return true; // Any point on infinite line is valid

      case LineVariant.ray:
        // Check if point is in the positive direction from ray origin
        final dotProduct =
            (x - p1.x) * (p2.x - p1.x) + (y - p1.y) * (p2.y - p1.y);
        return dotProduct >= 0;

      case LineVariant.segment:
        // Check if point is between segment endpoints (with tolerance)
        final t =
            ((x - p1.x) * (p2.x - p1.x) + (y - p1.y) * (p2.y - p1.y)) /
            (lineLength * lineLength);
        return t >= 0 && t <= 1;
    }
  }

  /// Finds a circle that contains the given coordinates on its circumference within tolerance
  GCircle? selectCircleAt(double x, double y, {double? tolerance}) {
    final tol = tolerance ?? GeometryConstants.circleSelectionTolerance;

    for (final circle in circles) {
      final radius = circle.getRadius();
      if (radius <= 0) continue;

      final distanceFromCenter = _distanceBetween(
        x,
        y,
        circle.center.x,
        circle.center.y,
      );

      // Only select if point is near the circumference (not inside or far outside)
      final distanceFromCircumference = (distanceFromCenter - radius).abs();
      if (distanceFromCircumference <= tol) {
        return circle;
      }
    }
    return null;
  }

  /// Helper method to calculate distance between two points
  double _distanceBetween(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Clears all geometric objects and resets counters
  void clear() {
    _repository.clear();
    _factory.reset();
    // Reset static counters in models
    GeometricObject.resetIdCounter();
    GPoint.resetParamCounter();
  }

  List<GeometricObject> getAllObjects() {
    return _repository.getAllObjects();
  }

  // Undo/Redo functionality: Save the current state as a snapshot.
  GeometryStateSnapshot saveState() {
    return GeometryStateSnapshot(
      points: List.from(points),
      lines: List.from(lines),
      circles: List.from(circles),
      constraints: List.from(constraints),
    );
  }

  // Restore the state from a snapshot.
  void restoreState(GeometryStateSnapshot snapshot) {
    clear();
    for (final p in snapshot.points) {
      _repository.addPoint(p);
    }
    for (final l in snapshot.lines) {
      _repository.addLine(l);
    }
    for (final c in snapshot.circles) {
      _repository.addCircle(c);
    }
    for (final cons in snapshot.constraints) {
      _repository.addConstraint(cons);
    }
  }

  // TODO implement in repository
  List<GeometricObject> getAllPoints() {
    return _repository.getAllObjects().whereType<GPoint>().toList();
  }
}
