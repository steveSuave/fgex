// test/geometry_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geometry_expert/services/geometry_engine.dart';
import 'package:flutter_geometry_expert/exceptions/geometry_exceptions.dart';

void main() {
  group('GeometryEngine Tests', () {
    late GeometryEngine engine;

    setUp(() {
      engine = GeometryEngine();
    });

    tearDown(() {
      engine.clear();
    });

    group('Point Creation', () {
      test('should create free point with valid coordinates', () {
        final point = engine.createFreePoint(10.0, 20.0);

        expect(point.x, equals(10.0));
        expect(point.y, equals(20.0));
        expect(engine.points.length, equals(1));
        expect(engine.points.contains(point), isTrue);
      });

      test('should throw exception for infinite coordinates', () {
        expect(
          () => engine.createFreePoint(double.infinity, 20.0),
          throwsA(isA<InvalidGeometricObjectException>()),
        );
        expect(
          () => engine.createFreePoint(10.0, double.nan),
          throwsA(isA<InvalidGeometricObjectException>()),
        );
      });

      test('should create point with custom name', () {
        final point = engine.createFreePoint(5.0, 15.0, name: 'A');

        expect(point.name, equals('A'));
        expect(point.x, equals(5.0));
        expect(point.y, equals(15.0));
      });
    });

    group('Line Creation', () {
      test('should create line between two distinct points', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);

        final line = engine.createInfiniteLine(p1, p2);

        expect(line.points.length, equals(2));
        expect(line.points.contains(p1), isTrue);
        expect(line.points.contains(p2), isTrue);
        expect(engine.lines.length, equals(1));
      });

      test('should throw exception for identical points', () {
        final point = engine.createFreePoint(5.0, 5.0);

        expect(
          () => engine.createInfiniteLine(point, point),
          throwsA(isA<InvalidConstructionException>()),
        );
      });

      test('should throw exception for points at same location', () {
        final p1 = engine.createFreePoint(5.0, 5.0);
        final p2 = engine.createFreePoint(5.0, 5.0);

        expect(
          () => engine.createInfiniteLine(p1, p2),
          throwsA(isA<InvalidConstructionException>()),
        );
      });

      test('should return existing line if already exists', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);

        final line1 = engine.createInfiniteLine(p1, p2);
        final line2 = engine.createInfiniteLine(p1, p2);

        expect(identical(line1, line2), isTrue);
        expect(engine.lines.length, equals(1));
      });
    });

    group('Circle Creation', () {
      test('should create circle with center and point on circumference', () {
        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(5.0, 0.0);

        final circle = engine.createCircle(center, pointOnCircle);

        expect(circle.center, equals(center));
        expect(circle.points.contains(pointOnCircle), isTrue);
        expect(circle.getRadius(), equals(5.0));
        expect(engine.circles.length, equals(1));
      });

      test('should throw exception for identical points', () {
        final point = engine.createFreePoint(5.0, 5.0);

        expect(
          () => engine.createCircle(point, point),
          throwsA(isA<InvalidConstructionException>()),
        );
      });

      test(
        'should throw exception for points at same location (zero radius)',
        () {
          final center = engine.createFreePoint(5.0, 5.0);
          final pointOnCircle = engine.createFreePoint(5.0, 5.0);

          expect(
            () => engine.createCircle(center, pointOnCircle),
            throwsA(isA<InvalidConstructionException>()),
          );
        },
      );
    });

    group('Line-Line Intersection', () {
      test('should create intersection point for intersecting lines', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);
        final p3 = engine.createFreePoint(0.0, 10.0);
        final p4 = engine.createFreePoint(10.0, 0.0);

        final line1 = engine.createInfiniteLine(p1, p2);
        final line2 = engine.createInfiniteLine(p3, p4);

        final intersection = engine.createLineLineIntersection(line1, line2);

        expect(intersection, isNotNull);
        expect(intersection!.x, closeTo(5.0, 0.001));
        expect(intersection.y, closeTo(5.0, 0.001));
        expect(line1.points.contains(intersection), isTrue);
        expect(line2.points.contains(intersection), isTrue);
      });

      test('should return null for parallel lines', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final p3 = engine.createFreePoint(0.0, 5.0);
        final p4 = engine.createFreePoint(10.0, 5.0);

        final line1 = engine.createInfiniteLine(p1, p2);
        final line2 = engine.createInfiniteLine(p3, p4);

        final intersection = engine.createLineLineIntersection(line1, line2);

        expect(intersection, isNull);
      });

      test('should throw exception for intersecting line with itself', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);
        final line = engine.createInfiniteLine(p1, p2);

        expect(
          () => engine.createLineLineIntersection(line, line),
          throwsA(isA<InvalidConstructionException>()),
        );
      });

      test('should reuse existing point at intersection location', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);
        final p3 = engine.createFreePoint(0.0, 10.0);
        final p4 = engine.createFreePoint(10.0, 0.0);

        // Create an existing point at the intersection location
        final existingPoint = engine.createFreePoint(5.0, 5.0);
        final initialPointCount = engine.points.length;

        final line1 = engine.createInfiniteLine(p1, p2);
        final line2 = engine.createInfiniteLine(p3, p4);

        final intersection = engine.createLineLineIntersection(line1, line2);

        expect(intersection, equals(existingPoint));
        expect(
          engine.points.length,
          equals(initialPointCount),
        ); // No new point created
        expect(line1.points.contains(existingPoint), isTrue);
        expect(line2.points.contains(existingPoint), isTrue);
      });
    });

    group('Line-Circle Intersection', () {
      test('should create intersection points for line crossing circle', () {
        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(5.0, 0.0);
        final circle = engine.createCircle(center, pointOnCircle);

        final p1 = engine.createFreePoint(-10.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final line = engine.createInfiniteLine(p1, p2);

        final intersections = engine.createLineCircleIntersection(line, circle);

        expect(intersections.length, equals(2));
        expect(intersections[0].x, closeTo(-5.0, 0.001));
        expect(intersections[0].y, closeTo(0.0, 0.001));
        expect(intersections[1].x, closeTo(5.0, 0.001));
        expect(intersections[1].y, closeTo(0.0, 0.001));
      });

      test('should reuse existing points at intersection locations', () {
        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(0.0, 5.0);
        final circle = engine.createCircle(center, pointOnCircle);

        // Create existing points at intersection locations
        final existingPoint1 = engine.createFreePoint(-5.0, 0.0);
        final existingPoint2 = engine.createFreePoint(5.0, 0.0);

        final p1 = engine.createFreePoint(-10.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final line = engine.createInfiniteLine(p1, p2);

        // Count points before intersection
        final initialPointCount = engine.points.length;

        final intersections = engine.createLineCircleIntersection(line, circle);

        expect(intersections.length, equals(2));
        expect(
          engine.points.length,
          equals(initialPointCount),
        ); // No new points created
        expect(intersections.contains(existingPoint1), isTrue);
        expect(intersections.contains(existingPoint2), isTrue);
        expect(line.points.contains(existingPoint1), isTrue);
        expect(line.points.contains(existingPoint2), isTrue);
        expect(circle.points.contains(existingPoint1), isTrue);
        expect(circle.points.contains(existingPoint2), isTrue);
      });
    });

    group('Circle-Circle Intersection', () {
      test('should create intersection points for overlapping circles', () {
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

        expect(intersections.length, equals(2));
        expect(intersections[0].x, closeTo(4.0, 0.001));
        expect(intersections[1].x, closeTo(4.0, 0.001));
        expect(intersections[0].y.abs(), closeTo(3.0, 0.001));
        expect(intersections[1].y.abs(), closeTo(3.0, 0.001));
        expect(
          intersections[0].y * intersections[1].y,
          lessThan(0),
        ); // One positive, one negative
      });

      test('should reuse existing points at intersection locations', () {
        final center1 = engine.createFreePoint(0.0, 0.0);
        final point1 = engine.createFreePoint(5.0, 0.0);
        final circle1 = engine.createCircle(center1, point1);

        final center2 = engine.createFreePoint(8.0, 0.0);
        final point2 = engine.createFreePoint(13.0, 0.0);
        final circle2 = engine.createCircle(center2, point2);

        // Create existing points at intersection locations
        final existingPoint1 = engine.createFreePoint(4.0, 3.0);
        final existingPoint2 = engine.createFreePoint(4.0, -3.0);
        final initialPointCount = engine.points.length;

        final intersections = engine.createCircleCircleIntersection(
          circle1,
          circle2,
        );

        expect(intersections.length, equals(2));
        expect(
          engine.points.length,
          equals(initialPointCount),
        ); // No new points created
        expect(intersections.contains(existingPoint1), isTrue);
        expect(intersections.contains(existingPoint2), isTrue);
        expect(circle1.points.contains(existingPoint1), isTrue);
        expect(circle1.points.contains(existingPoint2), isTrue);
        expect(circle2.points.contains(existingPoint1), isTrue);
        expect(circle2.points.contains(existingPoint2), isTrue);
      });
    });

    group('Point Selection', () {
      test('should select point within tolerance', () {
        final point = engine.createFreePoint(10.0, 20.0);

        final selected = engine.selectPointAt(10.1, 19.9);

        expect(selected, equals(point));
      });

      test('should return null when no point is within tolerance', () {
        engine.createFreePoint(10.0, 20.0);

        final selected = engine.selectPointAt(50.0, 50.0);

        expect(selected, isNull);
      });

      test('should return closest point when multiple points exist', () {
        final point1 = engine.createFreePoint(10.0, 10.0);
        engine.createFreePoint(15.0, 15.0);

        final selected = engine.selectPointAt(11.0, 11.0);

        expect(selected, equals(point1));
      });
    });

    group('Clear Operations', () {
      test('should clear all objects and reset counters', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);
        final p3 = engine.createFreePoint(5.0, 0.0);

        engine.createInfiniteLine(p1, p2);
        engine.createCircle(p1, p3);

        expect(engine.points.length, greaterThan(0));
        expect(engine.lines.length, greaterThan(0));
        expect(engine.circles.length, greaterThan(0));

        engine.clear();

        expect(engine.points.length, equals(0));
        expect(engine.lines.length, equals(0));
        expect(engine.circles.length, equals(0));
        expect(engine.constraints.length, equals(0));
      });
    });
  });
}
