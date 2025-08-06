import 'package:flutter_geometry_expert/models/constraint.dart';

enum GeometricObjectType {
  point, // formerly POINT = 1
  line, // formerly LINE = 2
  circle, // formerly CIRCLE = 3
}

abstract class GeometricObject {
  int id;
  GeometricObjectType type;
  String? name;
  int color;
  bool visible;
  List<Constraint> constraints;

  GeometricObject(this.type, {int? id})
    : id = id ?? _generateId(),
      color = 0,
      visible = true,
      constraints = [];

  static int _idCounter = 0;
  static int _generateId() => ++_idCounter;

  /// Resets the global ID counter - use with caution
  static void resetIdCounter() {
    _idCounter = 0;
  }

  bool shouldDraw() => visible;
}
