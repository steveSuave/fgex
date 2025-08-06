// test/intersection_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geometry_expert/services/intersection_calculator.dart';
import 'package:flutter_geometry_expert/models/models.dart';
import 'package:flutter_geometry_expert/exceptions/geometry_exceptions.dart';

void main() {
  group('IntersectionCalculator Tests', () {
    late IntersectionCalculator calculator;

    setUp(() {
      calculator = IntersectionCalculator();
    });

    group('Line-Line Intersection', () {
      test('should calculate intersection of perpendicular lines', () {
        final p1 = GPoint.withCoordinates(0.0, 5.0);
        final p2 = GPoint.withCoordinates(10.0, 5.0);
        final p3 = GPoint.withCoordinates(5.0, 0.0);
        final p4 = GPoint.withCoordinates(5.0, 10.0);

        final line1 = GLine(p1, p2);
        final line2 = GLine(p3, p4);

        final intersection = calculator.calculateLineLineIntersection(
          line1,
          line2,
        );

        expect(intersection, isNotNull);
        expect(intersection!.x, closeTo(5.0, 0.001));
        expect(intersection.y, closeTo(5.0, 0.001));
      });

      test('should calculate intersection of diagonal lines', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 10.0);
        final p3 = GPoint.withCoordinates(0.0, 10.0);
        final p4 = GPoint.withCoordinates(10.0, 0.0);

        final line1 = GLine(p1, p2);
        final line2 = GLine(p3, p4);

        final intersection = calculator.calculateLineLineIntersection(
          line1,
          line2,
        );

        expect(intersection, isNotNull);
        expect(intersection!.x, closeTo(5.0, 0.001));
        expect(intersection.y, closeTo(5.0, 0.001));
      });

      test('should return null for parallel horizontal lines', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 0.0);
        final p3 = GPoint.withCoordinates(0.0, 5.0);
        final p4 = GPoint.withCoordinates(10.0, 5.0);

        final line1 = GLine(p1, p2);
        final line2 = GLine(p3, p4);

        final intersection = calculator.calculateLineLineIntersection(
          line1,
          line2,
        );

        expect(intersection, isNull);
      });

      test('should return null for parallel diagonal lines', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 10.0);
        final p3 = GPoint.withCoordinates(0.0, 5.0);
        final p4 = GPoint.withCoordinates(10.0, 15.0);

        final line1 = GLine(p1, p2);
        final line2 = GLine(p3, p4);

        final intersection = calculator.calculateLineLineIntersection(
          line1,
          line2,
        );

        expect(intersection, isNull);
      });

      test('should throw exception for line with insufficient points', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 10.0);

        final line1 = GLine.empty(lineType: LineType.standard);
        line1.addPoint(p1);
        final line2 = GLine(p1, p2);

        expect(
          () => calculator.calculateLineLineIntersection(line1, line2),
          throwsA(isA<InvalidConstructionException>()),
        );
      });
    });

    group('Line-Circle Intersection', () {
      test('should find two intersections for line crossing circle', () {
        final center = GPoint.withCoordinates(5.0, 5.0);
        final pointOnCircle = GPoint.withCoordinates(8.0, 5.0);
        final circle = GCircle.withPoint(center, pointOnCircle);

        final p1 = GPoint.withCoordinates(2.0, 5.0);
        final p2 = GPoint.withCoordinates(8.0, 5.0);
        final line = GLine(p1, p2);

        final intersections = calculator.calculateLineCircleIntersections(
          line,
          circle,
        );

        expect(intersections.length, equals(2));
        expect(intersections[0].x, closeTo(2.0, 0.001));
        expect(intersections[0].y, closeTo(5.0, 0.001));
        expect(intersections[1].x, closeTo(8.0, 0.001));
        expect(intersections[1].y, closeTo(5.0, 0.001));
      });

      test('should find one intersection for line tangent to circle', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final pointOnCircle = GPoint.withCoordinates(5.0, 0.0);
        final circle = GCircle.withPoint(center, pointOnCircle);

        final p1 = GPoint.withCoordinates(-5.0, 5.0);
        final p2 = GPoint.withCoordinates(5.0, 5.0);
        final line = GLine(p1, p2);

        final intersections = calculator.calculateLineCircleIntersections(
          line,
          circle,
        );

        expect(intersections.length, equals(1));
        expect(intersections[0].x, closeTo(0.0, 0.001));
        expect(intersections[0].y, closeTo(5.0, 0.001));
      });

      test('should find no intersections for line missing circle', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final pointOnCircle = GPoint.withCoordinates(3.0, 0.0);
        final circle = GCircle.withPoint(center, pointOnCircle);

        final p1 = GPoint.withCoordinates(-5.0, 5.0);
        final p2 = GPoint.withCoordinates(5.0, 5.0);
        final line = GLine(p1, p2);

        final intersections = calculator.calculateLineCircleIntersections(
          line,
          circle,
        );

        expect(intersections.isEmpty, isTrue);
      });

      test('should handle vertical line intersecting circle', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final pointOnCircle = GPoint.withCoordinates(5.0, 0.0);
        final circle = GCircle.withPoint(center, pointOnCircle);

        final p1 = GPoint.withCoordinates(3.0, -10.0);
        final p2 = GPoint.withCoordinates(3.0, 10.0);
        final line = GLine(p1, p2);

        final intersections = calculator.calculateLineCircleIntersections(
          line,
          circle,
        );

        expect(intersections.length, equals(2));
        expect(intersections[0].x, closeTo(3.0, 0.001));
        expect(intersections[1].x, closeTo(3.0, 0.001));
        expect(intersections[0].y, closeTo(-4.0, 0.001));
        expect(intersections[1].y, closeTo(4.0, 0.001));
      });

      test('should throw exception for circle with invalid radius', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final circle = GCircle(center);

        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 10.0);
        final line = GLine(p1, p2);

        expect(
          () => calculator.calculateLineCircleIntersections(line, circle),
          throwsA(isA<InvalidGeometricObjectException>()),
        );
      });

      test('should throw exception for line with identical points', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final pointOnCircle = GPoint.withCoordinates(5.0, 0.0);
        final circle = GCircle.withPoint(center, pointOnCircle);

        final point = GPoint.withCoordinates(5.0, 5.0);
        final line = GLine(point, point);

        expect(
          () => calculator.calculateLineCircleIntersections(line, circle),
          throwsA(isA<InvalidConstructionException>()),
        );
      });

      test('should throw exception for line with insufficient points', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final pointOnCircle = GPoint.withCoordinates(5.0, 0.0);
        final circle = GCircle.withPoint(center, pointOnCircle);

        final line = GLine.empty(lineType: LineType.standard);
        line.addPoint(GPoint.withCoordinates(0.0, 0.0));

        expect(
          () => calculator.calculateLineCircleIntersections(line, circle),
          throwsA(isA<InvalidConstructionException>()),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle intersection at origin', () {
        final p1 = GPoint.withCoordinates(-5.0, 0.0);
        final p2 = GPoint.withCoordinates(5.0, 0.0);
        final p3 = GPoint.withCoordinates(0.0, -5.0);
        final p4 = GPoint.withCoordinates(0.0, 5.0);

        final line1 = GLine(p1, p2);
        final line2 = GLine(p3, p4);

        final intersection = calculator.calculateLineLineIntersection(
          line1,
          line2,
        );

        expect(intersection, isNotNull);
        expect(intersection!.x, closeTo(0.0, 0.001));
        expect(intersection.y, closeTo(0.0, 0.001));
      });

      test('should handle very large coordinates', () {
        final p1 = GPoint.withCoordinates(-1000.0, -1000.0);
        final p2 = GPoint.withCoordinates(1000.0, 1000.0);
        final p3 = GPoint.withCoordinates(-1000.0, 1000.0);
        final p4 = GPoint.withCoordinates(1000.0, -1000.0);

        final line1 = GLine(p1, p2);
        final line2 = GLine(p3, p4);

        final intersection = calculator.calculateLineLineIntersection(
          line1,
          line2,
        );

        expect(intersection, isNotNull);
        expect(intersection!.x, closeTo(0.0, 0.001));
        expect(intersection.y, closeTo(0.0, 0.001));
      });
    });
  });
}
