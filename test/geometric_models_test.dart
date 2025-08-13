// test/geometric_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geometry_expert/models/models.dart';
import 'dart:math' as math;

void main() {
  group('Geometric Models Tests', () {
    setUp(() {
      GeometricObject.resetIdCounter();
      GPoint.resetParamCounter();
    });

    group('GPoint Tests', () {
      test('should create point with coordinates', () {
        final point = GPoint.withCoordinates(10.0, 20.0);

        expect(point.x, equals(10.0));
        expect(point.y, equals(20.0));
        expect(point.type, equals(GeometricObjectType.point));
        expect(point.isFrozen, isFalse);
      });

      test('should create frozen point', () {
        final point = GPoint.withCoordinates(5.0, 15.0, isFrozen: true);

        expect(point.isFrozen, isTrue);
        expect(point.x, equals(5.0));
        expect(point.y, equals(15.0));
      });

      test('should update coordinates with setXY', () {
        final point = GPoint.withCoordinates(0.0, 0.0);

        point.setXY(25.0, 30.0);

        expect(point.x, equals(25.0));
        expect(point.y, equals(30.0));
      });

      test('should check same location with tolerance', () {
        final point = GPoint.withCoordinates(10.0, 20.0);

        expect(point.isSameLocation(10.0000005, 19.9999995), isTrue);
        expect(point.isSameLocation(10.5, 20.5), isFalse);
        expect(point.isSameLocation(10.0, 20.0), isTrue);
      });

      test('should provide offset property', () {
        final point = GPoint.withCoordinates(15.0, 25.0);
        final offset = point.offset;

        expect(offset.dx, equals(15.0));
        expect(offset.dy, equals(25.0));
      });

      test('should generate unique IDs', () {
        final point1 = GPoint.withCoordinates(0.0, 0.0);
        final point2 = GPoint.withCoordinates(1.0, 1.0);

        expect(point1.id, isNot(equals(point2.id)));
      });

      test('should use custom ID when provided', () {
        final point = GPoint.withCoordinates(0.0, 0.0, id: 999);

        expect(point.id, equals(999));
      });

      test('should display name or default toString', () {
        final pointWithName = GPoint.withCoordinates(0.0, 0.0);
        pointWithName.name = 'A';
        final pointWithoutName = GPoint.withCoordinates(1.0, 1.0);

        expect(pointWithName.toString(), equals('A'));
        expect(pointWithoutName.toString(), startsWith('P'));
      });

      test('should reset parameter counter', () {
        GPoint.withCoordinates(0.0, 0.0);
        GPoint.withCoordinates(1.0, 1.0);

        GPoint.resetParamCounter();
        final point = GPoint.withCoordinates(2.0, 2.0);

        expect(point.x1.youth, equals(1));
        expect(point.y1.youth, equals(2));
      });

      test('should calculate distance to another point', () {
        final point1 = GPoint.withCoordinates(0, 0);
        final point2 = GPoint.withCoordinates(3, 4);
        expect(point1.distanceTo(point2), equals(5));
      });

      test('getClosestPoint should return itself', () {
        final point1 = GPoint.withCoordinates(10, 20);
        final point2 = GPoint.withCoordinates(30, 40);
        expect(point1.getClosestPoint(point2), equals(point1));
      });
    });

    group('GLine Tests', () {
      test('should create line with two points', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 10.0);
        final line = GInfiniteLine(p1, p2);

        expect(line.points.length, equals(2));
        expect(line.points.contains(p1), isTrue);
        expect(line.points.contains(p2), isTrue);
        expect(line.lineType, equals(LineType.standard));
        expect(line.type, equals(GeometricObjectType.line));
      });

      test('should create line with specific type', () {
        final line = GInfiniteLine.empty(lineType: LineType.radicalAxis);

        expect(line.lineType, equals(LineType.radicalAxis));
        expect(line.points.isEmpty, isTrue);
      });

      test('should add points to line', () {
        final line = GInfiniteLine.empty(lineType: LineType.standard);
        final p1 = GPoint.withCoordinates(5.0, 5.0);
        final p2 = GPoint.withCoordinates(15.0, 15.0);

        line.addPoint(p1);
        line.addPoint(p2);

        expect(line.points.length, equals(2));
        expect(line.points.contains(p1), isTrue);
        expect(line.points.contains(p2), isTrue);
      });

      test('should not add duplicate points', () {
        final line = GInfiniteLine.empty(lineType: LineType.standard);
        final point = GPoint.withCoordinates(5.0, 5.0);

        line.addPoint(point);
        line.addPoint(point);

        expect(line.points.length, equals(1));
        expect(line.points.contains(point), isTrue);
      });

      test('should check if point is on line', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 10.0);
        final p3 = GPoint.withCoordinates(5.0, 5.0);
        final line = GInfiniteLine(p1, p2);

        line.addPoint(p3);

        expect(line.points.contains(p1), isTrue);
        expect(line.points.contains(p2), isTrue);
        expect(line.points.contains(p3), isTrue);

        final p4 = GPoint.withCoordinates(20.0, 20.0);
        expect(line.points.contains(p4), isFalse);
      });

      test('should provide meaningful description', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 10.0);
        p1.name = 'A';
        p2.name = 'B';

        final line = GInfiniteLine(p1, p2);
        final description = line.getDescription();

        expect(description, contains('A'));
        expect(description, contains('B'));
        expect(description, contains('Line'));
      });

      test('getClosestPoint on GInfiniteLine', () {
        final line = GInfiniteLine(
          GPoint.withCoordinates(0, 0),
          GPoint.withCoordinates(100, 0),
        );
        final point = GPoint.withCoordinates(50, 50);
        final closestPoint = line.getClosestPoint(point);
        expect(closestPoint.x, closeTo(50, 0.001));
        expect(closestPoint.y, closeTo(0, 0.001));
      });

      test('getClosestPoint on GRay', () {
        final ray = GRay(
          GPoint.withCoordinates(0, 0),
          GPoint.withCoordinates(100, 0),
        );
        final point1 = GPoint.withCoordinates(50, 50);
        final closestPoint1 = ray.getClosestPoint(point1);
        expect(closestPoint1.x, closeTo(50, 0.001));
        expect(closestPoint1.y, closeTo(0, 0.001));

        final point2 = GPoint.withCoordinates(-50, 50);
        final closestPoint2 = ray.getClosestPoint(point2);
        expect(closestPoint2.x, closeTo(0, 0.001));
        expect(closestPoint2.y, closeTo(0, 0.001));
      });

      test('getClosestPoint on GSegment', () {
        final segment = GSegment(
          GPoint.withCoordinates(0, 0),
          GPoint.withCoordinates(100, 0),
        );
        final point1 = GPoint.withCoordinates(50, 50);
        final closestPoint1 = segment.getClosestPoint(point1);
        expect(closestPoint1.x, closeTo(50, 0.001));
        expect(closestPoint1.y, closeTo(0, 0.001));

        final point2 = GPoint.withCoordinates(-50, 50);
        final closestPoint2 = segment.getClosestPoint(point2);
        expect(closestPoint2.x, closeTo(0, 0.001));
        expect(closestPoint2.y, closeTo(0, 0.001));

        final point3 = GPoint.withCoordinates(150, 50);
        final closestPoint3 = segment.getClosestPoint(point3);
        expect(closestPoint3.x, closeTo(100, 0.001));
        expect(closestPoint3.y, closeTo(0, 0.001));
      });
    });

    group('GCircle Tests', () {
      test('should create circle with center and point on circumference', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final pointOnCircle = GPoint.withCoordinates(5.0, 0.0);
        final circle = GCircle.withPoint(center, pointOnCircle);

        expect(circle.center, equals(center));
        expect(circle.points.contains(pointOnCircle), isTrue);
        expect(circle.circleType, equals(CircleType.pointBased));
        expect(circle.type, equals(GeometricObjectType.circle));
        expect(circle.getRadius(), closeTo(5.0, 0.001));
      });

      test('should create circle with just center', () {
        final center = GPoint.withCoordinates(10.0, 10.0);
        final circle = GCircle(center);

        expect(circle.center, equals(center));
        expect(circle.points.isEmpty, isTrue);
        expect(circle.getRadius(), equals(0.0));
      });

      test('should create circle with specific type', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final circle = GCircle(center, circleType: CircleType.radius);

        expect(circle.circleType, equals(CircleType.radius));
      });

      test('should calculate radius correctly', () {
        final center = GPoint.withCoordinates(3.0, 4.0);
        final pointOnCircle = GPoint.withCoordinates(6.0, 8.0);
        final circle = GCircle.withPoint(center, pointOnCircle);

        final expectedRadius = math.sqrt((6 - 3) * (6 - 3) + (8 - 4) * (8 - 4));
        expect(circle.getRadius(), closeTo(expectedRadius, 0.001));
      });

      test('should return zero radius for circle without points', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final circle = GCircle(center);

        expect(circle.getRadius(), equals(0.0));
      });

      test('should add points to circle', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final circle = GCircle(center);
        final p1 = GPoint.withCoordinates(5.0, 0.0);
        final p2 = GPoint.withCoordinates(0.0, 5.0);

        circle.addPoint(p1);
        circle.addPoint(p2);

        expect(circle.points.length, equals(2));
        expect(circle.points.contains(p1), isTrue);
        expect(circle.points.contains(p2), isTrue);
      });

      test('should not add duplicate points', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final circle = GCircle(center);
        final point = GPoint.withCoordinates(5.0, 0.0);

        circle.addPoint(point);
        circle.addPoint(point);

        expect(circle.points.length, equals(1));
        expect(circle.points.contains(point), isTrue);
      });

      test('should check if point is on circle', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final pointOnCircle = GPoint.withCoordinates(5.0, 0.0);
        final circle = GCircle.withPoint(center, pointOnCircle);

        expect(circle.isPointOnCircle(pointOnCircle), isTrue);

        final otherPoint = GPoint.withCoordinates(10.0, 10.0);
        expect(circle.isPointOnCircle(otherPoint), isFalse);
      });

      test('should provide meaningful description', () {
        final center = GPoint.withCoordinates(5.0, 10.0);
        center.name = 'O';
        final circle = GCircle(center);

        final description = circle.getDescription();
        expect(description, contains('Circle'));
        expect(description, contains('O'));
      });

      test('should use name or description in toString', () {
        final center = GPoint.withCoordinates(0.0, 0.0);
        final circleWithName = GCircle(center);
        circleWithName.name = 'MyCircle';

        final circleWithoutName = GCircle(center);

        expect(circleWithName.toString(), equals('MyCircle'));
        expect(circleWithoutName.toString(), contains('Circle'));
      });

      test('should create three-point circle', () {
        final center = GPoint.withCoordinates(2.0, 2.0);
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(4.0, 0.0);
        final p3 = GPoint.withCoordinates(2.0, 4.0);
        final circle = GCircle.threePoint(center, [p1, p2, p3]);

        expect(circle.circleType, equals(CircleType.threePoint));
        expect(circle.center, equals(center));
        expect(circle.points.length, equals(3));
        expect(circle.points.contains(p1), isTrue);
        expect(circle.points.contains(p2), isTrue);
        expect(circle.points.contains(p3), isTrue);
      });

      test('getClosestPoint on GCircle', () {
        final circle = GCircle.withPoint(
          GPoint.withCoordinates(0, 0),
          GPoint.withCoordinates(100, 0),
        );
        final point = GPoint.withCoordinates(200, 0);
        final closestPoint = circle.getClosestPoint(point);
        expect(closestPoint.x, closeTo(100, 0.001));
        expect(closestPoint.y, closeTo(0, 0.001));
      });
    });

    group('Constraint Tests', () {
      test('should create constraint with type and elements', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 10.0);
        final line = GInfiniteLine(p1, p2);

        final constraint = Constraint(ConstraintType.interLL, [p1, line]);

        expect(constraint.type, equals(ConstraintType.interLL));
        expect(constraint.elements.length, equals(2));
        expect(constraint.elements.contains(p1), isTrue);
        expect(constraint.elements.contains(line), isTrue);
      });

      test('should provide meaningful description', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(10.0, 10.0);
        // TODO check validity of this test
        final constraint = Constraint(ConstraintType.interLL, [p1, p2]);

        expect(constraint.type, equals(ConstraintType.interLL));
      });
    });

    group('GeometricObject Base Tests', () {
      test('should generate sequential IDs', () {
        GeometricObject.resetIdCounter();

        final obj1 = GPoint.withCoordinates(0.0, 0.0);
        final obj2 = GInfiniteLine.empty(lineType: LineType.standard);
        final obj3 = GCircle(GPoint.withCoordinates(0.0, 0.0));

        expect(obj1.id, equals(1));
        expect(obj2.id, equals(2));
        expect(obj3.id, equals(4)); // Center point gets ID 3, circle gets ID 4
      });

      test('should reset ID counter', () {
        GPoint.withCoordinates(0.0, 0.0);

        GeometricObject.resetIdCounter();
        final obj2 = GPoint.withCoordinates(1.0, 1.0);

        expect(obj2.id, equals(1));
      });

      test('should allow custom names', () {
        final point = GPoint.withCoordinates(0.0, 0.0);
        point.name = 'CustomPoint';

        expect(point.name, equals('CustomPoint'));
      });
    });

    group('Enum Tests', () {
      test('should have correct line type values', () {
        expect(LineType.values.length, equals(2));
        expect(LineType.values.contains(LineType.standard), isTrue);
        expect(LineType.values.contains(LineType.radicalAxis), isTrue);
      });

      test('should have correct circle type values', () {
        expect(CircleType.values.length, equals(4));
        expect(CircleType.values.contains(CircleType.pointBased), isTrue);
        expect(CircleType.values.contains(CircleType.radius), isTrue);
        expect(CircleType.values.contains(CircleType.special), isTrue);
        expect(CircleType.values.contains(CircleType.threePoint), isTrue);
      });

      test('should have correct geometric object type values', () {
        expect(GeometricObjectType.values.length, equals(3));
        expect(
          GeometricObjectType.values.contains(GeometricObjectType.point),
          isTrue,
        );
        expect(
          GeometricObjectType.values.contains(GeometricObjectType.line),
          isTrue,
        );
        expect(
          GeometricObjectType.values.contains(GeometricObjectType.circle),
          isTrue,
        );
      });

      test('should have correct constraint type values', () {
        expect(ConstraintType.values.length, greaterThan(0));
        expect(ConstraintType.values.contains(ConstraintType.interLL), isTrue);
        expect(ConstraintType.values.contains(ConstraintType.interLC), isTrue);
      });
    });
  });
}
