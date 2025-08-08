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

        final line1 = GInfiniteLine(p1, p2);
        final line2 = GInfiniteLine(p3, p4);

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

        final line1 = GInfiniteLine(p1, p2);
        final line2 = GInfiniteLine(p3, p4);

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

        final line1 = GInfiniteLine(p1, p2);
        final line2 = GInfiniteLine(p3, p4);

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

        final line1 = GInfiniteLine(p1, p2);
        final line2 = GInfiniteLine(p3, p4);

        final intersection = calculator.calculateLineLineIntersection(
          line1,
          line2,
        );

        expect(intersection, isNull);
      });

      test('should throw exception for line with insufficient points', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 10.0);

        final line1 = GInfiniteLine.empty(lineType: LineType.standard);
        line1.addPoint(p1);
        final line2 = GInfiniteLine(p1, p2);

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
        final line = GInfiniteLine(p1, p2);

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
        final line = GInfiniteLine(p1, p2);

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
        final line = GInfiniteLine(p1, p2);

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
        final line = GInfiniteLine(p1, p2);

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
        final line = GInfiniteLine(p1, p2);

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
        final line = GInfiniteLine(point, point);

        expect(
          () => calculator.calculateLineCircleIntersections(line, circle),
          throwsA(isA<InvalidConstructionException>()),
        );
      });

      test('should throw exception for line with insufficient points', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final pointOnCircle = GPoint.withCoordinates(5.0, 0.0);
        final circle = GCircle.withPoint(center, pointOnCircle);

        final line = GInfiniteLine.empty(lineType: LineType.standard);
        line.addPoint(GPoint.withCoordinates(0.0, 0.0));

        expect(
          () => calculator.calculateLineCircleIntersections(line, circle),
          throwsA(isA<InvalidConstructionException>()),
        );
      });
    });

    group('Ray Intersection Tests', () {
      test('should find intersection when rays cross each other', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 0.0);
        final p3 = GPoint.withCoordinates(5.0, 5.0);
        final p4 = GPoint.withCoordinates(5.0, -5.0);

        final ray1 = GRay(p1, p2); // Ray from (0,0) towards (10,0)
        final ray2 = GRay(p3, p4); // Ray from (5,5) towards (5,-5)

        final intersection = calculator.calculateLineLineIntersection(
          ray1,
          ray2,
        );

        expect(intersection, isNotNull);
        expect(intersection!.x, closeTo(5.0, 0.001));
        expect(intersection.y, closeTo(0.0, 0.001));
      });

      test('should return null when ray intersection is behind ray origin', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 0.0);
        final p3 = GPoint.withCoordinates(-5.0, 5.0);
        final p4 = GPoint.withCoordinates(-5.0, -5.0);

        final ray1 = GRay(p1, p2); // Ray from (0,0) towards (10,0)
        final ray2 = GRay(p3, p4); // Ray from (-5,5) towards (-5,-5)

        final intersection = calculator.calculateLineLineIntersection(
          ray1,
          ray2,
        );

        expect(
          intersection,
          isNull,
        ); // Intersection at (-5,0) is behind ray1's origin
      });
    });

    group('Segment Intersection Tests', () {
      test('should find intersection when segments cross', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 10.0);
        final p3 = GPoint.withCoordinates(0.0, 10.0);
        final p4 = GPoint.withCoordinates(10.0, 0.0);

        final segment1 = GSegment(p1, p2);
        final segment2 = GSegment(p3, p4);

        final intersection = calculator.calculateLineLineIntersection(
          segment1,
          segment2,
        );

        expect(intersection, isNotNull);
        expect(intersection!.x, closeTo(5.0, 0.001));
        expect(intersection.y, closeTo(5.0, 0.001));
      });

      test('should return null when segments do not cross', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(5.0, 5.0);
        final p3 = GPoint.withCoordinates(6.0, 6.0);
        final p4 = GPoint.withCoordinates(10.0, 10.0);

        final segment1 = GSegment(p1, p2);
        final segment2 = GSegment(p3, p4);

        final intersection = calculator.calculateLineLineIntersection(
          segment1,
          segment2,
        );

        expect(
          intersection,
          isNull,
        ); // Lines would intersect but segments don't overlap
      });
    });

    group('Mixed Line Type Intersections', () {
      test('should handle infinite line and ray intersection', () {
        final p1 = GPoint.withCoordinates(-10.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 0.0);
        final p3 = GPoint.withCoordinates(5.0, 5.0);
        final p4 = GPoint.withCoordinates(5.0, -5.0);

        final line = GInfiniteLine(p1, p2);
        final ray = GRay(p3, p4);

        final intersection = calculator.calculateLineLineIntersection(
          line,
          ray,
        );

        expect(intersection, isNotNull);
        expect(intersection!.x, closeTo(5.0, 0.001));
        expect(intersection.y, closeTo(0.0, 0.001));
      });

      test('should handle ray and segment intersection', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 0.0);
        final p3 = GPoint.withCoordinates(5.0, -5.0);
        final p4 = GPoint.withCoordinates(5.0, 5.0);

        final ray = GRay(p1, p2);
        final segment = GSegment(p3, p4);

        final intersection = calculator.calculateLineLineIntersection(
          ray,
          segment,
        );

        expect(intersection, isNotNull);
        expect(intersection!.x, closeTo(5.0, 0.001));
        expect(intersection.y, closeTo(0.0, 0.001));
      });
    });

    group('Circle-Circle Intersection', () {
      test('should find two intersections for overlapping circles', () {
        final center1 = GPoint.withCoordinates(0.0, 0.0);
        final point1 = GPoint.withCoordinates(5.0, 0.0);
        final circle1 = GCircle.withPoint(
          center1,
          point1,
        ); // Radius 5 at origin

        final center2 = GPoint.withCoordinates(8.0, 0.0);
        final point2 = GPoint.withCoordinates(13.0, 0.0);
        final circle2 = GCircle.withPoint(center2, point2); // Radius 5 at (8,0)

        final intersections = calculator.calculateCircleCircleIntersections(
          circle1,
          circle2,
        );

        expect(intersections.length, equals(2));
        // For circles with centers (0,0) and (8,0) both with radius 5:
        // Intersection points are at (4, 3) and (4, -3)
        expect(intersections[0].x, closeTo(4.0, 0.001));
        expect(
          intersections[0].y.abs(),
          closeTo(3.0, 0.001),
        ); // Allow for either +3 or -3
        expect(intersections[1].x, closeTo(4.0, 0.001));
        expect(
          intersections[1].y.abs(),
          closeTo(3.0, 0.001),
        ); // Allow for either +3 or -3
        // Ensure we have one positive and one negative y value
        expect(intersections[0].y * intersections[1].y, lessThan(0));
      });

      test('should find one intersection for tangent circles', () {
        final center1 = GPoint.withCoordinates(0.0, 0.0);
        final point1 = GPoint.withCoordinates(5.0, 0.0);
        final circle1 = GCircle.withPoint(
          center1,
          point1,
        ); // Radius 5 at origin

        final center2 = GPoint.withCoordinates(10.0, 0.0);
        final point2 = GPoint.withCoordinates(15.0, 0.0);
        final circle2 = GCircle.withPoint(
          center2,
          point2,
        ); // Radius 5 at (10,0)

        final intersections = calculator.calculateCircleCircleIntersections(
          circle1,
          circle2,
        );

        expect(intersections.length, equals(1));
        expect(intersections[0].x, closeTo(5.0, 0.001));
        expect(intersections[0].y, closeTo(0.0, 0.001));
      });

      test('should find no intersections for separate circles', () {
        final center1 = GPoint.withCoordinates(0.0, 0.0);
        final point1 = GPoint.withCoordinates(3.0, 0.0);
        final circle1 = GCircle.withPoint(
          center1,
          point1,
        ); // Radius 3 at origin

        final center2 = GPoint.withCoordinates(10.0, 0.0);
        final point2 = GPoint.withCoordinates(13.0, 0.0);
        final circle2 = GCircle.withPoint(
          center2,
          point2,
        ); // Radius 3 at (10,0)

        final intersections = calculator.calculateCircleCircleIntersections(
          circle1,
          circle2,
        );

        expect(intersections.isEmpty, isTrue);
      });

      test('should handle concentric circles', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final point1 = GPoint.withCoordinates(3.0, 0.0);
        final point2 = GPoint.withCoordinates(5.0, 0.0);
        final circle1 = GCircle.withPoint(center, point1); // Radius 3
        final circle2 = GCircle.withPoint(center, point2); // Radius 5

        final intersections = calculator.calculateCircleCircleIntersections(
          circle1,
          circle2,
        );

        expect(
          intersections.isEmpty,
          isTrue,
        ); // Concentric circles don't intersect
      });
    });

    group('Edge Cases', () {
      test('should handle intersection at origin', () {
        final p1 = GPoint.withCoordinates(-5.0, 0.0);
        final p2 = GPoint.withCoordinates(5.0, 0.0);
        final p3 = GPoint.withCoordinates(0.0, -5.0);
        final p4 = GPoint.withCoordinates(0.0, 5.0);

        final line1 = GInfiniteLine(p1, p2);
        final line2 = GInfiniteLine(p3, p4);

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

        final line1 = GInfiniteLine(p1, p2);
        final line2 = GInfiniteLine(p3, p4);

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
