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

        final line = engine.createLine(p1, p2);

        expect(line.points.length, equals(2));
        expect(line.points.contains(p1), isTrue);
        expect(line.points.contains(p2), isTrue);
        expect(engine.lines.length, equals(1));
      });

      test('should throw exception for identical points', () {
        final point = engine.createFreePoint(5.0, 5.0);

        expect(
          () => engine.createLine(point, point),
          throwsA(isA<InvalidConstructionException>()),
        );
      });

      test('should throw exception for points at same location', () {
        final p1 = engine.createFreePoint(5.0, 5.0);
        final p2 = engine.createFreePoint(5.0, 5.0);

        expect(
          () => engine.createLine(p1, p2),
          throwsA(isA<InvalidConstructionException>()),
        );
      });

      test('should return existing line if already exists', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);

        final line1 = engine.createLine(p1, p2);
        final line2 = engine.createLine(p1, p2);

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

        final line1 = engine.createLine(p1, p2);
        final line2 = engine.createLine(p3, p4);

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

        final line1 = engine.createLine(p1, p2);
        final line2 = engine.createLine(p3, p4);

        final intersection = engine.createLineLineIntersection(line1, line2);

        expect(intersection, isNull);
      });

      test('should throw exception for intersecting line with itself', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 10.0);
        final line = engine.createLine(p1, p2);

        expect(
          () => engine.createLineLineIntersection(line, line),
          throwsA(isA<InvalidConstructionException>()),
        );
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

        engine.createLine(p1, p2);
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
