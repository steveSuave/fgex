// test/object_selection_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geometry_expert/services/geometry_engine.dart';
import 'package:flutter_geometry_expert/models/models.dart';

void main() {
  group('Object Selection Tests', () {
    late GeometryEngine engine;

    setUp(() {
      engine = GeometryEngine();
    });

    group('Line Selection', () {
      test('should select infinite line containing point', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final line = engine.createInfiniteLine(p1, p2);

        // Point on the line should select it
        final selectedLine = engine.selectLineAt(5.0, 0.0);
        expect(selectedLine, equals(line));
        expect(selectedLine is GInfiniteLine, isTrue);
      });

      test('should select ray containing point in valid direction', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final ray = engine.createRay(p1, p2);

        // Point on ray in valid direction should select it
        final selectedLine = engine.selectLineAt(5.0, 0.0);
        expect(selectedLine, equals(ray));
        expect(selectedLine is GRay, isTrue);
      });

      test('should not select ray for point behind origin', () {
        final p1 = engine.createFreePoint(5.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        engine.createRay(p1, p2);

        // Point behind ray origin should not select it
        final selectedLine = engine.selectLineAt(0.0, 0.0);
        expect(selectedLine, isNull);
      });

      test('should select segment containing point within bounds', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        final segment = engine.createSegment(p1, p2);

        // Point within segment bounds should select it
        final selectedLine = engine.selectLineAt(5.0, 0.0);
        expect(selectedLine, equals(segment));
        expect(selectedLine is GSegment, isTrue);
      });

      test('should not select segment for point outside bounds', () {
        final p1 = engine.createFreePoint(5.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        engine.createSegment(p1, p2);

        // Point outside segment bounds should not select it
        final selectedLine = engine.selectLineAt(0.0, 0.0);
        expect(selectedLine, isNull);
      });

      test('should return null when no line is at position', () {
        final p1 = engine.createFreePoint(0.0, 0.0);
        final p2 = engine.createFreePoint(10.0, 0.0);
        engine.createInfiniteLine(p1, p2);

        // Point far from any line should return null (using tolerance > 5.0)
        final selectedLine = engine.selectLineAt(5.0, 10.0);
        expect(selectedLine, isNull);
      });
    });

    group('Circle Selection', () {
      test('should select circle when clicking on circumference', () {
        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(5.0, 0.0);
        final circle = engine.createCircle(center, pointOnCircle);

        // Point on circumference should select circle
        final selectedCircle = engine.selectCircleAt(0.0, 5.0); // Top of circle
        expect(selectedCircle, equals(circle));
      });

      test('should not select circle when clicking inside', () {
        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(5.0, 0.0);
        engine.createCircle(center, pointOnCircle);

        // Point far inside circle should not select it (more than tolerance away from circumference)
        final selectedCircle = engine.selectCircleAt(
          0.0,
          0.0,
          tolerance: 2.0,
        ); // At center, 5 units from circumference > 2.0 tolerance
        expect(selectedCircle, isNull);
      });

      test('should not select circle when clicking outside', () {
        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(5.0, 0.0);
        engine.createCircle(center, pointOnCircle);

        // Point far outside circle should not select it (more than tolerance away from circumference)
        final selectedCircle = engine.selectCircleAt(
          15.0,
          0.0,
        ); // 10 units from circumference
        expect(selectedCircle, isNull);
      });

      test('should return null when no circle is at position', () {
        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(5.0, 0.0);
        engine.createCircle(center, pointOnCircle);

        // Point not on any circle should return null
        final selectedCircle = engine.selectCircleAt(20.0, 20.0);
        expect(selectedCircle, isNull);
      });
    });

    group('Mixed Selection', () {
      test('should select correct object when multiple objects exist', () {
        // Create a line and a circle that intersect
        final p1 = engine.createFreePoint(-5.0, 0.0);
        final p2 = engine.createFreePoint(5.0, 0.0);
        final line = engine.createInfiniteLine(p1, p2);

        final center = engine.createFreePoint(0.0, 0.0);
        final pointOnCircle = engine.createFreePoint(3.0, 0.0);
        final circle = engine.createCircle(center, pointOnCircle);

        // Should select line when clicking on line part not on circle
        final selectedLine = engine.selectLineAt(4.0, 0.0);
        expect(selectedLine, equals(line));

        // Should select circle when clicking on circle circumference
        final selectedCircle = engine.selectCircleAt(0.0, 3.0);
        expect(selectedCircle, equals(circle));
      });
    });
  });
}
