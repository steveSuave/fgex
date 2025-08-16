// lib/services/constraint_solver.dart
import 'dart:math' as math;
import '../models/models.dart';
import 'intersection_calculator.dart';

class DependencyEntry {
  Set<int> dependents;
  Constraint constraint;

  DependencyEntry(this.constraint, this.dependents);
}

/// Handles constraint solving and dependency propagation for drag operations
class ConstraintSolver {
  final IntersectionCalculator _intersectionCalculator =
      IntersectionCalculator();

  /// Builds a dependency graph from constraints
  Map<int, DependencyEntry> buildDependencyGraph(List<Constraint> constraints) {
    final graph = <int, DependencyEntry>{};

    for (final constraint in constraints) {
      switch (constraint.type) {
        case ConstraintType.midpoint:
          // Midpoint depends on its two parent points
          final midpoint = constraint.elements[0] as GPoint;
          final p1 = constraint.elements[1] as GPoint;
          final p2 = constraint.elements[2] as GPoint;
          graph[midpoint.id] = DependencyEntry(constraint, {p1.id, p2.id});
          break;

        case ConstraintType.interLL:
          // Line-line intersection depends on both lines
          final intersection = constraint.elements[0] as GPoint;
          final line1 = constraint.elements[1] as GLine;
          final line2 = constraint.elements[2] as GLine;
          final deps = <int>{};
          deps.addAll(_getLineDependencies(line1));
          deps.addAll(_getLineDependencies(line2));
          graph[intersection.id] = DependencyEntry(constraint, deps);
          break;

        case ConstraintType.interLC:
          // Line-circle intersection depends on line and circle
          final intersection = constraint.elements[0] as GPoint;
          final line = constraint.elements[1] as GLine;
          final circle = constraint.elements[2] as GCircle;
          final deps = <int>{};
          deps.addAll(_getLineDependencies(line));
          deps.addAll(_getCircleDependencies(circle));
          graph[intersection.id] = DependencyEntry(constraint, deps);
          break;

        case ConstraintType.interCC:
          // Circle-circle intersection depends on both circles
          final intersection = constraint.elements[0] as GPoint;
          final circle1 = constraint.elements[1] as GCircle;
          final circle2 = constraint.elements[2] as GCircle;
          final deps = <int>{};
          deps.addAll(_getCircleDependencies(circle1));
          deps.addAll(_getCircleDependencies(circle2));
          graph[intersection.id] = DependencyEntry(constraint, deps);
          break;

        case ConstraintType.onLine:
          // Point on line depends on the line
          final point = constraint.elements[0] as GPoint;
          final line = constraint.elements[1] as GLine;
          graph[point.id] = DependencyEntry(
            constraint,
            _getLineDependencies(line),
          );
          break;

        case ConstraintType.onCircle:
          // Point on circle depends on the circle
          final point = constraint.elements[0] as GPoint;
          final circle = constraint.elements[1] as GCircle;
          graph[point.id] = DependencyEntry(
            constraint,
            _getCircleDependencies(circle),
          );
          break;

        case ConstraintType.perpendicular:
          // Perpendicular line depends on the reference line
          final perpLine = constraint.elements[0] as GLine;
          final refLine = constraint.elements[1] as GLine;
          final deps = <int>{};
          deps.addAll(_getLineDependencies(refLine));
          graph[perpLine.id] = DependencyEntry(constraint, deps);
          // Also make the perpendicular line's points dependent on the reference line
          for (final point in perpLine.points) {
            graph[point.id] = DependencyEntry(constraint, deps);
          }
          break;

        case ConstraintType.parallel:
          // Parallel line depends on the reference line
          final parallelLine = constraint.elements[0] as GLine;
          final refLine = constraint.elements[1] as GLine;
          final deps = <int>{};
          deps.addAll(_getLineDependencies(refLine));
          graph[parallelLine.id] = DependencyEntry(constraint, deps);
          // Also make the parallel line's points dependent on the reference line
          for (final point in parallelLine.points) {
            graph[point.id] = DependencyEntry(constraint, deps);
          }
          break;

        case ConstraintType.eqDistance:
          // Equal distance constraints would require more complex solving
          break;
      }
    }

    return graph;
  }

  /// Gets all points that a line depends on
  Set<int> _getLineDependencies(GLine line) {
    final deps = <int>{};
    for (final point in line.points) {
      deps.add(point.id);
    }
    return deps;
  }

  /// Gets all points that a circle depends on
  Set<int> _getCircleDependencies(GCircle circle) {
    final deps = <int>{};
    deps.add(circle.center.id);
    for (final point in circle.points) {
      deps.add(point.id);
    }
    return deps;
  }

  /// Finds all objects that transitively depend on a given set of objects
  Set<int> findTransitiveDependents(
    Set<int> changedObjects,
    Map<int, DependencyEntry> dependencyGraph,
  ) {
    final allDependents = <int>{};
    final toProcess = <int>{}..addAll(changedObjects);

    while (toProcess.isNotEmpty) {
      final current = toProcess.first;
      toProcess.remove(current);

      // Find all objects that depend on the current object
      for (final entry in dependencyGraph.entries) {
        if (entry.value.dependents.contains(current) &&
            !allDependents.contains(entry.key)) {
          allDependents.add(entry.key);
          toProcess.add(entry.key);
        }
      }
    }

    return allDependents;
  }

  /// Determines if an object can be freely dragged (has no constraints making it dependent)
  bool canDragFree(int objectId, Map<int, DependencyEntry> dependencyGraph) {
    if (!dependencyGraph.containsKey(objectId)) {
      return true;
    }

    // Perpendicular s can be dragged freely
    // TODO this works weirdly in (e.g) a constructed angle bisector.
    return dependencyGraph[objectId]?.constraint.type ==
        ConstraintType.perpendicular;
  }

  /// Determines if an object can be dragged in a constrained way (e.g., sliding along a line/circle)
  bool canDragConstrained(int objectId, List<Constraint> constraints) {
    for (final constraint in constraints) {
      if (constraint.elements.isNotEmpty &&
          constraint.elements[0].id == objectId) {
        // This object is constrained - check if it's a "semi-free" constraint type
        return constraint.type == ConstraintType.onLine ||
            constraint.type == ConstraintType.onCircle;
      }
    }
    return false;
  }

  /// Updates all constraints that depend on changed objects
  void updateConstraints(
    Set<int> affectedObjects,
    List<Constraint> constraints,
    List<GPoint> points,
    List<GLine> lines,
    List<GCircle> circles,
  ) {
    final objectMap = <int, GeometricObject>{};

    // Build lookup map
    for (final point in points) {
      objectMap[point.id] = point;
    }
    for (final line in lines) {
      objectMap[line.id] = line;
    }
    for (final circle in circles) {
      objectMap[circle.id] = circle;
    }

    // Update circle geometry when defining points change
    _updateCircleGeometry(affectedObjects, circles);

    // Update constraints in order (simpler constraints first)
    final orderedConstraints = _orderConstraintsByComplexity(constraints);

    for (final constraint in orderedConstraints) {
      // Check if any element in the constraint is affected (not just the first element)
      bool shouldUpdate = false;
      for (final element in constraint.elements) {
        if (affectedObjects.contains(element.id)) {
          shouldUpdate = true;
          break;
        }
      }

      if (shouldUpdate) {
        _updateConstraint(constraint, objectMap);
      }
    }
  }

  /// Updates circle geometry when their defining points move
  void _updateCircleGeometry(Set<int> affectedObjects, List<GCircle> circles) {
    for (final circle in circles) {
      if (circle.circleType == CircleType.threePoint) {
        // For three-point circles, check if any of the three defining points moved
        bool needsUpdate = false;
        for (final point in circle.points) {
          if (affectedObjects.contains(point.id)) {
            needsUpdate = true;
            break;
          }
        }

        if (needsUpdate && circle.points.length >= 3) {
          // Recalculate the circumcenter
          final p1 = circle.points[0];
          final p2 = circle.points[1];
          final p3 = circle.points[2];
          final newCenter = _calculateCircumcenter(p1, p2, p3);
          circle.center.setXY(newCenter.x, newCenter.y);
        }
      }
      // For other circle types (pointBased, radius), geometry updates automatically
      // through point references
    }
  }

  /// Calculates the circumcenter of three points using determinant method
  GPoint _calculateCircumcenter(GPoint p1, GPoint p2, GPoint p3) {
    final d =
        2 *
        (p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y));

    if (d.abs() < 1e-10) {
      // Points are collinear, return midpoint of first two points as fallback
      return GPoint.withCoordinates((p1.x + p2.x) / 2, (p1.y + p2.y) / 2);
    }

    final ux =
        (p1.x * p1.x + p1.y * p1.y) * (p2.y - p3.y) +
        (p2.x * p2.x + p2.y * p2.y) * (p3.y - p1.y) +
        (p3.x * p3.x + p3.y * p3.y) * (p1.y - p2.y);

    final uy =
        (p1.x * p1.x + p1.y * p1.y) * (p3.x - p2.x) +
        (p2.x * p2.x + p2.y * p2.y) * (p1.x - p3.x) +
        (p3.x * p3.x + p3.y * p3.y) * (p2.x - p1.x);

    return GPoint.withCoordinates(ux / d, uy / d);
  }

  /// Orders constraints by complexity for proper solving sequence
  List<Constraint> _orderConstraintsByComplexity(List<Constraint> constraints) {
    final ordered = <Constraint>[];

    // Add simple constraints first
    for (final constraint in constraints) {
      if (constraint.type == ConstraintType.midpoint) {
        ordered.add(constraint);
      }
    }

    // Add intersection constraints
    for (final constraint in constraints) {
      if (constraint.type == ConstraintType.interLL ||
          constraint.type == ConstraintType.interLC ||
          constraint.type == ConstraintType.interCC) {
        ordered.add(constraint);
      }
    }

    // Add containment constraints
    for (final constraint in constraints) {
      if (constraint.type == ConstraintType.onLine ||
          constraint.type == ConstraintType.onCircle) {
        ordered.add(constraint);
      }
    }

    // Add remaining constraints
    for (final constraint in constraints) {
      if (!ordered.contains(constraint)) {
        ordered.add(constraint);
      }
    }

    return ordered;
  }

  /// Updates a single constraint based on its type
  void _updateConstraint(
    Constraint constraint,
    Map<int, GeometricObject> objectMap,
  ) {
    switch (constraint.type) {
      case ConstraintType.midpoint:
        _updateMidpointConstraint(constraint);
        break;

      case ConstraintType.interLL:
        _updateLineLineIntersection(constraint);
        break;

      case ConstraintType.interLC:
        _updateLineCircleIntersection(constraint);
        break;

      case ConstraintType.interCC:
        _updateCircleCircleIntersection(constraint);
        break;

      case ConstraintType.onLine:
        _updatePointOnLine(constraint);
        break;

      case ConstraintType.onCircle:
        _updatePointOnCircle(constraint);
        break;

      case ConstraintType.perpendicular:
        _updatePerpendicularConstraint(constraint);
        break;

      case ConstraintType.parallel:
        _updateParallelConstraint(constraint);
        break;

      case ConstraintType.eqDistance:
        // Equal distance constraints would require more complex solving
        break;
    }
  }

  /// Updates midpoint constraint
  void _updateMidpointConstraint(Constraint constraint) {
    final midpoint = constraint.elements[0] as GPoint;
    final p1 = constraint.elements[1] as GPoint;
    final p2 = constraint.elements[2] as GPoint;

    final newX = (p1.x + p2.x) / 2;
    final newY = (p1.y + p2.y) / 2;

    midpoint.setXY(newX, newY);
  }

  /// Updates line-line intersection constraint using existing calculator
  void _updateLineLineIntersection(Constraint constraint) {
    final intersection = constraint.elements[0] as GPoint;
    final line1 = constraint.elements[1] as GLine;
    final line2 = constraint.elements[2] as GLine;

    try {
      final result = _intersectionCalculator.calculateLineLineIntersection(
        line1,
        line2,
      );
      if (result != null) {
        intersection.setXY(result.x, result.y);
      }
    } catch (e) {
      // Keep current position if calculation fails
    }
  }

  /// Updates line-circle intersection constraint using existing calculator
  void _updateLineCircleIntersection(Constraint constraint) {
    final intersection = constraint.elements[0] as GPoint;
    final line = constraint.elements[1] as GLine;
    final circle = constraint.elements[2] as GCircle;

    try {
      final results = _intersectionCalculator.calculateLineCircleIntersections(
        line,
        circle,
      );
      if (results.isNotEmpty) {
        // Use the closest intersection to current position
        GPoint closest = results[0];
        double minDistance = intersection.distanceTo(closest);

        for (final result in results) {
          final distance = intersection.distanceTo(result);
          if (distance < minDistance) {
            minDistance = distance;
            closest = result;
          }
        }

        intersection.setXY(closest.x, closest.y);
      }
    } catch (e) {
      // Keep current position if calculation fails
    }
  }

  /// Updates circle-circle intersection constraint using existing calculator
  void _updateCircleCircleIntersection(Constraint constraint) {
    final intersection = constraint.elements[0] as GPoint;
    final circle1 = constraint.elements[1] as GCircle;
    final circle2 = constraint.elements[2] as GCircle;

    try {
      final results = _intersectionCalculator
          .calculateCircleCircleIntersections(circle1, circle2);
      if (results.isNotEmpty) {
        // Use the closest intersection to current position
        GPoint closest = results[0];
        double minDistance = intersection.distanceTo(closest);

        for (final result in results) {
          final distance = intersection.distanceTo(result);
          if (distance < minDistance) {
            minDistance = distance;
            closest = result;
          }
        }

        intersection.setXY(closest.x, closest.y);
      }
    } catch (e) {
      // Keep current position if calculation fails
    }
  }

  /// Updates point constrained to lie on a line
  void _updatePointOnLine(Constraint constraint) {
    final point = constraint.elements[0] as GPoint;
    final line = constraint.elements[1] as GLine;

    // Project point onto line
    final closest = line.getClosestPoint(point);
    point.setXY(closest.x, closest.y);
  }

  /// Updates point constrained to lie on a circle
  void _updatePointOnCircle(Constraint constraint) {
    final point = constraint.elements[0] as GPoint;
    final circle = constraint.elements[1] as GCircle;

    // Project point onto circle
    final closest = circle.getClosestPoint(point);
    point.setXY(closest.x, closest.y);
  }

  /// Updates perpendicular line constraint
  void _updatePerpendicularConstraint(Constraint constraint) {
    final perpLine = constraint.elements[0] as GLine;
    final refLine = constraint.elements[1] as GLine;

    if (perpLine.points.length < 2 || refLine.points.length < 2) return;

    // Get reference line direction
    final refP1 = refLine.points[0];
    final refP2 = refLine.points[1];
    final refDx = refP2.x - refP1.x;
    final refDy = refP2.y - refP1.y;

    // Get perpendicular line's first point (anchor point)
    final perpP1 = perpLine.points[0];
    final perpP2 = perpLine.points[1];

    // Calculate perpendicular direction (rotate reference by 90 degrees)
    final perpDx = -refDy; // Perpendicular direction
    final perpDy = refDx;

    // Maintain the distance from first point to second point
    final currentDistance = perpP1.distanceTo(perpP2);
    final length = math.sqrt(perpDx * perpDx + perpDy * perpDy);

    if (length > 0) {
      // Normalize and scale to maintain distance
      final normalizedDx = perpDx / length * currentDistance;
      final normalizedDy = perpDy / length * currentDistance;

      // Update second point to maintain perpendicular relationship
      perpP2.setXY(perpP1.x + normalizedDx, perpP1.y + normalizedDy);
    }
  }

  /// Updates parallel line constraint
  void _updateParallelConstraint(Constraint constraint) {
    final parallelLine = constraint.elements[0] as GLine;
    final refLine = constraint.elements[1] as GLine;

    if (parallelLine.points.length < 2 || refLine.points.length < 2) return;

    // Get reference line direction
    final refP1 = refLine.points[0];
    final refP2 = refLine.points[1];
    final refDx = refP2.x - refP1.x;
    final refDy = refP2.y - refP1.y;

    // Get parallel line's first point (anchor point)
    final parallelP1 = parallelLine.points[0];
    final parallelP2 = parallelLine.points[1];

    // Maintain the distance from first point to second point
    final currentDistance = parallelP1.distanceTo(parallelP2);
    final length = math.sqrt(refDx * refDx + refDy * refDy);

    if (length > 0) {
      // Normalize and scale to maintain distance
      final normalizedDx = refDx / length * currentDistance;
      final normalizedDy = refDy / length * currentDistance;

      // Update second point to maintain parallel relationship
      parallelP2.setXY(
        parallelP1.x + normalizedDx,
        parallelP1.y + normalizedDy,
      );
    }
  }
}
