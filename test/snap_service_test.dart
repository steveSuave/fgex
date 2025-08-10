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

      final snappedObject = snapService.getSnapPoint(pointer, objects);

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

      final snappedObject = snapService.getSnapPoint(pointer, objects);

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

    test(
      'getSnapPoint returns point on circle while getHighlightedObject returns circle',
      () {
        final circle = GCircle.withPoint(
          GPoint.withCoordinates(50, 50),
          GPoint.withCoordinates(100, 50),
        );
        final pointer = GPoint.withCoordinates(
          90,
          50,
        ); // Near circumference, away from center
        final objects = <GeometricObject>[circle];

        final highlightedObject = snapService.getHighlightedObject(
          pointer,
          objects,
        );
        final snapPoint = snapService.getSnapPoint(pointer, objects);

        expect(highlightedObject, isA<GCircle>());
        expect(highlightedObject, equals(circle));
        expect(snapPoint, isA<GPoint>());
        expect((snapPoint as GPoint).x, closeTo(100, 0.001));
        expect(snapPoint.y, closeTo(50, 0.001));
      },
    );

    test(
      'getSnapPoint returns point on line while getHighlightedObject returns line',
      () {
        final line = GInfiniteLine(
          GPoint.withCoordinates(0, 0),
          GPoint.withCoordinates(100, 100),
        );
        final pointer = GPoint.withCoordinates(52, 50);
        final objects = <GeometricObject>[line];

        final highlightedObject = snapService.getHighlightedObject(
          pointer,
          objects,
        );
        final snapPoint = snapService.getSnapPoint(pointer, objects);

        expect(highlightedObject, isA<GLine>());
        expect(highlightedObject, equals(line));
        expect(snapPoint, isA<GPoint>());
        expect((snapPoint as GPoint).x, closeTo(51, 0.001));
        expect(snapPoint.y, closeTo(51, 0.001));
      },
    );

    test('getSnapPoint returns existing point when snapping to point', () {
      final point = GPoint.withCoordinates(50, 50);
      final pointer = GPoint.withCoordinates(52, 52);
      final objects = <GeometricObject>[point];

      final highlightedObject = snapService.getHighlightedObject(
        pointer,
        objects,
      );
      final snapPoint = snapService.getSnapPoint(pointer, objects);

      expect(highlightedObject, equals(point));
      expect(snapPoint, equals(point));
    });

    test('getSnapPoint returns pointer when no snap available', () {
      final point = GPoint.withCoordinates(100, 100);
      final pointer = GPoint.withCoordinates(10, 10);
      final objects = <GeometricObject>[point];

      final highlightedObject = snapService.getHighlightedObject(
        pointer,
        objects,
      );
      final snapPoint = snapService.getSnapPoint(pointer, objects);

      expect(highlightedObject, isNull);
      expect(snapPoint, equals(pointer));
    });
  });
}
