import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_geometry_expert/services/geometry_engine.dart';
import 'package:flutter_geometry_expert/models/models.dart';

void main() {
  group('Auto Point Creation Logic Tests', () {
    late GeometryEngine engine;

    setUp(() {
      engine = GeometryEngine();
    });

    test('should create points automatically when none exist at click location for line', () {
      // Initially no points
      expect(engine.points.length, equals(0));

      // Simulate the logic from _handleLineConstruction
      const position1 = Offset(100, 100);
      final point1AtPosition = engine.selectPointAt(position1.dx, position1.dy);
      
      late GPoint firstPoint;
      if (point1AtPosition != null) {
        firstPoint = point1AtPosition;
      } else {
        firstPoint = engine.createFreePoint(position1.dx, position1.dy);
      }

      // Should have created first point
      expect(engine.points.length, equals(1));
      expect(firstPoint.x, equals(100.0));
      expect(firstPoint.y, equals(100.0));

      // Simulate second click
      const position2 = Offset(200, 150);
      final point2AtPosition = engine.selectPointAt(position2.dx, position2.dy);
      
      late GPoint secondPoint;
      if (point2AtPosition != null) {
        secondPoint = point2AtPosition;
      } else {
        secondPoint = engine.createFreePoint(position2.dx, position2.dy);
      }

      // Should have created second point
      expect(engine.points.length, equals(2));
      expect(secondPoint.x, equals(200.0));
      expect(secondPoint.y, equals(150.0));

      // Create the line
      engine.createInfiniteLine(firstPoint, secondPoint);
      
      // Should have two points and one line
      expect(engine.points.length, equals(2));
      expect(engine.lines.length, equals(1));
    });

    test('should create points automatically when none exist at click location for circle', () {
      // Initially no points
      expect(engine.points.length, equals(0));

      // Simulate the logic from _handleCircleConstruction
      const centerPosition = Offset(150, 150);
      final centerAtPosition = engine.selectPointAt(centerPosition.dx, centerPosition.dy);
      
      late GPoint centerPoint;
      if (centerAtPosition != null) {
        centerPoint = centerAtPosition;
      } else {
        centerPoint = engine.createFreePoint(centerPosition.dx, centerPosition.dy);
      }

      // Should have created center point
      expect(engine.points.length, equals(1));
      expect(centerPoint.x, equals(150.0));
      expect(centerPoint.y, equals(150.0));

      // Simulate second click for radius point
      const radiusPosition = Offset(200, 150);
      final radiusAtPosition = engine.selectPointAt(radiusPosition.dx, radiusPosition.dy);
      
      late GPoint radiusPoint;
      if (radiusAtPosition != null) {
        radiusPoint = radiusAtPosition;
      } else {
        radiusPoint = engine.createFreePoint(radiusPosition.dx, radiusPosition.dy);
      }

      // Should have created radius point
      expect(engine.points.length, equals(2));
      expect(radiusPoint.x, equals(200.0));
      expect(radiusPoint.y, equals(150.0));

      // Create the circle
      engine.createCircle(centerPoint, radiusPoint);
      
      // Should have two points and one circle
      expect(engine.points.length, equals(2));
      expect(engine.circles.length, equals(1));
      
      // Verify circle properties
      final circle = engine.circles.first;
      expect(circle.center.x, equals(150.0));
      expect(circle.center.y, equals(150.0));
      expect(circle.getRadius(), equals(50.0)); // Distance from (150,150) to (200,150)
    });

    test('should use existing points when clicked within tolerance', () {
      // Create an existing point
      final existingPoint = engine.createFreePoint(100, 100);
      expect(engine.points.length, equals(1));

      // Try to "click" near the existing point (within tolerance)
      const clickPosition = Offset(102, 98); // Within default tolerance
      final foundPoint = engine.selectPointAt(clickPosition.dx, clickPosition.dy);
      
      // Should find the existing point, not create a new one
      expect(foundPoint, isNotNull);
      expect(foundPoint!.id, equals(existingPoint.id));
      expect(engine.points.length, equals(1)); // Still only one point
    });

    test('should create new point when clicked outside tolerance of existing points', () {
      // Create an existing point
      engine.createFreePoint(100, 100);
      expect(engine.points.length, equals(1));

      // Try to "click" far from the existing point (outside tolerance)
      const clickPosition = Offset(200, 200);
      final foundPoint = engine.selectPointAt(clickPosition.dx, clickPosition.dy);
      
      // Should not find existing point
      expect(foundPoint, isNull);
      
      // Create new point at click location
      final newPoint = engine.createFreePoint(clickPosition.dx, clickPosition.dy);
      
      // Should now have two points
      expect(engine.points.length, equals(2));
      expect(newPoint.x, equals(200.0));
      expect(newPoint.y, equals(200.0));
    });

    test('should handle mixed existing and new points for shape creation', () {
      // Create one existing point
      final existingPoint = engine.createFreePoint(100, 100);
      expect(engine.points.length, equals(1));

      // First click: use existing point
      final firstPoint = engine.selectPointAt(100, 100);
      expect(firstPoint, isNotNull);
      expect(firstPoint!.id, equals(existingPoint.id));

      // Second click: create new point at different location
      const newPosition = Offset(300, 200);
      final foundPoint = engine.selectPointAt(newPosition.dx, newPosition.dy);
      expect(foundPoint, isNull); // Should not find existing point here
      
      final secondPoint = engine.createFreePoint(newPosition.dx, newPosition.dy);
      
      // Should now have two points
      expect(engine.points.length, equals(2));
      
      // Create line between existing and new point
      engine.createInfiniteLine(firstPoint, secondPoint);
      
      // Should have two points and one line
      expect(engine.points.length, equals(2));
      expect(engine.lines.length, equals(1));
      
      // Verify line connects the correct points
      final line = engine.lines.first;
      expect(line.points.contains(existingPoint), isTrue);
      expect(line.points.contains(secondPoint), isTrue);
    });
  });
}