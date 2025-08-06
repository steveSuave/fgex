// lib/services/geometry_engine.dart
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
  final NameGenerator _nameGenerator = NameGenerator();

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

  /// Creates a line between two points
  GLine createLine(GPoint p1, GPoint p2) {
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
    if (existingLine != null) {
      return existingLine;
    }

    final line = _factory.createLine(p1, p2);
    _repository.addLine(line);
    return line;
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

      for (final point in intersections) {
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
      }

      return intersections;
    } on GeometryException {
      rethrow;
    } catch (e) {
      throw IntersectionCalculationException(
        'Unexpected error during line-circle intersection',
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

  /// Clears all geometric objects and resets counters
  void clear() {
    _repository.clear();
    _factory.reset();
    // Reset static counters in models
    GeometricObject.resetIdCounter();
    GPoint.resetParamCounter();
  }
}
