// lib/models/point.dart
import 'package:flutter/material.dart';
import 'geometric_object.dart';
import 'param.dart';

class GPoint extends GeometricObject {
  Param x1;
  Param y1;
  bool isFrozen;

  GPoint(this.x1, this.y1, {this.isFrozen = false})
    : super(GeometricObject.POINT);

  GPoint.withCoordinates(double x, double y, {this.isFrozen = false})
    : x1 = Param(_generateParamIndex(), x),
      y1 = Param(_generateParamIndex(), y),
      super(GeometricObject.POINT);

  static int _paramCounter = 1;
  static int _generateParamIndex() => _paramCounter++;

  double get x => x1.value;
  double get y => y1.value;

  void setXY(double x, double y) {
    x1.value = x;
    y1.value = y;
  }

  bool isSameLocation(double x, double y, {double tolerance = 1e-6}) {
    return (this.x - x).abs() < tolerance && (this.y - y).abs() < tolerance;
  }

  Offset get offset => Offset(x, y);

  @override
  String toString() => name ?? 'P$id';
}
