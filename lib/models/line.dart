// lib/models/line.dart
import 'geometric_object.dart';
import 'point.dart';

class GLine extends GeometricObject {
  static const int LLINE = 0; // Standard line
  static const int CCLINE = 1; // Circle-circle radical axis
  
  int lineType;
  List<GPoint> points;
  
  GLine(GPoint p1, GPoint p2, {this.lineType = LLINE}) 
    : points = [p1, p2],
      super(GeometricObject.LINE);
  
  GLine.empty({this.lineType = LLINE}) 
    : points = [],
      super(GeometricObject.LINE);
  
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
