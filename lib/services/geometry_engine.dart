// lib/services/geometry_engine.dart
import 'dart:math' as math;
import '../models/models.dart';

class GeometryEngine {
  List<GPoint> points = [];
  List<GLine> lines = [];
  List<GCircle> circles = [];
  List<Constraint> constraints = [];

  // Add geometric objects
  void addPoint(GPoint point) {
    if (!points.contains(point)) {
      points.add(point);
    }
  }

  void addLine(GLine line) {
    if (!lines.contains(line)) {
      lines.add(line);
    }
  }

  void addCircle(GCircle circle) {
    if (!circles.contains(circle)) {
      circles.add(circle);
    }
  }

  void addConstraint(Constraint constraint) {
    constraints.add(constraint);
  }

  // Smart construction methods (like Java original)
  GPoint createFreePoint(double x, double y, {String? name}) {
    var point = GPoint.withCoordinates(x, y);
    point.name = name ?? generatePointName();
    addPoint(point);
    return point;
  }

  GLine createLine(GPoint p1, GPoint p2) {
    // Check if line already exists
    var existingLine = findLine(p1, p2);
    if (existingLine != null) {
      return existingLine;
    }

    var line = GLine(p1, p2);
    line.name = generateLineName();
    addLine(line);
    return line;
  }

  GCircle createCircle(GPoint center, GPoint pointOnCircle) {
    var circle = GCircle.withPoint(center, pointOnCircle);
    circle.name = generateCircleName();
    addCircle(circle);
    return circle;
  }

  // Intersection methods
  GPoint? createIntersectionLL(GLine line1, GLine line2) {
    if (line1.points.length < 2 || line2.points.length < 2) {
      return null;
    }

    var p1 = line1.points[0];
    var p2 = line1.points[1];
    var p3 = line2.points[0];
    var p4 = line2.points[1];

    // Calculate intersection using determinants
    var denom = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
    if (denom.abs() < 1e-10) return null; // Parallel lines

    var t =
        ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) / denom;

    var intersectionX = p1.x + t * (p2.x - p1.x);
    var intersectionY = p1.y + t * (p2.y - p1.y);

    var intersection = GPoint.withCoordinates(intersectionX, intersectionY);
    intersection.name = generatePointName();

    // Add point to both lines
    line1.addPoint(intersection);
    line2.addPoint(intersection);

    // Add constraint
    var constraint = Constraint(ConstraintType.interLL, [
      intersection,
      line1,
      line2,
    ]);
    addConstraint(constraint);

    addPoint(intersection);
    return intersection;
  }

  List<GPoint> createIntersectionLC(GLine line, GCircle circle) {
    if (line.points.length < 2) return [];

    var p1 = line.points[0];
    var p2 = line.points[1];
    var center = circle.center;
    var radius = circle.getRadius();

    // Line direction vector
    var dx = p2.x - p1.x;
    var dy = p2.y - p1.y;
    var length = math.sqrt(dx * dx + dy * dy);

    if (length == 0) return [];

    // Normalize direction vector
    dx /= length;
    dy /= length;

    // Vector from line start to circle center
    var fx = center.x - p1.x;
    var fy = center.y - p1.y;

    // Project onto line
    var t = fx * dx + fy * dy;
    var closestX = p1.x + t * dx;
    var closestY = p1.y + t * dy;

    // Distance from center to line
    var distanceToLine = math.sqrt(
      (center.x - closestX) * (center.x - closestX) +
          (center.y - closestY) * (center.y - closestY),
    );

    if (distanceToLine > radius) return []; // No intersection

    // Calculate intersection points
    var halfChord = math.sqrt(
      radius * radius - distanceToLine * distanceToLine,
    );

    var intersection1 = GPoint.withCoordinates(
      closestX - halfChord * dx,
      closestY - halfChord * dy,
    );
    intersection1.name = generatePointName();

    var intersection2 = GPoint.withCoordinates(
      closestX + halfChord * dx,
      closestY + halfChord * dy,
    );
    intersection2.name = generatePointName();

    var intersections = <GPoint>[];

    if (distanceToLine < radius) {
      // Two intersections
      intersections = [intersection1, intersection2];
    } else {
      // One intersection (tangent)
      intersections = [intersection1];
    }

    for (var point in intersections) {
      line.addPoint(point);
      circle.addPoint(point);
      addPoint(point);

      var constraint = Constraint(ConstraintType.interLC, [
        point,
        line,
        circle,
      ]);
      addConstraint(constraint);
    }

    return intersections;
  }

  // Utility methods
  GLine? findLine(GPoint p1, GPoint p2) {
    for (var line in lines) {
      if (line.containsBothPoints(p1, p2)) {
        return line;
      }
    }
    return null;
  }

  GPoint? selectPointAt(double x, double y, {double tolerance = 20.0}) {
    for (var point in points) {
      var distance = math.sqrt(
        (point.x - x) * (point.x - x) + (point.y - y) * (point.y - y),
      );
      if (distance <= tolerance) {
        return point;
      }
    }
    return null;
  }

  // Name generation
  int _pointCounter = 0;
  int _lineCounter = 0;
  int _circleCounter = 0;

  String generatePointName() {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_pointCounter < letters.length) {
      return letters[_pointCounter++];
    }
    return 'P${++_pointCounter}';
  }

  String generateLineName() => 'l${++_lineCounter}';
  String generateCircleName() => 'c${++_circleCounter}';

  void clear() {
    points.clear();
    lines.clear();
    circles.clear();
    constraints.clear();
    _pointCounter = 0;
    _lineCounter = 0;
    _circleCounter = 0;
  }
}
