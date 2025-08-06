import 'package:flutter_geometry_expert/models/constraint.dart';

abstract class GeometricObject {
  static const int POINT = 1;
  static const int LINE = 2;
  static const int CIRCLE = 3;

  int id;
  int type;
  String? name;
  int color;
  bool visible;
  List<Constraint> constraints;

  GeometricObject(this.type)
    : id = _generateId(),
      color = 0,
      visible = true,
      constraints = [];

  static int _idCounter = 0;
  static int _generateId() => ++_idCounter;

  bool shouldDraw() => visible;
}
