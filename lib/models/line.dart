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
    double canvasHeight, {
    double translationX = 0.0,
    double translationY = 0.0,
  });

  String getDescription();

  @override
  double distanceToPoint(GPoint point) {
    final closestPoint = getClosestPoint(point);
    return closestPoint.distanceTo(point);
  }

  /// Calculates the projection of a point onto the infinite line defined by the line's points.
  /// Returns the projection parameter 't' and the projected point.
  ({double t, GPoint point}) _projectPoint(GPoint toPoint) {
    if (points.length < 2) {
      // If line is not defined, return the first point or a zero point.
      final p1 = firstPoint ?? GPoint.withCoordinates(0, 0);
      return (t: 0.0, point: p1);
    }
    final p1 = points[0];
    final p2 = points[1];
    final lineDirX = p2.x - p1.x;
    final lineDirY = p2.y - p1.y;

    final double lineLengthSq = lineDirX * lineDirX + lineDirY * lineDirY;
    if (lineLengthSq < 1e-12) {
      // The two points defining the line are the same.
      return (t: 0.0, point: p1);
    }

    final double t =
        ((toPoint.x - p1.x) * lineDirX + (toPoint.y - p1.y) * lineDirY) /
        lineLengthSq;

    final closestX = p1.x + t * lineDirX;
    final closestY = p1.y + t * lineDirY;
    final closestPoint = GPoint.withCoordinates(closestX, closestY);

    return (t: t, point: closestPoint);
  }

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
  GPoint getClosestPoint(GPoint toPoint) {
    // For an infinite line, the closest point is always the direct projection.
    return _projectPoint(toPoint).point;
  }

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
    double canvasHeight, {
    double translationX = 0.0,
    double translationY = 0.0,
  }) {
    if (points.length < 2) return [];

    final p1 = points[0];
    final dir = direction;

    if (dir.dx.abs() < 1e-10 && dir.dy.abs() < 1e-10) return [];

    // Calculate the current visible viewport bounds accounting for translation
    final viewportLeft = -translationX;
    final viewportRight = canvasWidth - translationX;
    final viewportTop = -translationY;
    final viewportBottom = canvasHeight - translationY;

    // Find intersections with viewport boundaries
    final intersections = <({double x, double y})>[];

    // Check intersection with left edge (x = viewportLeft)
    if (dir.dx.abs() > 1e-10) {
      final t = (viewportLeft - p1.x) / dir.dx;
      final y = p1.y + t * dir.dy;
      if (y >= viewportTop && y <= viewportBottom) {
        intersections.add((x: viewportLeft, y: y));
      }
    }

    // Check intersection with right edge (x = viewportRight)
    if (dir.dx.abs() > 1e-10) {
      final t = (viewportRight - p1.x) / dir.dx;
      final y = p1.y + t * dir.dy;
      if (y >= viewportTop && y <= viewportBottom) {
        intersections.add((x: viewportRight, y: y));
      }
    }

    // Check intersection with top edge (y = viewportTop)
    if (dir.dy.abs() > 1e-10) {
      final t = (viewportTop - p1.y) / dir.dy;
      final x = p1.x + t * dir.dx;
      if (x >= viewportLeft && x <= viewportRight) {
        intersections.add((x: x, y: viewportTop));
      }
    }

    // Check intersection with bottom edge (y = viewportBottom)
    if (dir.dy.abs() > 1e-10) {
      final t = (viewportBottom - p1.y) / dir.dy;
      final x = p1.x + t * dir.dx;
      if (x >= viewportLeft && x <= viewportRight) {
        intersections.add((x: x, y: viewportBottom));
      }
    }

    // Remove duplicates (within tolerance)
    final uniqueIntersections = <({double x, double y})>[];
    for (final intersection in intersections) {
      bool isDuplicate = false;
      for (final existing in uniqueIntersections) {
        if ((intersection.x - existing.x).abs() < 1e-6 &&
            (intersection.y - existing.y).abs() < 1e-6) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) {
        uniqueIntersections.add(intersection);
      }
    }

    // For infinite lines, we should have exactly 2 intersections
    // If we have fewer, extend beyond viewport
    if (uniqueIntersections.length < 2) {
      final extension = math.max(canvasWidth, canvasHeight);
      final length = math.sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
      if (length == 0) return [];
      final normalizedDx = dir.dx / length;
      final normalizedDy = dir.dy / length;

      return [
        (
          x: p1.x - normalizedDx * extension,
          y: p1.y - normalizedDy * extension,
        ),
        (
          x: p1.x + normalizedDx * extension,
          y: p1.y + normalizedDy * extension,
        ),
      ];
    }

    return uniqueIntersections.take(2).toList();
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
  GPoint getClosestPoint(GPoint toPoint) {
    final projection = _projectPoint(toPoint);
    // If t < 0, the projection is behind the ray's start point.
    // In this case, the closest point on the ray is the start point itself.
    if (projection.t < 0) {
      return points[0];
    }
    // Otherwise, it's the projected point on the infinite line.
    return projection.point;
  }

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
    double canvasHeight, {
    double translationX = 0.0,
    double translationY = 0.0,
  }) {
    if (points.length < 2) return [];

    final p1 = points[0]; // Ray origin
    final dir = direction;

    if (dir.dx.abs() < 1e-10 && dir.dy.abs() < 1e-10) return [];

    // Calculate the current visible viewport bounds accounting for translation
    final viewportLeft = -translationX;
    final viewportRight = canvasWidth - translationX;
    final viewportTop = -translationY;
    final viewportBottom = canvasHeight - translationY;

    // Find intersections with viewport boundaries in the positive direction only
    final intersections = <({double x, double y})>[];

    // Check intersection with left edge (x = viewportLeft)
    if (dir.dx.abs() > 1e-10) {
      final t = (viewportLeft - p1.x) / dir.dx;
      if (t >= 0) {
        // Only positive direction for rays
        final y = p1.y + t * dir.dy;
        if (y >= viewportTop && y <= viewportBottom) {
          intersections.add((x: viewportLeft, y: y));
        }
      }
    }

    // Check intersection with right edge (x = viewportRight)
    if (dir.dx.abs() > 1e-10) {
      final t = (viewportRight - p1.x) / dir.dx;
      if (t >= 0) {
        // Only positive direction for rays
        final y = p1.y + t * dir.dy;
        if (y >= viewportTop && y <= viewportBottom) {
          intersections.add((x: viewportRight, y: y));
        }
      }
    }

    // Check intersection with top edge (y = viewportTop)
    if (dir.dy.abs() > 1e-10) {
      final t = (viewportTop - p1.y) / dir.dy;
      if (t >= 0) {
        // Only positive direction for rays
        final x = p1.x + t * dir.dx;
        if (x >= viewportLeft && x <= viewportRight) {
          intersections.add((x: x, y: viewportTop));
        }
      }
    }

    // Check intersection with bottom edge (y = viewportBottom)
    if (dir.dy.abs() > 1e-10) {
      final t = (viewportBottom - p1.y) / dir.dy;
      if (t >= 0) {
        // Only positive direction for rays
        final x = p1.x + t * dir.dx;
        if (x >= viewportLeft && x <= viewportRight) {
          intersections.add((x: x, y: viewportBottom));
        }
      }
    }

    // Remove duplicates (within tolerance)
    final uniqueIntersections = <({double x, double y})>[];
    for (final intersection in intersections) {
      bool isDuplicate = false;
      for (final existing in uniqueIntersections) {
        if ((intersection.x - existing.x).abs() < 1e-6 &&
            (intersection.y - existing.y).abs() < 1e-6) {
          isDuplicate = true;
          break;
        }
      }
      if (!isDuplicate) {
        uniqueIntersections.add(intersection);
      }
    }

    // Ray starts at origin and goes to the first intersection (if any)
    if (uniqueIntersections.isNotEmpty) {
      return [(x: p1.x, y: p1.y), uniqueIntersections.first];
    }

    // If no viewport intersection found, extend beyond viewport in positive direction
    final extension = math.max(canvasWidth, canvasHeight);
    final length = math.sqrt(dir.dx * dir.dx + dir.dy * dir.dy);
    if (length == 0) return [];
    final normalizedDx = dir.dx / length;
    final normalizedDy = dir.dy / length;

    return [
      (x: p1.x, y: p1.y), // Ray starts at origin
      (x: p1.x + normalizedDx * extension, y: p1.y + normalizedDy * extension),
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
  GPoint getClosestPoint(GPoint toPoint) {
    final projection = _projectPoint(toPoint);
    // For a segment, the projection must be between the start and end points (0 <= t <= 1).
    if (projection.t < 0) {
      // Projection is before the start point.
      return points[0];
    } else if (projection.t > 1) {
      // Projection is after the end point.
      return points[1];
    }
    // Projection is within the segment.
    return projection.point;
  }

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
    double canvasHeight, {
    double translationX = 0.0,
    double translationY = 0.0,
  }) {
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
