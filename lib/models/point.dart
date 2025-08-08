// lib/models/point.dart
import 'package:flutter/material.dart';
import 'geometric_object.dart';
import 'param.dart';
import '../constants/geometry_constants.dart';

class GPoint extends GeometricObject {
  Param x1;
  Param y1;
  bool isFrozen;

  GPoint(this.x1, this.y1, {this.isFrozen = false, int? id})
    : super(GeometricObjectType.point, id: id);

  GPoint.withCoordinates(
    double x,
    double y, {
    this.isFrozen = false,
    int? id,
    int? paramStartIndex,
  }) : x1 = Param(paramStartIndex ?? _generateParamIndex(), x),
       y1 = Param((paramStartIndex ?? (_paramCounter - 1)) + 1, y),
       super(GeometricObjectType.point, id: id) {
    if (paramStartIndex == null) {
      _paramCounter++; // Only increment once more if we used auto-generated indices
    }
  }

  static int _paramCounter = 1;
  static int _generateParamIndex() => _paramCounter++;

  /// Resets the parameter counter
  static void resetParamCounter() {
    _paramCounter = 1;
  }

  double get x => x1.value;
  double get y => y1.value;

  void setXY(double x, double y) {
    x1.value = x;
    y1.value = y;
  }

  bool isSameLocation(
    double x,
    double y, {
    double tolerance = GeometryConstants.pointLocationTolerance,
  }) {
    return (this.x - x).abs() < tolerance && (this.y - y).abs() < tolerance;
  }

  Offset get offset => Offset(x, y);

  @override
  String toString() => name ?? 'P$id';
}
