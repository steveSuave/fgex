// lib/models/param.dart
class Param {
  int xIndex;
  double value;
  bool isStatic;

  Param(this.xIndex, this.value, {this.isStatic = false});

  void setParameterStatic() {
    isStatic = true;
  }
}
