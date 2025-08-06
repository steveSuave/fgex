// lib/models/line.dart
import 'geometric_object.dart';
import 'point.dart';

enum LineType {
  standard, // Standard line (formerly LLINE = 0)
  radicalAxis, // Circle-circle radical axis (formerly CCLINE = 1)
}

class GLine extends GeometricObject {
  LineType lineType;
  List<GPoint> points;

  GLine(GPoint p1, GPoint p2, {this.lineType = LineType.standard, int? id})
    : points = [p1, p2],
      super(GeometricObjectType.line, id: id);

  GLine.empty({this.lineType = LineType.standard, int? id})
    : points = [],
      super(GeometricObjectType.line, id: id);

  void addPoint(GPoint point) {
    if (!points.contains(point)) {
      points.add(point);
    }
  }

  GPoint? get firstPoint => points.isNotEmpty ? points.first : null;
  GPoint? getSecondPoint(GPoint? exclude) {
    for (var point in points) {
      if (point != exclude) return point;
    }
    return null;
  }

  bool containsBothPoints(GPoint p1, GPoint p2) {
    return points.contains(p1) && points.contains(p2);
  }

  String getDescription() {
    if (points.length >= 2) {
      return 'Line ${points[0]}${points[1]}';
    }
    return 'Line $id';
  }

  @override
  String toString() => name ?? getDescription();
}
