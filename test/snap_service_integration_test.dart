import 'package:flutter_geometry_expert/models/models.dart';
import 'package:flutter_geometry_expert/services/geometry_engine.dart';
import 'package:flutter_geometry_expert/services/snap_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SnapService Integration Tests', () {
    late GeometryEngine engine;
    late SnapService snapService;

    setUp(() {
      engine = GeometryEngine();
      snapService = SnapService();
    });

    test('intersection tool workflow - complete line-line intersection', () {
      // Create two intersecting lines
      final line1Point1 = engine.createFreePoint(0, 50);
      final line1Point2 = engine.createFreePoint(100, 50);
      final line1 = engine.createInfiniteLine(line1Point1, line1Point2);

      final line2Point1 = engine.createFreePoint(50, 0);
      final line2Point2 = engine.createFreePoint(50, 100);
      final line2 = engine.createInfiniteLine(line2Point1, line2Point2);

      // Simulate intersection tool workflow (away from existing points)
      final pointer1 = GPoint.withCoordinates(25, 50);
      final pointer2 = GPoint.withCoordinates(50, 25);

      // First click - should highlight line1
      final highlighted1 = snapService.getHighlightedObject(
        pointer1,
        engine.getAllObjects(),
      );
      expect(highlighted1, isA<GLine>());
      expect(highlighted1, equals(line1));

      // Second click - should highlight line2
      final highlighted2 = snapService.getHighlightedObject(
        pointer2,
        engine.getAllObjects(),
      );
      expect(highlighted2, isA<GLine>());
      expect(highlighted2, equals(line2));

      // Create intersection
      final intersection = engine.createLineLineIntersection(
        highlighted1 as GLine,
        highlighted2 as GLine,
      );
      expect(intersection, isNotNull);
      expect(intersection!.x, closeTo(50, 0.001));
      expect(intersection.y, closeTo(50, 0.001));
    });

    test('intersection tool workflow - complete line-circle intersection', () {
      // Create line and circle that intersect
      final linePoint1 = engine.createFreePoint(0, 100);
      final linePoint2 = engine.createFreePoint(200, 100);
      final line = engine.createInfiniteLine(linePoint1, linePoint2);

      final circleCenter = engine.createFreePoint(100, 100);
      final circlePoint = engine.createFreePoint(125, 100);
      final circle = engine.createCircle(circleCenter, circlePoint);

      // Simulate intersection tool workflow
      // Line points: (0,100), (200,100) - Circle points: (100,100), (125,100)
      final linePointer = GPoint.withCoordinates(
        150,
        100,
      ); // On line, away from existing points
      final circlePointer = GPoint.withCoordinates(
        120,
        120,
      ); // Near circle edge, away from center

      // First click - should highlight line
      final highlightedLine = snapService.getHighlightedObject(
        linePointer,
        engine.getAllObjects(),
      );
      expect(highlightedLine, isA<GLine>());
      expect(highlightedLine, equals(line));

      // Second click - should highlight circle
      final highlightedCircle = snapService.getHighlightedObject(
        circlePointer,
        engine.getAllObjects(),
      );
      expect(highlightedCircle, isA<GCircle>());
      expect(highlightedCircle, equals(circle));

      // Create intersections
      final intersections = engine.createLineCircleIntersection(
        highlightedLine as GLine,
        highlightedCircle as GCircle,
      );
      expect(intersections, hasLength(2));
      expect(intersections[0].x, closeTo(75, 0.001));
      expect(intersections[0].y, closeTo(100, 0.001));
      expect(intersections[1].x, closeTo(125, 0.001));
      expect(intersections[1].y, closeTo(100, 0.001));
    });

    test('point creation workflow using getSnapPoint', () {
      // Create a circle
      final center = engine.createFreePoint(50, 50);
      final pointOnCircle = engine.createFreePoint(100, 50);
      engine.createCircle(center, pointOnCircle);

      // Simulate point creation near circle (far from existing points: 50,50 100,50)
      final pointer = GPoint.withCoordinates(
        50,
        85,
      ); // Near circle but far from existing points

      // getSnapPoint should return a point on the circle
      final snapPoint = snapService.getSnapPoint(
        pointer,
        engine.getAllObjects(),
      );
      expect(snapPoint, isA<GPoint>());

      final snappedPoint = snapPoint as GPoint;
      // Should be on circle circumference (distance from center = radius)
      final distanceFromCenter = snappedPoint.distanceTo(center);
      expect(distanceFromCenter, closeTo(50, 0.001));

      // If not already in engine, can create it
      if (!engine.getAllObjects().contains(snappedPoint)) {
        final newPoint = engine.createFreePoint(snappedPoint.x, snappedPoint.y);
        expect(newPoint.x, closeTo(50, 0.001));
        expect(newPoint.y, closeTo(100, 0.001));
      }
    });

    test('point creation on circle integration test', () {
      // Create a circle
      final center = engine.createFreePoint(100, 100);
      final radiusPoint = engine.createFreePoint(150, 100);
      engine.createCircle(center, radiusPoint);

      final initialPointCount = engine.getAllPoints().length;

      // Try to create a point on the circle
      final nearCirclePointer = GPoint.withCoordinates(120, 130);
      final snapPoint = snapService.getSnapPoint(
        nearCirclePointer,
        engine.getAllObjects(),
      );

      expect(snapPoint, isA<GPoint>());
      final snappedPoint = snapPoint as GPoint;

      // Verify the point is on the circle
      final distanceFromCenter = snappedPoint.distanceTo(center);
      expect(distanceFromCenter, closeTo(50, 0.001)); // radius = 50

      // Create the point in the engine
      final newPoint = engine.createFreePoint(snappedPoint.x, snappedPoint.y);
      expect(engine.getAllPoints().length, equals(initialPointCount + 1));

      // Verify the new point coordinates
      expect(newPoint.x, closeTo(snappedPoint.x, 0.001));
      expect(newPoint.y, closeTo(snappedPoint.y, 0.001));
    });

    test('point creation on line integration test', () {
      // Create a line
      final point1 = engine.createFreePoint(0, 0);
      final point2 = engine.createFreePoint(100, 100);
      engine.createInfiniteLine(point1, point2);

      final initialPointCount = engine.getAllPoints().length;

      // Try to create a point on the line
      final nearLinePointer = GPoint.withCoordinates(52, 48);
      final snapPoint = snapService.getSnapPoint(
        nearLinePointer,
        engine.getAllObjects(),
      );

      expect(snapPoint, isA<GPoint>());
      final snappedPoint = snapPoint as GPoint;

      // Verify the point is on the line (y = x for this diagonal line)
      expect(snappedPoint.x, closeTo(snappedPoint.y, 0.001));
      expect(snappedPoint.x, closeTo(50, 0.001));

      // Create the point in the engine
      engine.createFreePoint(snappedPoint.x, snappedPoint.y);
      expect(engine.getAllPoints().length, equals(initialPointCount + 1));
    });

    test('line construction using points on circles', () {
      // Create two circles
      final circle1Center = engine.createFreePoint(50, 50);
      final circle1Point = engine.createFreePoint(100, 50);
      engine.createCircle(circle1Center, circle1Point);

      final circle2Center = engine.createFreePoint(150, 50);
      final circle2Point = engine.createFreePoint(200, 50);
      engine.createCircle(circle2Center, circle2Point);

      final initialLineCount = engine.getAllObjects().whereType<GLine>().length;

      // Create points on circles using snap service
      final pointer1 = GPoint.withCoordinates(75, 75);
      final snapPoint1 = snapService.getSnapPoint(
        pointer1,
        engine.getAllObjects(),
      );
      expect(snapPoint1, isA<GPoint>());
      final point1OnCircle = engine.createFreePoint(
        (snapPoint1 as GPoint).x,
        snapPoint1.y,
      );

      final pointer2 = GPoint.withCoordinates(125, 75);
      final snapPoint2 = snapService.getSnapPoint(
        pointer2,
        engine.getAllObjects(),
      );
      expect(snapPoint2, isA<GPoint>());
      final point2OnCircle = engine.createFreePoint(
        (snapPoint2 as GPoint).x,
        snapPoint2.y,
      );

      // Verify points are on circles
      expect(point1OnCircle.distanceTo(circle1Center), closeTo(50, 0.001));
      expect(point2OnCircle.distanceTo(circle2Center), closeTo(50, 0.001));

      // Create line using these points
      final line = engine.createInfiniteLine(point1OnCircle, point2OnCircle);
      expect(
        engine.getAllObjects().whereType<GLine>().length,
        equals(initialLineCount + 1),
      );
      expect(line.points[0], equals(point1OnCircle));
      expect(line.points[1], equals(point2OnCircle));
    });
  });
}
