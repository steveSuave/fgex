import 'package:flutter/material.dart';
import 'package:flutter_geometry_expert/models/models.dart';
import 'package:flutter_geometry_expert/services/constraint_solver.dart';
import 'package:flutter_geometry_expert/services/geometry_engine.dart';
import 'package:flutter_geometry_expert/services/geometry_state_snapshot.dart';
import 'package:flutter_geometry_expert/services/snap_service.dart';

import '../exceptions/geometry_exceptions.dart';

enum ConstructionMode { select, point, line, circle, translate, drag }

enum PointConstructionMode { point, intersection, midpoint }

enum LineConstructionMode { infinite, ray, segment, perpendicular }

enum CircleConstructionMode { centerPoint, threePoint }

class GeometryController extends ChangeNotifier {
  final GeometryEngine engine = GeometryEngine();
  final SnapService snapService = SnapService();
  final ConstraintSolver constraintSolver = ConstraintSolver();

  ConstructionMode _mode = ConstructionMode.select;
  PointConstructionMode _pointMode = PointConstructionMode.point;
  LineConstructionMode _lineMode = LineConstructionMode.infinite;
  CircleConstructionMode _circleMode = CircleConstructionMode.centerPoint;

  final List<GPoint> _selectedPoints = [];
  final List<GeometricObject> _selectedObjects = [];
  GeometricObject? _hoveredObject;
  GeometricObject? _draggedObject;
  Offset? _lastDragPosition;
  Offset _canvasTranslation = Offset.zero;
  String? _errorMessage;

  ConstructionMode get mode => _mode;
  PointConstructionMode get pointMode => _pointMode;
  LineConstructionMode get lineMode => _lineMode;
  CircleConstructionMode get circleMode => _circleMode;
  List<GPoint> get selectedPoints => _selectedPoints;
  List<GeometricObject> get selectedObjects => _selectedObjects;
  GeometricObject? get hoveredObject => _hoveredObject;
  GeometricObject? get draggedObject => _draggedObject;
  Offset get canvasTranslation => _canvasTranslation;
  String? get errorMessage => _errorMessage;

  final List<GeometryStateSnapshot> _undoStack = [];
  final List<GeometryStateSnapshot> _redoStack = [];

  void undo() {
    if (_undoStack.isNotEmpty) {
      final snapshot = _undoStack.removeLast();
      _redoStack.add(engine.saveState());
      engine.restoreState(snapshot);
      notifyListeners();
    }
  }

  void redo() {
    if (_redoStack.isNotEmpty) {
      final snapshot = _redoStack.removeLast();
      _undoStack.add(engine.saveState());
      engine.restoreState(snapshot);
      notifyListeners();
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
  }

  void selectTool(
    ConstructionMode newMode, [
    PointConstructionMode? newPointMode,
    LineConstructionMode? newLineMode,
    CircleConstructionMode? newCircleMode,
  ]) {
    _mode = newMode;
    if (newPointMode != null) _pointMode = newPointMode;
    if (newLineMode != null) _lineMode = newLineMode;
    if (newCircleMode != null) _circleMode = newCircleMode;
    _selectedPoints.clear();
    _selectedObjects.clear();
    notifyListeners();
  }

  void clearCanvas() {
    engine.clear();
    _selectedPoints.clear();
    _selectedObjects.clear();
    _hoveredObject = null;
    _canvasTranslation = Offset.zero;
    notifyListeners();
  }

  String getStatusMessage() {
    switch (_mode) {
      case ConstructionMode.point:
        return _getPointModeStatus();
      case ConstructionMode.line:
        return _getLineModeStatus();
      case ConstructionMode.circle:
        return _getCircleModeStatus();
      case ConstructionMode.select:
        return 'Select mode - click objects to select';
      case ConstructionMode.translate:
        return 'Pan/translate mode - drag to move the canvas';
      case ConstructionMode.drag:
        return 'Drag mode - click and drag objects to move them';
    }
  }

  String _getPointModeStatus() {
    if (_pointMode == PointConstructionMode.point) {
      return 'Click to create a point';
    }

    if (_pointMode == PointConstructionMode.midpoint) {
      return _getMidpointModeStatus();
    }

    if (_selectedObjects.isEmpty) {
      return 'Click on first object to intersect';
    }

    if (_selectedObjects.length == 1) {
      return 'Click on second object to intersect';
    }

    return 'Two objects selected - creating intersections';
  }

  String _getMidpointModeStatus() {
    if (_selectedPoints.isEmpty) {
      return 'Select first point for midpoint';
    }

    return 'Select second point for midpoint';
  }

  String _getLineTypeName() {
    const Map<LineConstructionMode, String> lineTypeNames = {
      LineConstructionMode.infinite: 'line',
      LineConstructionMode.ray: 'ray',
      LineConstructionMode.segment: 'segment',
      LineConstructionMode.perpendicular: 'perpendicular',
    };

    return lineTypeNames[_lineMode] ?? 'line';
  }

  String _getLineModeStatus() {
    final String lineTypeName = _getLineTypeName();

    if (_lineMode == LineConstructionMode.perpendicular) {
      return _getPerpendicularStatus();
    }

    if (_selectedPoints.isEmpty) {
      return 'Select first point for $lineTypeName';
    }

    return 'Select second point for $lineTypeName';
  }

  String _getPerpendicularStatus() {
    final hasPoint = _selectedPoints.isNotEmpty;
    final hasLine = _selectedObjects.any((obj) => obj is GLine);

    if (!hasPoint && !hasLine) {
      return 'Select a point and a line (any order)';
    } else if (hasPoint && !hasLine) {
      return 'Select a line for perpendicular';
    } else if (!hasPoint && hasLine) {
      return 'Select a point for perpendicular';
    }

    return 'Creating perpendicular line...';
  }

  String _getCircleModeStatus() {
    if (_circleMode == CircleConstructionMode.centerPoint) {
      return _getCenterPointCircleStatus();
    }

    return _getThreePointCircleStatus();
  }

  String _getCenterPointCircleStatus() {
    if (_selectedPoints.isEmpty) {
      return 'Select center point for circle';
    }

    return 'Select point on circle';
  }

  String _getThreePointCircleStatus() {
    if (_selectedPoints.isEmpty) {
      return 'Select first point for 3-point circle';
    }

    if (_selectedPoints.length == 1) {
      return 'Select second point for 3-point circle';
    }

    return 'Select third point for 3-point circle';
  }

  GPoint _adjustPositionForTranslation(Offset position) {
    return GPoint.withCoordinates(
      position.dx - _canvasTranslation.dx,
      position.dy - _canvasTranslation.dy,
    );
  }

  void handlePointerHover(Offset position) {
    if (_mode == ConstructionMode.translate) return;

    final pointer = _adjustPositionForTranslation(position);
    final newHoveredObject = snapService.getHighlightedObject(
      pointer,
      engine.getAllObjects(),
    );

    if (newHoveredObject != _hoveredObject) {
      _hoveredObject = newHoveredObject;
      notifyListeners();
    }
  }

  void handleTapDown(Offset position) {
    // Save current state for undo and clear redo stack.
    _undoStack.add(engine.saveState());
    _redoStack.clear();

    switch (_mode) {
      case ConstructionMode.point:
        _handlePointConstruction(position);
        break;
      case ConstructionMode.line:
        _handleLineConstruction(position);
        break;
      case ConstructionMode.circle:
        _handleCircleConstruction(position);
        break;
      case ConstructionMode.select:
        _handleSelection(position);
        break;
      case ConstructionMode.translate:
        break;
      case ConstructionMode.drag:
        _handleDragStart(position);
        break;
    }
    notifyListeners();
  }

  void handlePanUpdate(DragUpdateDetails details) {
    if (_mode == ConstructionMode.translate) {
      _canvasTranslation += details.delta;
    } else if (_mode == ConstructionMode.drag && _draggedObject != null) {
      _handleDragUpdate(details);
    }
    notifyListeners();
  }

  void handlePanStart(Offset position) {
    if (_mode == ConstructionMode.drag) {
      _handleDragStart(position);
    }
    notifyListeners();
  }

  void handlePanEnd(DragEndDetails details) {
    if (_mode == ConstructionMode.drag) {
      _draggedObject = null;
      _lastDragPosition = null;
      notifyListeners();
    }
  }

  void _handlePointConstruction(Offset position) {
    final pointer = _adjustPositionForTranslation(position);

    try {
      switch (_pointMode) {
        case PointConstructionMode.point:
          final highlightedObject = snapService.getHighlightedObject(
            pointer,
            engine.getAllObjects(),
          );
          final snapPoint = snapService.getSnapPoint(
            pointer,
            engine.getAllObjects(),
          );
          if (snapPoint is GPoint) {
            if (highlightedObject is GLine) {
              engine.createPointOnLine(
                highlightedObject,
                snapPoint.x,
                snapPoint.y,
              );
            } else if (highlightedObject is GCircle) {
              engine.createPointOnCircle(
                highlightedObject,
                snapPoint.x,
                snapPoint.y,
              );
            } else {
              createPoint(snapPoint, highlightedObject);
            }
          }
          break;
        case PointConstructionMode.intersection:
          _handleIntersection(pointer.offset);
          break;
        case PointConstructionMode.midpoint:
          _handleMidpointConstruction(pointer);
          break;
      }
    } on GeometryException catch (e) {
      _showError('Error creating point: ${e.message}');
    }
  }

  void _handleMidpointConstruction(GPoint pointer) {
    final highlightedObject = snapService.getHighlightedObject(
      pointer,
      engine.getAllObjects(),
    );
    final snappedObject = snapService.getSnapPoint(
      pointer,
      engine.getAllObjects(),
    );

    if (snappedObject is GPoint) {
      createPoint(snappedObject, highlightedObject);
    } else {
      _showError('Midpoints must be defined by points.');
      return;
    }

    if (_selectedPoints.length == 2) {
      try {
        engine.createMidpoint(_selectedPoints[0], _selectedPoints[1]);
        _selectedPoints.clear();
      } on GeometryException catch (e) {
        _showError('Error creating midpoint: ${e.message}');
        _selectedPoints.clear();
      }
    }
  }

  void _handleLineConstruction(Offset position) {
    final pointer = _adjustPositionForTranslation(position);

    if (_lineMode == LineConstructionMode.perpendicular) {
      _handlePerpendicularConstruction(pointer);
      return;
    }

    final highlightedObject = snapService.getHighlightedObject(
      pointer,
      engine.getAllObjects(),
    );
    final snappedObject = snapService.getSnapPoint(
      pointer,
      engine.getAllObjects(),
    );

    if (snappedObject is GPoint) {
      createPoint(snappedObject, highlightedObject);
    } else {
      _showError('Lines must be defined by points.');
      return;
    }

    if (_selectedPoints.length == 2) {
      try {
        switch (_lineMode) {
          case LineConstructionMode.infinite:
            engine.createInfiniteLine(_selectedPoints[0], _selectedPoints[1]);
            break;
          case LineConstructionMode.ray:
            engine.createRay(_selectedPoints[0], _selectedPoints[1]);
            break;
          case LineConstructionMode.segment:
            engine.createSegment(_selectedPoints[0], _selectedPoints[1]);
            break;
          case LineConstructionMode.perpendicular:
            break;
        }
        _selectedPoints.clear();
      } on GeometryException catch (e) {
        _showError('Error creating line: ${e.message}');
        _selectedPoints.clear();
      }
    }
  }

  void _handlePerpendicularConstruction(GPoint pointer) {
    final allObjects = engine.getAllObjects();
    final highlightedObject = snapService.getHighlightedObject(
      pointer,
      allObjects,
    );

    final snappedPoint = snapService.getSnapPoint(pointer, allObjects);
    if (snappedPoint is GPoint && allObjects.contains(snappedPoint)) {
      if (!_selectedPoints.contains(snappedPoint)) {
        _selectedPoints.add(snappedPoint);
      }
    } else {
      final clickedLine = engine.selectLineAt(pointer.x, pointer.y);
      if (clickedLine != null) {
        if (!_selectedObjects.contains(clickedLine)) {
          _selectedObjects.add(clickedLine);
        }
      } else {
        if (_selectedPoints.isEmpty) {
          // Create constrained point if there's a highlighted object
          if (highlightedObject is GLine) {
            final newPoint = engine.createPointOnLine(
              highlightedObject,
              pointer.x,
              pointer.y,
            );
            _selectedPoints.add(newPoint);
          } else if (highlightedObject is GCircle) {
            final newPoint = engine.createPointOnCircle(
              highlightedObject,
              pointer.x,
              pointer.y,
            );
            _selectedPoints.add(newPoint);
          } else {
            // Create free point if no highlighted object
            final newPoint = engine.createFreePoint(pointer.x, pointer.y);
            _selectedPoints.add(newPoint);
          }
        }
      }
    }

    final hasPoint = _selectedPoints.isNotEmpty;
    final hasLine = _selectedObjects.any((obj) => obj is GLine);

    if (hasPoint && hasLine) {
      try {
        final point = _selectedPoints.first;
        final line =
            _selectedObjects.firstWhere((obj) => obj is GLine) as GLine;

        engine.createPerpendicularLine(point, line);

        _selectedPoints.clear();
        _selectedObjects.clear();
      } on GeometryException catch (e) {
        _showError('Error creating perpendicular line: ${e.message}');
        _selectedPoints.clear();
        _selectedObjects.clear();
      }
    }
  }

  void _handleCircleConstruction(Offset position) {
    final pointer = _adjustPositionForTranslation(position);
    final highlightedObject = snapService.getHighlightedObject(
      pointer,
      engine.getAllObjects(),
    );
    final snappedObject = snapService.getSnapPoint(
      pointer,
      engine.getAllObjects(),
    );

    if (snappedObject is GPoint) {
      createPoint(snappedObject, highlightedObject);
    } else {
      _showError('Circles must be defined by points.');
      return;
    }

    if (_circleMode == CircleConstructionMode.centerPoint) {
      if (_selectedPoints.length == 2) {
        try {
          engine.createCircle(_selectedPoints[0], _selectedPoints[1]);
          _selectedPoints.clear();
        } on GeometryException catch (e) {
          _showError('Error creating circle: ${e.message}');
          _selectedPoints.clear();
        }
      }
    } else {
      if (_selectedPoints.length == 3) {
        try {
          engine.createThreePointCircle(
            _selectedPoints[0],
            _selectedPoints[1],
            _selectedPoints[2],
          );
          _selectedPoints.clear();
        } on GeometryException catch (e) {
          _showError('Error creating 3-point circle: ${e.message}');
          _selectedPoints.clear();
        }
      }
    }
  }

  void createPoint(GPoint snappedObject, GeometricObject? highlightedObject) {
    if (!engine.getAllObjects().contains(snappedObject)) {
      // Create constrained point if there's a highlighted object
      if (highlightedObject is GLine) {
        final newPoint = engine.createPointOnLine(
          highlightedObject,
          snappedObject.x,
          snappedObject.y,
        );
        _selectedPoints.add(newPoint);
      } else if (highlightedObject is GCircle) {
        final newPoint = engine.createPointOnCircle(
          highlightedObject,
          snappedObject.x,
          snappedObject.y,
        );
        _selectedPoints.add(newPoint);
      } else {
        // No highlighted object: check if snappedObject is at intersection of two objects
        final allObjects = engine.getAllObjects();
        final lines = allObjects.whereType<GLine>().toList();
        final circles = allObjects.whereType<GCircle>().toList();

        // Find all lines/circles that the point lies on (within tolerance)
        final onLines = lines.where((line) {
          final closest = line.getClosestPoint(snappedObject);
          return snappedObject.distanceTo(closest) < 1e-6;
        }).toList();

        final onCircles = circles.where((circle) {
          final closest = circle.getClosestPoint(snappedObject);
          return snappedObject.distanceTo(closest) < 1e-6;
        }).toList();

        // Try to create intersection if point is at intersection of two objects
        if (onLines.length >= 2) {
          // Line-line intersection
          final intersection = engine.createLineLineIntersection(
            onLines[0],
            onLines[1],
          );
          if (intersection != null) {
            _selectedPoints.add(intersection);
          } else {
            // Fallback: create free point
            final newPoint = engine.createFreePoint(
              snappedObject.x,
              snappedObject.y,
            );
            _selectedPoints.add(newPoint);
          }
        } else if (onLines.length == 1 && onCircles.length == 1) {
          // Line-circle intersection
          final intersections = engine.createLineCircleIntersection(
            onLines[0],
            onCircles[0],
          );
          // Find the intersection closest to snappedObject
          if (intersections.isNotEmpty) {
            final closest = intersections.reduce(
              (a, b) =>
                  a.distanceTo(snappedObject) < b.distanceTo(snappedObject)
                  ? a
                  : b,
            );
            _selectedPoints.add(closest);
          } else {
            final newPoint = engine.createFreePoint(
              snappedObject.x,
              snappedObject.y,
            );
            _selectedPoints.add(newPoint);
          }
        } else if (onCircles.length >= 2) {
          // Circle-circle intersection
          final intersections = engine.createCircleCircleIntersection(
            onCircles[0],
            onCircles[1],
          );
          if (intersections.isNotEmpty) {
            final closest = intersections.reduce(
              (a, b) =>
                  a.distanceTo(snappedObject) < b.distanceTo(snappedObject)
                  ? a
                  : b,
            );
            _selectedPoints.add(closest);
          } else {
            final newPoint = engine.createFreePoint(
              snappedObject.x,
              snappedObject.y,
            );
            _selectedPoints.add(newPoint);
          }
        } else {
          // Create free point if not on intersection
          final newPoint = engine.createFreePoint(
            snappedObject.x,
            snappedObject.y,
          );
          _selectedPoints.add(newPoint);
        }
      }
    } else {
      _selectedPoints.add(snappedObject);
    }
  }

  void _handleSelection(Offset position) {
    final pointer = _adjustPositionForTranslation(position);
    final snappedObject = snapService.getHighlightedObject(
      pointer,
      engine.getAllObjects(),
    );

    if (snappedObject != null) {
      if (_selectedObjects.contains(snappedObject)) {
        _selectedObjects.remove(snappedObject);
      } else {
        _selectedObjects.add(snappedObject);
      }
    }
  }

  void _handleIntersection(Offset position) {
    final pointer = GPoint.withCoordinates(position.dx, position.dy);
    final snappedObject = snapService.getHighlightedObject(
      pointer,
      engine.getAllObjects(),
    );

    if (snappedObject != null &&
        (snappedObject is GLine || snappedObject is GCircle)) {
      _addObjectToSelection(snappedObject);

      if (_selectedObjects.length == 2) {
        _processObjectIntersection();
      }
    } else {
      _showError(
        'Click directly on a line or circle to select it for intersection',
      );
    }
  }

  void _addObjectToSelection(GeometricObject object) {
    if (!_selectedObjects.contains(object)) {
      _selectedObjects.add(object);
    }
  }

  void _processObjectIntersection() {
    if (_selectedObjects.length < 2) return;
    try {
      _createIntersectionForSelectedObjects();
    } on GeometryException catch (e) {
      _showError('Error creating intersection: ${e.message}');
    } finally {
      _clearObjectSelection();
    }
  }

  void _clearObjectSelection() {
    _selectedObjects.clear();
  }

  bool _createIntersectionForSelectedObjects() {
    if (_selectedObjects.length < 2) return false;

    final obj1 = _selectedObjects[0];
    final obj2 = _selectedObjects[1];

    if (obj1 is GLine && obj2 is GLine) {
      return _handleLineLineIntersection(obj1, obj2);
    } else if (obj1 is GLine && obj2 is GCircle) {
      return _handleLineCircleIntersection(obj1, obj2);
    } else if (obj1 is GCircle && obj2 is GLine) {
      return _handleLineCircleIntersection(obj2, obj1);
    } else if (obj1 is GCircle && obj2 is GCircle) {
      return _handleCircleCircleIntersection(obj1, obj2);
    } else {
      _showError('Cannot intersect these object types');
      return false;
    }
  }

  bool _handleLineLineIntersection(GLine line1, GLine line2) {
    final intersection = engine.createLineLineIntersection(line1, line2);
    if (intersection == null) {
      _showError('No intersection point');
      return false;
    }
    return true;
  }

  bool _handleLineCircleIntersection(GLine line, GCircle circle) {
    final intersections = engine.createLineCircleIntersection(line, circle);
    if (intersections.isEmpty) {
      _showError('Line and circle do not intersect');
      return false;
    }
    return true;
  }

  bool _handleCircleCircleIntersection(GCircle circle1, GCircle circle2) {
    final intersections = engine.createCircleCircleIntersection(
      circle1,
      circle2,
    );
    if (intersections.isEmpty) {
      _showError('Circles do not intersect');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _handleDragStart(Offset position) {
    final pointer = _adjustPositionForTranslation(position);

    GPoint? pointToDrag;
    GeometricObject? objectToDrag;

    for (final point in engine.points) {
      if (point.isSameLocation(pointer.x, pointer.y)) {
        pointToDrag = point;
        break;
      }
    }

    if (pointToDrag != null) {
      objectToDrag = pointToDrag;
    } else {
      objectToDrag = snapService.getHighlightedObject(
        pointer,
        engine.getAllObjects(),
      );
    }

    if (objectToDrag != null) {
      final dependencyGraph = constraintSolver.buildDependencyGraph(
        engine.constraints,
      );

      if (constraintSolver.canDragFree(objectToDrag.id, dependencyGraph)) {
        _draggedObject = objectToDrag;
        _lastDragPosition = position;
      } else if (constraintSolver.canDragConstrained(
        objectToDrag.id,
        engine.constraints,
      )) {
        _draggedObject = objectToDrag;
        _lastDragPosition = position;
      } else {
        _showError(
          'Cannot drag constrained object: ${objectToDrag.name ?? objectToDrag.id}',
        );
      }
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_draggedObject == null || _lastDragPosition == null) return;

    final currentPosition = details.localPosition;
    final delta = currentPosition - _lastDragPosition!;
    final adjustedDelta = Offset(delta.dx, delta.dy);

    if (_draggedObject is GPoint) {
      final point = _draggedObject as GPoint;
      final requestedX = point.x + adjustedDelta.dx;
      final requestedY = point.y + adjustedDelta.dy;

      final dependencyGraph = constraintSolver.buildDependencyGraph(
        engine.constraints,
      );

      if (constraintSolver.canDragFree(point.id, dependencyGraph)) {
        point.setXY(requestedX, requestedY);
      } else if (constraintSolver.canDragConstrained(
        point.id,
        engine.constraints,
      )) {
        _handleConstrainedDrag(point, requestedX, requestedY);
      }

      final dependentObjects = constraintSolver.findTransitiveDependents({
        point.id,
      }, dependencyGraph);

      final affectedObjects = <int>{point.id};
      affectedObjects.addAll(dependentObjects);

      constraintSolver.updateConstraints(
        affectedObjects,
        engine.constraints,
        engine.points,
        engine.lines,
        engine.circles,
      );

      _lastDragPosition = currentPosition;
    } else if (_draggedObject is GLine) {
      final line = _draggedObject as GLine;
      final dependencyGraph = constraintSolver.buildDependencyGraph(
        engine.constraints,
      );
      final affectedObjects = <int>{};
      for (final point in line.points) {
        final newX = point.x + adjustedDelta.dx;
        final newY = point.y + adjustedDelta.dy;
        if (constraintSolver.canDragFree(point.id, dependencyGraph)) {
          point.setXY(newX, newY);
        } else if (constraintSolver.canDragConstrained(
          point.id,
          engine.constraints,
        )) {
          _handleConstrainedDrag(point, newX, newY);
        }
        affectedObjects.add(point.id);
        affectedObjects.addAll(
          constraintSolver.findTransitiveDependents({
            point.id,
          }, dependencyGraph),
        );
      }
      constraintSolver.updateConstraints(
        affectedObjects,
        engine.constraints,
        engine.points,
        engine.lines,
        engine.circles,
      );
      _lastDragPosition = currentPosition;
    } else if (_draggedObject is GCircle) {
      final circle = _draggedObject as GCircle;
      final dependencyGraph = constraintSolver.buildDependencyGraph(
        engine.constraints,
      );
      final pointsToMove = <GPoint>[circle.center, ...circle.points];
      final affectedObjects = <int>{};
      for (final point in pointsToMove) {
        final newX = point.x + adjustedDelta.dx;
        final newY = point.y + adjustedDelta.dy;
        if (constraintSolver.canDragFree(point.id, dependencyGraph)) {
          point.setXY(newX, newY);
        } else if (constraintSolver.canDragConstrained(
          point.id,
          engine.constraints,
        )) {
          _handleConstrainedDrag(point, newX, newY);
        }
        affectedObjects.add(point.id);
        affectedObjects.addAll(
          constraintSolver.findTransitiveDependents({
            point.id,
          }, dependencyGraph),
        );
      }
      constraintSolver.updateConstraints(
        affectedObjects,
        engine.constraints,
        engine.points,
        engine.lines,
        engine.circles,
      );
      _lastDragPosition = currentPosition;
    }
  }

  void _handleConstrainedDrag(
    GPoint point,
    double requestedX,
    double requestedY,
  ) {
    for (final constraint in engine.constraints) {
      if (constraint.elements.isNotEmpty &&
          constraint.elements[0].id == point.id) {
        if (constraint.type == ConstraintType.onLine) {
          final line = constraint.elements[1] as GLine;
          final requestedPoint = GPoint.withCoordinates(requestedX, requestedY);
          final projectedPoint = line.getClosestPoint(requestedPoint);
          point.setXY(projectedPoint.x, projectedPoint.y);
          return;
        } else if (constraint.type == ConstraintType.onCircle) {
          final circle = constraint.elements[1] as GCircle;
          // If the circle is being dragged, move the point with the same delta.
          if (_draggedObject is GCircle &&
              (_draggedObject as GCircle).id == circle.id) {
            point.setXY(requestedX, requestedY);
          } else {
            final requestedPoint = GPoint.withCoordinates(
              requestedX,
              requestedY,
            );
            final projectedPoint = circle.getClosestPoint(requestedPoint);
            point.setXY(projectedPoint.x, projectedPoint.y);
          }
          return;
        }
      }
    }
  }
}
