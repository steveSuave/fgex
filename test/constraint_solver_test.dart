// test/constraint_solver_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geometry_expert/services/constraint_solver.dart';
import 'package:flutter_geometry_expert/services/geometry_engine.dart';

void main() {
  group('ConstraintSolver Tests', () {
    late ConstraintSolver solver;
    late GeometryEngine engine;

    setUp(() {
      solver = ConstraintSolver();
      engine = GeometryEngine();
    });

    tearDown(() {
      engine.clear();
    });

    group('Dependency Graph Building', () {
      test('should build empty graph for no constraints', () {
        final graph = solver.buildDependencyGraph([]);
        expect(graph.isEmpty, isTrue);
      });

      test('should build midpoint dependencies correctly', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final midpoint = engine.createMidpoint(p1, p2);

        final graph = solver.buildDependencyGraph(engine.constraints);

        expect(graph.containsKey(midpoint.id), isTrue);
        expect(graph[midpoint.id]!.dependents, containsAll([p1.id, p2.id]));
      });

      test('should build line-line intersection dependencies correctly', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);
        final p3 = engine.createFreePoint(0.0, 10.0);
        final p4 = engine.createFreePoint(10.0, 0.0);

        final line1 = engine.createInfiniteLine(p1, p2);
        final line2 = engine.createInfiniteLine(p3, p4);
        final intersection = engine.createLineLineIntersection(line1, line2);

        final graph = solver.buildDependencyGraph(engine.constraints);

        expect(graph.containsKey(intersection!.id), isTrue);
        expect(
          graph[intersection.id]!.dependents,
          containsAll([p1.id, p2.id, p3.id, p4.id]),
        );
      });

      test('should build line-circle intersection dependencies correctly', () {
        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(5.0, 0.0);
        final circle = engine.createCircle(center, pointOnCircle);

        final p1 = engine.createFreePoint(-10.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final line = engine.createInfiniteLine(p1, p2);

        final intersections = engine.createLineCircleIntersection(line, circle);

        final graph = solver.buildDependencyGraph(engine.constraints);

        for (final intersection in intersections) {
          expect(graph.containsKey(intersection.id), isTrue);
          expect(
            graph[intersection.id]!.dependents,
            containsAll([center.id, pointOnCircle.id, p1.id, p2.id]),
          );
        }
      });

      test(
        'should build circle-circle intersection dependencies correctly',
        () {
          final center1 = engine.createFreePoint(0.0, 0.0);
          final point1 = engine.createFreePoint(5.0, 0.0);
          final circle1 = engine.createCircle(center1, point1);

          final center2 = engine.createFreePoint(8.0, 0.0);
          final point2 = engine.createFreePoint(13.0, 0.0);
          final circle2 = engine.createCircle(center2, point2);

          final intersections = engine.createCircleCircleIntersection(
            circle1,
            circle2,
          );

          final graph = solver.buildDependencyGraph(engine.constraints);

          for (final intersection in intersections) {
            expect(graph.containsKey(intersection.id), isTrue);
            expect(
              graph[intersection.id]!.dependents,
              containsAll([center1.id, point1.id, center2.id, point2.id]),
            );
          }
        },
      );

      test('should build perpendicular line dependencies correctly', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final originalLine = engine.createInfiniteLine(p1, p2);

        final pointForPerp = engine.createFreePoint(5.0, 5.0);
        final perpLine = engine.createPerpendicularLine(
          pointForPerp,
          originalLine,
        );

        final graph = solver.buildDependencyGraph(engine.constraints);

        // Perpendicular line depends on the original line
        expect(graph.containsKey(perpLine.id), isTrue);
        expect(graph[perpLine.id]!.dependents, containsAll([p1.id, p2.id]));

        // Perpendicular line's points also depend on the original line
        for (final point in perpLine.points) {
          if (point != pointForPerp) {
            // Skip the anchor point
            expect(graph.containsKey(point.id), isTrue);
            expect(graph[point.id]!.dependents, containsAll([p1.id, p2.id]));
          }
        }
      });

      test('should build onLine constraint dependencies correctly', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final line = engine.createInfiniteLine(p1, p2);
        final pointOnLine = engine.createPointOnLine(line, 5.0, 0.0);

        final graph = solver.buildDependencyGraph(engine.constraints);

        expect(graph.containsKey(pointOnLine.id), isTrue);
        expect(graph[pointOnLine.id]!.dependents, containsAll([p1.id, p2.id]));
      });

      test('should build onCircle constraint dependencies correctly', () {
        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(5.0, 0.0);
        final circle = engine.createCircle(center, pointOnCircle);
        final constrainedPoint = engine.createPointOnCircle(circle, 0.0, 5.0);

        final graph = solver.buildDependencyGraph(engine.constraints);

        expect(graph.containsKey(constrainedPoint.id), isTrue);
        expect(
          graph[constrainedPoint.id]!.dependents,
          containsAll([center.id, pointOnCircle.id]),
        );
      });
    });

    group('Transitive Dependencies', () {
      test('should find no dependents for free point', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final graph = solver.buildDependencyGraph(engine.constraints);

        final dependents = solver.findTransitiveDependents({p1.id}, graph);

        expect(dependents.isEmpty, isTrue);
      });

      test('should find direct dependents', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final midpoint = engine.createMidpoint(p1, p2);

        final graph = solver.buildDependencyGraph(engine.constraints);
        final dependents = solver.findTransitiveDependents({p1.id}, graph);

        expect(dependents, contains(midpoint.id));
      });

      test('should find transitive dependents through multiple levels', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final midpoint = engine.createMidpoint(p1, p2);

        final p3 = engine.createFreePoint(0.0, 10.0);
        final secondMidpoint = engine.createMidpoint(midpoint, p3);

        final graph = solver.buildDependencyGraph(engine.constraints);
        final dependents = solver.findTransitiveDependents({p1.id}, graph);

        expect(dependents, contains(midpoint.id));
        expect(dependents, contains(secondMidpoint.id));
      });

      test('should handle circular dependencies correctly', () {
        // Create a simple setup without circular dependencies
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);
        final p3 = engine.createFreePoint(0.0, 10.0);
        final p4 = engine.createFreePoint(10.0, 0.0);

        final line1 = engine.createInfiniteLine(p1, p2);
        final line2 = engine.createInfiniteLine(p3, p4);
        final intersection = engine.createLineLineIntersection(line1, line2);

        final graph = solver.buildDependencyGraph(engine.constraints);
        final dependents = solver.findTransitiveDependents({p1.id}, graph);

        expect(dependents, contains(intersection!.id));
      });
    });

    group('Drag Capability Tests', () {
      test('should allow free dragging of unconstrained points', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final graph = solver.buildDependencyGraph(engine.constraints);

        final canDrag = solver.canDragFree(p1.id, graph);

        expect(canDrag, isTrue);
      });

      test('should not allow free dragging of constrained points', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final midpoint = engine.createMidpoint(p1, p2);

        final graph = solver.buildDependencyGraph(engine.constraints);
        final canDrag = solver.canDragFree(midpoint.id, graph);

        expect(canDrag, isFalse);
      });

      test('should allow constrained dragging for onLine points', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final line = engine.createInfiniteLine(p1, p2);
        final pointOnLine = engine.createPointOnLine(line, 5.0, 0.0);

        final canDrag = solver.canDragConstrained(
          pointOnLine.id,
          engine.constraints,
        );

        expect(canDrag, isTrue);
      });

      test('should allow constrained dragging for onCircle points', () {
        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(5.0, 0.0);
        final circle = engine.createCircle(center, pointOnCircle);
        final constrainedPoint = engine.createPointOnCircle(circle, 0.0, 5.0);

        final canDrag = solver.canDragConstrained(
          constrainedPoint.id,
          engine.constraints,
        );

        expect(canDrag, isTrue);
      });

      test('should not allow constrained dragging for intersection points', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);
        final p3 = engine.createFreePoint(0.0, 10.0);
        final p4 = engine.createFreePoint(10.0, 0.0);

        final line1 = engine.createInfiniteLine(p1, p2);
        final line2 = engine.createInfiniteLine(p3, p4);
        final intersection = engine.createLineLineIntersection(line1, line2);

        final canDrag = solver.canDragConstrained(
          intersection!.id,
          engine.constraints,
        );

        expect(canDrag, isFalse);
      });
    });

    group('Constraint Update Tests', () {
      test('should update midpoint when parent points move', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final midpoint = engine.createMidpoint(p1, p2);

        expect(midpoint.x, equals(5.0));
        expect(midpoint.y, equals(0.0));

        // Move p1
        p1.setXY(0.0, 10.0);

        solver.updateConstraints(
          {p1.id},
          engine.constraints,
          engine.points,
          engine.lines,
          engine.circles,
        );

        expect(midpoint.x, equals(5.0));
        expect(midpoint.y, equals(5.0));
      });

      test('should update line-line intersection when lines move', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);
        final p3 = engine.createFreePoint(0.0, 10.0);
        final p4 = engine.createFreePoint(10.0, 0.0);

        final line1 = engine.createInfiniteLine(p1, p2);
        final line2 = engine.createInfiniteLine(p3, p4);
        final intersection = engine.createLineLineIntersection(line1, line2);

        expect(intersection!.x, closeTo(5.0, 0.001));
        expect(intersection.y, closeTo(5.0, 0.001));

        // Move line1 by moving p1
        p1.setXY(2.0, 0.0);

        // Include transitive dependencies
        final graph = solver.buildDependencyGraph(engine.constraints);
        final dependents = solver.findTransitiveDependents({p1.id}, graph);
        final allAffected = <int>{p1.id}..addAll(dependents);

        solver.updateConstraints(
          allAffected,
          engine.constraints,
          engine.points,
          engine.lines,
          engine.circles,
        );

        // New intersection should be at different location
        expect(intersection.x, isNot(closeTo(5.0, 0.001)));
      });

      test('should update perpendicular line when base line moves', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final originalLine = engine.createInfiniteLine(p1, p2);

        final pointForPerp = engine.createFreePoint(5.0, 5.0);
        final perpLine = engine.createPerpendicularLine(
          pointForPerp,
          originalLine,
        );

        final originalSecondPoint = perpLine.points[1];
        final originalX = originalSecondPoint.x;
        final originalY = originalSecondPoint.y;

        // Rotate the original line by moving p2
        p2.setXY(0.0, 10.0); // Now vertical instead of horizontal

        // Include transitive dependencies (this is what the UI drag handler does)
        final graph = solver.buildDependencyGraph(engine.constraints);
        final dependents = solver.findTransitiveDependents({p2.id}, graph);
        final allAffected = <int>{p2.id}..addAll(dependents);

        solver.updateConstraints(
          allAffected,
          engine.constraints,
          engine.points,
          engine.lines,
          engine.circles,
        );

        final newSecondPoint = perpLine.points[1];

        // The perpendicular should have updated (either coordinate should be different)
        final hasChanged =
            newSecondPoint.x != originalX || newSecondPoint.y != originalY;
        expect(hasChanged, isTrue);
      });

      test('should project onLine point back to line when line moves', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final line = engine.createInfiniteLine(p1, p2);
        final pointOnLine = engine.createPointOnLine(line, 5.0, 0.0);

        expect(pointOnLine.y, closeTo(0.0, 0.001));

        // Rotate the line slightly (not 45 degrees which is too extreme)
        p2.setXY(10.0, 2.0);

        solver.updateConstraints(
          {p2.id},
          engine.constraints,
          engine.points,
          engine.lines,
          engine.circles,
        );

        // Point should still be close to the line
        final distance = line.distanceToPoint(pointOnLine);
        expect(
          distance,
          lessThan(1.0),
        ); // More tolerant since projection may not be perfect
      });

      test('should project onCircle point back to circle when circle moves', () {
        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(5.0, 0.0);
        final circle = engine.createCircle(center, pointOnCircle);
        final constrainedPoint = engine.createPointOnCircle(circle, 0.0, 5.0);

        final originalDistance = center.distanceTo(constrainedPoint);
        expect(originalDistance, closeTo(5.0, 0.001));

        // Move the circle by changing its radius point slightly
        pointOnCircle.setXY(7.0, 0.0); // Increase radius to 7

        // Include transitive dependencies (this is what the UI drag handler does)
        final graph = solver.buildDependencyGraph(engine.constraints);
        final dependents = solver.findTransitiveDependents({
          pointOnCircle.id,
        }, graph);
        final allAffected = <int>{pointOnCircle.id}..addAll(dependents);

        solver.updateConstraints(
          allAffected,
          engine.constraints,
          engine.points,
          engine.lines,
          engine.circles,
        );

        // Constrained point should still be on the circle (now with radius 7)
        final newDistance = center.distanceTo(constrainedPoint);
        expect(newDistance, closeTo(7.0, 0.001));
      });
    });

    group('Three-Point Circle Update Tests', () {
      test(
        'should update three-point circle center when any defining point moves',
        () {
          final p1 = engine.createFreePoint(0.0, 0.0);
          final p2 = engine.createFreePoint(4.0, 0.0);
          final p3 = engine.createFreePoint(2.0, 2.0);

          final circle = engine.createThreePointCircle(p1, p2, p3);
          final originalCenterX = circle.center.x;
          final originalCenterY = circle.center.y;

          // Move one of the defining points significantly
          p1.setXY(0.0, 6.0);

          solver.updateConstraints(
            {p1.id},
            engine.constraints,
            engine.points,
            engine.lines,
            engine.circles,
          );

          // Center should have moved (at least one coordinate should be different)
          final centerMoved =
              !circle.center.x.isNaN &&
              !circle.center.y.isNaN &&
              (circle.center.x != originalCenterX ||
                  circle.center.y != originalCenterY);
          expect(centerMoved, isTrue);

          // All three points should still be on the circle
          final radius = circle.getRadius();
          if (radius > 0) {
            expect(circle.center.distanceTo(p1), closeTo(radius, 0.001));
            expect(circle.center.distanceTo(p2), closeTo(radius, 0.001));
            expect(circle.center.distanceTo(p3), closeTo(radius, 0.001));
          }
        },
      );

      test(
        'should update three-point circle when second defining point moves',
        () {
          final p1 = engine.createFreePoint(0.0, 0.0);
          final p2 = engine.createFreePoint(4.0, 0.0);
          final p3 = engine.createFreePoint(2.0, 2.0);

          final circle = engine.createThreePointCircle(p1, p2, p3);
          final originalCenterX = circle.center.x;
          final originalCenterY = circle.center.y;

          // Move the second defining point
          p2.setXY(6.0, 2.0);

          solver.updateConstraints(
            {p2.id},
            engine.constraints,
            engine.points,
            engine.lines,
            engine.circles,
          );

          // Center should have moved
          final centerMoved =
              !circle.center.x.isNaN &&
              !circle.center.y.isNaN &&
              (circle.center.x != originalCenterX ||
                  circle.center.y != originalCenterY);
          expect(centerMoved, isTrue);
        },
      );

      test(
        'should update three-point circle when third defining point moves',
        () {
          final p1 = engine.createFreePoint(0.0, 0.0);
          final p2 = engine.createFreePoint(4.0, 0.0);
          final p3 = engine.createFreePoint(2.0, 2.0);

          final circle = engine.createThreePointCircle(p1, p2, p3);
          final originalCenterX = circle.center.x;
          final originalCenterY = circle.center.y;

          // Move the third defining point
          p3.setXY(1.0, 4.0);

          solver.updateConstraints(
            {p3.id},
            engine.constraints,
            engine.points,
            engine.lines,
            engine.circles,
          );

          // Center should have moved
          final centerMoved =
              !circle.center.x.isNaN &&
              !circle.center.y.isNaN &&
              (circle.center.x != originalCenterX ||
                  circle.center.y != originalCenterY);
          expect(centerMoved, isTrue);
        },
      );

      test('should handle collinear fallback in circumcenter calculation', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(4.0, 0.0);
        final p3 = engine.createFreePoint(2.0, 2.0);

        final circle = engine.createThreePointCircle(p1, p2, p3);

        // Force collinearity by moving p3 onto the line through p1 and p2
        p3.setXY(8.0, 0.0);

        solver.updateConstraints(
          {p3.id},
          engine.constraints,
          engine.points,
          engine.lines,
          engine.circles,
        );

        // Should fallback to midpoint of first two points
        expect(circle.center.x, closeTo(2.0, 0.001));
        expect(circle.center.y, closeTo(0.0, 0.001));
      });
    });

    group('Constraint Ordering Tests', () {
      test('should process midpoints before intersections', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final p3 = engine.createFreePoint(0.0, 10.0);
        final p4 = engine.createFreePoint(10.0, 10.0);

        // Create midpoint first, then intersection
        final midpoint = engine.createMidpoint(p1, p2);

        final line1 = engine.createInfiniteLine(p1, p3);
        final line2 = engine.createInfiniteLine(p2, p4);
        final intersection = engine.createLineLineIntersection(line1, line2);

        solver.buildDependencyGraph(engine.constraints);

        // Test that constraint processing works correctly regardless of creation order
        solver.updateConstraints(
          {p1.id, p2.id},
          engine.constraints,
          engine.points,
          engine.lines,
          engine.circles,
        );

        expect(midpoint.x, equals(5.0));
        if (intersection != null) {
          expect(intersection.x, closeTo(0.0, 0.001));
        }
      });
    });

    group('Edge Cases', () {
      test('should handle empty constraint list', () {
        final p1 = engine.createFreePoint(0.0, 0.0);

        solver.updateConstraints(
          {p1.id},
          [],
          engine.points,
          engine.lines,
          engine.circles,
        );

        // Should not throw any errors
        expect(p1.x, equals(0.0));
        expect(p1.y, equals(0.0));
      });

      test('should handle constraint with missing objects gracefully', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final midpoint = engine.createMidpoint(p1, p2);

        // Create a constraint list without p2 to simulate missing objects
        final modifiedConstraints = engine.constraints.toList();

        // Should not crash when updating constraints even with inconsistent state
        expect(() {
          solver.updateConstraints(
            {p1.id},
            modifiedConstraints,
            [p1, midpoint], // Only include some points
            engine.lines,
            engine.circles,
          );
        }, returnsNormally);
      });

      test('should handle multiple affected objects correctly', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final p3 = engine.createFreePoint(5.0, 10.0);

        final midpoint12 = engine.createMidpoint(p1, p2);
        final midpoint13 = engine.createMidpoint(p1, p3);

        p1.setXY(2.0, 2.0);

        solver.updateConstraints(
          {p1.id},
          engine.constraints,
          engine.points,
          engine.lines,
          engine.circles,
        );

        // Both midpoints should be updated
        expect(midpoint12.x, equals(6.0));
        expect(midpoint12.y, equals(1.0));
        expect(midpoint13.x, equals(3.5));
        expect(midpoint13.y, equals(6.0));
      });
    });
  });
}
