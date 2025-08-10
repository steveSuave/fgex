// lib/services/snap_service.dart
import '../models/models.dart';
import 'intersection_calculator.dart';

const double maxSnapDistance = 15.0;

class SnapService {
  final IntersectionCalculator _intersectionCalculator =
      IntersectionCalculator();

  /// Main entry point for selecting an object.
  /// If an object is snapped, returns it. Otherwise, returns a new point at the pointer's location.
  GeometricObject selectObject(GPoint pointer, List<GeometricObject> objects) {
    final snapped = getHighlightedObject(pointer, objects);
    return snapped ?? pointer;
  }

  /// Main entry point for highlighting an object.
  /// Returns the highest-priority snapped object, or null if nothing is close enough.
  GeometricObject? getHighlightedObject(
    GPoint pointer,
    List<GeometricObject> objects,
  ) {
    final nearbyObjects = _filterNearby(objects, pointer);

    // Priority Order:
    // 1. Existing Points
    // 2. Intersections
    // 3. Points on Lines/Circles
    final snappedExistingPoint = _snapToExistingPoints(pointer, nearbyObjects);
    if (snappedExistingPoint != null) return snappedExistingPoint;

    final snappedIntersection = _snapToIntersections(pointer, nearbyObjects);
    if (snappedIntersection != null) return snappedIntersection;

    final snappedPointOnLarge = _snapToPointsOnLarges(pointer, nearbyObjects);
    if (snappedPointOnLarge != null) return snappedPointOnLarge;

    return null;
  }

  // --- Private Helper Methods ---

  /// Filters a list of objects to those "close" to the pointer.
  List<GeometricObject> _filterNearby(
    List<GeometricObject> objects,
    GPoint pointer,
  ) {
    return objects
        .where((obj) => obj.distanceToPoint(pointer) <= maxSnapDistance)
        .toList();
  }

  /// Finds the closest object in a list to the pointer.
  T? _selectClosest<T extends GeometricObject>(
    List<T> options,
    GPoint pointer,
  ) {
    if (options.isEmpty) return null;

    T? closest;
    double minDistance = double.infinity;

    for (final obj in options) {
      final distance = obj.distanceToPoint(pointer);
      if (distance < minDistance) {
        minDistance = distance;
        closest = obj;
      }
    }
    return closest;
  }

  /// Generates all intersection points between pairs of objects in a list.
  List<GPoint> _getIntersections(List<GeometricObject> objects) {
    final intersections = <GPoint>[];
    final larges = objects
        .where(
          (o) =>
              o.type == GeometricObjectType.line ||
              o.type == GeometricObjectType.circle,
        )
        .toList();

    for (int i = 0; i < larges.length; i++) {
      for (int j = i + 1; j < larges.length; j++) {
        final obj1 = larges[i];
        final obj2 = larges[j];

        try {
          if (obj1 is GLine && obj2 is GLine) {
            final intersection = _intersectionCalculator
                .calculateLineLineIntersection(obj1, obj2);
            if (intersection != null) intersections.add(intersection);
          } else if (obj1 is GLine && obj2 is GCircle) {
            intersections.addAll(
              _intersectionCalculator.calculateLineCircleIntersections(
                obj1,
                obj2,
              ),
            );
          } else if (obj1 is GCircle && obj2 is GLine) {
            intersections.addAll(
              _intersectionCalculator.calculateLineCircleIntersections(
                obj2,
                obj1,
              ),
            );
          } else if (obj1 is GCircle && obj2 is GCircle) {
            intersections.addAll(
              _intersectionCalculator.calculateCircleCircleIntersections(
                obj1,
                obj2,
              ),
            );
          }
        } catch (e) {
          // Ignore calculation errors (e.g., parallel lines)
        }
      }
    }
    return intersections;
  }

  /// Snaps to the closest existing point.
  GPoint? _snapToExistingPoints(
    GPoint pointer,
    List<GeometricObject> nearbyObjects,
  ) {
    final points = nearbyObjects.whereType<GPoint>().toList();
    return _selectClosest(points, pointer);
  }

  /// Snaps to the closest intersection point of nearby large objects.
  GPoint? _snapToIntersections(
    GPoint pointer,
    List<GeometricObject> nearbyObjects,
  ) {
    final nearbyLarges = nearbyObjects
        .where((o) => o.type != GeometricObjectType.point)
        .toList();
    final intersections = _getIntersections(nearbyLarges);
    final nearbyIntersections = intersections
        .where((p) => p.distanceTo(pointer) <= maxSnapDistance)
        .toList();
    return _selectClosest(nearbyIntersections, pointer);
  }

  /// Snaps to the closest point on the body of a line or circle.
  GPoint? _snapToPointsOnLarges(
    GPoint pointer,
    List<GeometricObject> nearbyObjects,
  ) {
    final nearbyLarges = nearbyObjects
        .where((o) => o.type != GeometricObjectType.point)
        .toList();
    if (nearbyLarges.isEmpty) return null;

    // Find the closest point on each large object
    final closestPoints = nearbyLarges
        .map((large) => large.getClosestPoint(pointer))
        .toList();

    // Select the best among those closest points
    return _selectClosest(closestPoints, pointer);
  }
}
