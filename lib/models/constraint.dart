import 'package:flutter_geometry_expert/models/geometric_object.dart';

enum ConstraintType {
  interLL, // Line-line intersection  
  interLC, // Line-circle intersection
  interCC, // Circle-circle intersection
  midpoint,
  perpendicular,
  parallel,
  eqDistance,
  onCircle,
  onLine,
}

class Constraint {
  ConstraintType type;
  List<GeometricObject> elements;
  double proportion;
  
  Constraint(this.type, this.elements, {this.proportion = 0});
  
  GeometricObject getElement(int index) => elements[index];
}
