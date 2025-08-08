import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geometry_expert/models/models.dart';

void main() {
  group('Infinite Line Translation Tests', () {
    setUp(() {
      GeometricObject.resetIdCounter();
      GPoint.resetParamCounter();
    });

    group('Viewport-Aware Infinite Line Drawing', () {
      test('should calculate different endpoints based on translation', () {
        final p1 = GPoint.withCoordinates(100.0, 100.0);
        final p2 = GPoint.withCoordinates(200.0, 200.0);
        final line = GInfiniteLine(p1, p2);

        // Get endpoints with no translation
        final endpointsNoTranslation = line.getDrawingEndpoints(
          800.0,
          600.0,
          translationX: 0.0,
          translationY: 0.0,
        );

        // Get endpoints with significant translation
        final endpointsWithTranslation = line.getDrawingEndpoints(
          800.0,
          600.0,
          translationX: 1000.0,
          translationY: 800.0,
        );

        // Endpoints should be different due to different viewport bounds
        expect(endpointsNoTranslation.length, equals(2));
        expect(endpointsWithTranslation.length, equals(2));

        // At least one endpoint should be significantly different
        final ep1Diff =
            (endpointsNoTranslation[0].x - endpointsWithTranslation[0].x).abs();
        final ep2Diff =
            (endpointsNoTranslation[1].x - endpointsWithTranslation[1].x).abs();

        expect(
          ep1Diff > 100 || ep2Diff > 100,
          isTrue,
          reason: 'Endpoints should change significantly with translation',
        );
      });

      test('should extend line to cover translated viewport bounds', () {
        // Create a horizontal line that will intersect the translated viewport
        // With translationY=1000, viewport y-bounds are -1000 to -400
        // So place the line at y=-500 (within translated viewport)
        final p1 = GPoint.withCoordinates(0.0, -500.0);
        final p2 = GPoint.withCoordinates(100.0, -500.0); // Horizontal line
        final line = GInfiniteLine(p1, p2);

        // With large positive translation, viewport is shifted
        final endpoints = line.getDrawingEndpoints(
          800.0,
          600.0,
          translationX: 2000.0,
          translationY: 1000.0,
        );

        expect(endpoints.length, equals(2));

        // Line should extend to cover the translated viewport
        // Translated viewport left edge is at x = -2000, right edge at x = -1200
        // Since this is a horizontal line within the viewport y-bounds,
        // we should get intersections with left and right edges
        final minX = endpoints[0].x < endpoints[1].x
            ? endpoints[0].x
            : endpoints[1].x;
        final maxX = endpoints[0].x > endpoints[1].x
            ? endpoints[0].x
            : endpoints[1].x;

        // For a horizontal line at y=-500 within the translated viewport,
        // we should get exactly the viewport x-bounds
        expect(
          minX,
          closeTo(-2000.0, 1.0),
          reason: 'Line should start at left edge of translated viewport',
        );
        expect(
          maxX,
          closeTo(-1200.0, 1.0),
          reason: 'Line should end at right edge of translated viewport',
        );

        // Both endpoints should be at the same y-coordinate as the line
        expect(endpoints[0].y, closeTo(-500.0, 1.0));
        expect(endpoints[1].y, closeTo(-500.0, 1.0));
      });
    });

    group('Viewport-Aware Ray Drawing', () {
      test('should calculate different endpoints based on translation', () {
        final p1 = GPoint.withCoordinates(100.0, 100.0); // Ray origin
        final p2 = GPoint.withCoordinates(200.0, 200.0); // Direction point
        final ray = GRay(p1, p2);

        // Get endpoints with no translation
        final endpointsNoTranslation = ray.getDrawingEndpoints(
          800.0,
          600.0,
          translationX: 0.0,
          translationY: 0.0,
        );

        // Get endpoints with translation that moves viewport
        final endpointsWithTranslation = ray.getDrawingEndpoints(
          800.0,
          600.0,
          translationX: 1000.0,
          translationY: 800.0,
        );

        expect(endpointsNoTranslation.length, equals(2));
        expect(endpointsWithTranslation.length, equals(2));

        // First endpoint should always be the ray origin
        expect(endpointsNoTranslation[0].x, equals(100.0));
        expect(endpointsNoTranslation[0].y, equals(100.0));
        expect(endpointsWithTranslation[0].x, equals(100.0));
        expect(endpointsWithTranslation[0].y, equals(100.0));

        // Second endpoint should be different due to different viewport bounds
        final secondEndpointDiff =
            (endpointsNoTranslation[1].x - endpointsWithTranslation[1].x)
                .abs() +
            (endpointsNoTranslation[1].y - endpointsWithTranslation[1].y).abs();

        expect(
          secondEndpointDiff > 10,
          isTrue,
          reason: 'Ray endpoint should change with translation',
        );
      });

      test('should only extend in positive direction from origin', () {
        final p1 = GPoint.withCoordinates(500.0, 300.0); // Ray origin
        final p2 = GPoint.withCoordinates(600.0, 300.0); // Points right
        final ray = GRay(p1, p2);

        final endpoints = ray.getDrawingEndpoints(
          800.0,
          600.0,
          translationX: 0.0,
          translationY: 0.0,
        );

        expect(endpoints.length, equals(2));

        // First endpoint is always the origin
        expect(endpoints[0].x, equals(500.0));
        expect(endpoints[0].y, equals(300.0));

        // Second endpoint should be to the right (positive direction)
        expect(endpoints[1].x, greaterThan(500.0));
        expect(endpoints[1].y, equals(300.0)); // Same y since horizontal
      });
    });

    group('Edge Cases', () {
      test('should handle very large translation values', () {
        final p1 = GPoint.withCoordinates(0.0, 0.0);
        final p2 = GPoint.withCoordinates(1.0, 1.0);
        final line = GInfiniteLine(p1, p2);

        // Test with extremely large translation
        final endpoints = line.getDrawingEndpoints(
          800.0,
          600.0,
          translationX: 1000000.0,
          translationY: 1000000.0,
        );

        expect(endpoints.length, equals(2));
        expect(endpoints[0].x.isFinite, isTrue);
        expect(endpoints[0].y.isFinite, isTrue);
        expect(endpoints[1].x.isFinite, isTrue);
        expect(endpoints[1].y.isFinite, isTrue);
      });

      test('should handle near-vertical and near-horizontal lines', () {
        // Near-vertical line
        final p1 = GPoint.withCoordinates(100.0, 0.0);
        final p2 = GPoint.withCoordinates(100.0001, 1000.0);
        final verticalLine = GInfiniteLine(p1, p2);

        final verticalEndpoints = verticalLine.getDrawingEndpoints(
          800.0,
          600.0,
          translationX: 500.0,
          translationY: 300.0,
        );

        expect(verticalEndpoints.length, equals(2));

        // Near-horizontal line
        final p3 = GPoint.withCoordinates(0.0, 100.0);
        final p4 = GPoint.withCoordinates(1000.0, 100.0001);
        final horizontalLine = GInfiniteLine(p3, p4);

        final horizontalEndpoints = horizontalLine.getDrawingEndpoints(
          800.0,
          600.0,
          translationX: 500.0,
          translationY: 300.0,
        );

        expect(horizontalEndpoints.length, equals(2));
      });
    });
  });
}
