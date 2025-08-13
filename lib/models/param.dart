// lib/models/param.dart
class Param {
  int youth;
  double value;
  bool isStatic;

  Param(this.youth, this.value, {this.isStatic = false});

  void setParameterStatic() {
    isStatic = true;
  }
}
