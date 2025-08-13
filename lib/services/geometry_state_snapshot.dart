import 'package:flutter_geometry_expert/models/circle.dart';
import 'package:flutter_geometry_expert/models/constraint.dart';
import 'package:flutter_geometry_expert/models/line.dart';
import 'package:flutter_geometry_expert/models/point.dart';

/// Snapshot of the geometry state used for undo/redo.
class GeometryStateSnapshot {
  final List<GPoint> points;
  final List<GLine> lines;
  final List<GCircle> circles;
  final List<Constraint> constraints;

  GeometryStateSnapshot({
    required this.points,
    required this.lines,
    required this.circles,
    required this.constraints,
  });
}
