// lib/models/line.dart
import 'dart:math' as math;
import 'geometric_object.dart';
import 'point.dart';

enum LineType {
  standard, // Standard line (formerly LLINE = 0)
  radicalAxis, // Circle-circle radical axis (formerly CCLINE = 1)
}

enum LineVariant {
  infinite, // Infinite line in both directions
  ray, // Ray starting from first point through second point
  segment, // Line segment between two points
}

abstract class GLine extends GeometricObject {
  LineType lineType;
  List<GPoint> points;
  LineVariant get variant;

  GLine(GPoint p1, GPoint p2, {this.lineType = LineType.standard, int? id})
    : points = [p1, p2],
      super(GeometricObjectType.line, id: id);

  GLine.empty({this.lineType = LineType.standard, int? id})
    : points = [],
      super(GeometricObjectType.line, id: id);

  void addPoint(GPoint point) {
    if (!points.contains(point)) {
      points.add(point);
    }
  }

  GPoint? get firstPoint => points.isNotEmpty ? points.first : null;
  GPoint? getSecondPoint(GPoint? exclude) {
    for (var point in points) {
      if (point != exclude) return point;
    }
    return null;
  }

  bool containsBothPoints(GPoint p1, GPoint p2) {
    return points.contains(p1) && points.contains(p2);
  }

  /// Check if a point lies on this line (considering line type constraints)
  bool containsPoint(double x, double y, {double tolerance = 1e-10});

  /// Get the direction vector of the line
  ({double dx, double dy}) get direction {
    if (points.length < 2) return (dx: 0.0, dy: 0.0);
    return (dx: points[1].x - points[0].x, dy: points[1].y - points[0].y);
  }

  /// Get line endpoints for rendering (may extend to canvas bounds for infinite lines/rays)
  List<({double x, double y})> getDrawingEndpoints(
    double canvasWidth,
    double canvasHeight,
  );

  String getDescription();

  @override
  String toString() => name ?? getDescription();
}

class GInfiniteLine extends GLine {
  @override
  LineVariant get variant => LineVariant.infinite;

  GInfiniteLine(
    super.p1,
    super.p2, {
    super.lineType = LineType.standard,
    super.id,
  });

  GInfiniteLine.empty({super.lineType = LineType.standard, super.id})
    : super.empty();

  @override
  bool containsPoint(double x, double y, {double tolerance = 1e-10}) {
    if (points.length < 2) return false;

    final p1 = points[0];
    final p2 = points[1];

    // Check if point is collinear with line points using cross product
    final crossProduct =
        (y - p1.y) * (p2.x - p1.x) - (x - p1.x) * (p2.y - p1.y);
    return crossProduct.abs() < tolerance;
  }

  @override
  List<({double x, double y})> getDrawingEndpoints(
    double canvasWidth,
    double canvasHeight,
  ) {
    if (points.length < 2) return [];

    final p1 = points[0];
    final dir = direction;

    if (dir.dx.abs() < 1e-10 && dir.dy.abs() < 1e-10) return [];

    // Extend line to canvas bounds
    final maxDimension = math.max(canvasWidth, canvasHeight) * 2;
    final length = math.sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
    final normalizedDx = dir.dx / length;
    final normalizedDy = dir.dy / length;

    return [
      (
        x: p1.x - normalizedDx * maxDimension,
        y: p1.y - normalizedDy * maxDimension,
      ),
      (
        x: p1.x + normalizedDx * maxDimension,
        y: p1.y + normalizedDy * maxDimension,
      ),
    ];
  }

  @override
  String getDescription() {
    if (points.length >= 2) {
      return 'Line ${points[0]}${points[1]}';
    }
    return 'Line $id';
  }
}

class GRay extends GLine {
  @override
  LineVariant get variant => LineVariant.ray;

  GRay(super.p1, super.p2, {super.lineType = LineType.standard, super.id});

  GRay.empty({super.lineType = LineType.standard, super.id}) : super.empty();

  @override
  bool containsPoint(double x, double y, {double tolerance = 1e-10}) {
    if (points.length < 2) return false;

    final p1 = points[0]; // Ray origin
    final p2 = points[1]; // Point defining direction

    // Check if point is collinear
    final crossProduct =
        (y - p1.y) * (p2.x - p1.x) - (x - p1.x) * (p2.y - p1.y);
    if (crossProduct.abs() >= tolerance) return false;

    // Check if point is in the correct direction from origin
    final dotProduct = (x - p1.x) * (p2.x - p1.x) + (y - p1.y) * (p2.y - p1.y);
    return dotProduct >= 0; // Point must be in positive direction
  }

  @override
  List<({double x, double y})> getDrawingEndpoints(
    double canvasWidth,
    double canvasHeight,
  ) {
    if (points.length < 2) return [];

    final p1 = points[0]; // Ray origin
    final dir = direction;

    if (dir.dx.abs() < 1e-10 && dir.dy.abs() < 1e-10) return [];

    // Extend ray from origin in positive direction
    final maxDimension = math.max(canvasWidth, canvasHeight) * 2;
    final length = math.sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
    final normalizedDx = dir.dx / length;
    final normalizedDy = dir.dy / length;

    return [
      (x: p1.x, y: p1.y), // Ray starts at origin
      (
        x: p1.x + normalizedDx * maxDimension,
        y: p1.y + normalizedDy * maxDimension,
      ),
    ];
  }

  @override
  String getDescription() {
    if (points.length >= 2) {
      return 'Ray ${points[0]}${points[1]}';
    }
    return 'Ray $id';
  }
}

class GSegment extends GLine {
  @override
  LineVariant get variant => LineVariant.segment;

  GSegment(super.p1, super.p2, {super.lineType = LineType.standard, super.id});

  GSegment.empty({super.lineType = LineType.standard, super.id})
    : super.empty();

  @override
  bool containsPoint(double x, double y, {double tolerance = 1e-10}) {
    if (points.length < 2) return false;

    final p1 = points[0];
    final p2 = points[1];

    // Check if point is collinear
    final crossProduct =
        (y - p1.y) * (p2.x - p1.x) - (x - p1.x) * (p2.y - p1.y);
    if (crossProduct.abs() >= tolerance) return false;

    // Check if point is between the segment endpoints
    final minX = math.min(p1.x, p2.x);
    final maxX = math.max(p1.x, p2.x);
    final minY = math.min(p1.y, p2.y);
    final maxY = math.max(p1.y, p2.y);

    return x >= minX - tolerance &&
        x <= maxX + tolerance &&
        y >= minY - tolerance &&
        y <= maxY + tolerance;
  }

  @override
  List<({double x, double y})> getDrawingEndpoints(
    double canvasWidth,
    double canvasHeight,
  ) {
    if (points.length < 2) return [];

    final p1 = points[0];
    final p2 = points[1];

    return [(x: p1.x, y: p1.y), (x: p2.x, y: p2.y)];
  }

  /// Get the length of the segment
  double get length {
    if (points.length < 2) return 0.0;
    final p1 = points[0];
    final p2 = points[1];
    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  String getDescription() {
    if (points.length >= 2) {
      return 'Segment ${points[0]}${points[1]}';
    }
    return 'Segment $id';
  }
}
