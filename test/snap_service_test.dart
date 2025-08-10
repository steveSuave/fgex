import 'package:flutter_geometry_expert/models/models.dart';
import 'package:flutter_geometry_expert/services/snap_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SnapService', () {
    late SnapService snapService;

    setUp(() {
      snapService = SnapService();
    });

    test('should snap to an existing point', () {
      final point1 = GPoint.withCoordinates(10, 10);
      final point2 = GPoint.withCoordinates(100, 100);
      final pointer = GPoint.withCoordinates(12, 12);
      final objects = <GeometricObject>[point1, point2];

      final snappedObject = snapService.getHighlightedObject(pointer, objects);

      expect(snappedObject, equals(point1));
    });

    test('should snap to an intersection', () {
      final line1 = GInfiniteLine(
        GPoint.withCoordinates(0, 50),
        GPoint.withCoordinates(100, 50),
      );
      final line2 = GInfiniteLine(
        GPoint.withCoordinates(50, 0),
        GPoint.withCoordinates(50, 100),
      );
      final pointer = GPoint.withCoordinates(52, 52);
      final objects = <GeometricObject>[line1, line2];

      final snappedObject = snapService.getHighlightedObject(pointer, objects);

      expect(snappedObject, isA<GPoint>());
      expect((snappedObject as GPoint).x, closeTo(50, 0.001));
      expect((snappedObject).y, closeTo(50, 0.001));
    });

    test('should snap to a point on a line', () {
      final line = GInfiniteLine(
        GPoint.withCoordinates(0, 0),
        GPoint.withCoordinates(100, 100),
      );
      final pointer = GPoint.withCoordinates(52, 50);
      final objects = <GeometricObject>[line];

      final snappedObject = snapService.getHighlightedObject(pointer, objects);

      expect(snappedObject, isA<GPoint>());
      expect((snappedObject as GPoint).x, closeTo(51, 0.001));
      expect((snappedObject).y, closeTo(51, 0.001));
    });

    test('should snap to a point on a circle', () {
      final circle = GCircle.withPoint(
        GPoint.withCoordinates(50, 50),
        GPoint.withCoordinates(100, 50),
      );
      final pointer = GPoint.withCoordinates(10, 50);
      final objects = <GeometricObject>[circle];

      final snappedObject = snapService.getHighlightedObject(pointer, objects);

      expect(snappedObject, isA<GPoint>());
      expect((snappedObject as GPoint).x, closeTo(0, 0.001));
      expect((snappedObject).y, closeTo(50, 0.001));
    });

    test('should return null if no object is close enough', () {
      final point = GPoint.withCoordinates(100, 100);
      final pointer = GPoint.withCoordinates(10, 10);
      final objects = <GeometricObject>[point];

      final snappedObject = snapService.getHighlightedObject(pointer, objects);

      expect(snappedObject, isNull);
    });
  });
}
