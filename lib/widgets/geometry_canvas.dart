import 'package:flutter/material.dart';
import 'package:flutter_geometry_expert/widgets/geometry_painter.dart';
import '../models/models.dart';
import '../services/geometry_engine.dart';

enum ConstructionMode { select, point, line, circle, intersection }

class GeometryCanvas extends StatefulWidget {
  @override
  _GeometryCanvasState createState() => _GeometryCanvasState();
}

class _GeometryCanvasState extends State<GeometryCanvas> {
  final GeometryEngine engine = GeometryEngine();
  ConstructionMode mode = ConstructionMode.select;
  List<GPoint> selectedPoints = [];
  GPoint? hoveredPoint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
            child: GestureDetector(
              onTapDown: _handleTapDown,
              onPanUpdate: _handlePanUpdate,
              child: CustomPaint(
                painter: GeometryPainter(
                  engine: engine,
                  selectedPoints: selectedPoints,
                  hoveredPoint: hoveredPoint,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        ),
        _buildStatusBar(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 60,
      color: Colors.grey[200],
      child: Row(
        children: [
          _toolButton(Icons.mouse, ConstructionMode.select, 'Select'),
          _toolButton(Icons.circle_outlined, ConstructionMode.point, 'Point'),
          _toolButton(Icons.linear_scale, ConstructionMode.line, 'Line'),
          _toolButton(Icons.circle, ConstructionMode.circle, 'Circle'),
          _toolButton(Icons.close, ConstructionMode.intersection, 'Intersect'),
          Spacer(),
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              setState(() {
                engine.clear();
                selectedPoints.clear();
                hoveredPoint = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _toolButton(IconData icon, ConstructionMode toolMode, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => setState(() {
          mode = toolMode;
          selectedPoints.clear();
        }),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: mode == toolMode ? Colors.blue[200] : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: mode == toolMode ? Colors.blue[800] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    String status = 'Ready';
    switch (mode) {
      case ConstructionMode.point:
        status = 'Click to create a point';
        break;
      case ConstructionMode.line:
        status = selectedPoints.isEmpty
            ? 'Select first point for line'
            : 'Select second point for line';
        break;
      case ConstructionMode.circle:
        status = selectedPoints.isEmpty
            ? 'Select center point for circle'
            : 'Select point on circle';
        break;
      case ConstructionMode.intersection:
        status = 'Select two objects to intersect';
        break;
      case ConstructionMode.select:
        status = 'Select mode - click objects to select';
        break;
    }

    return Container(
      height: 30,
      color: Colors.grey[100],
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(status, style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final position = details.localPosition;

    switch (mode) {
      case ConstructionMode.point:
        _createPoint(position);
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
      case ConstructionMode.intersection:
        _handleIntersection(position);
        break;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (mode == ConstructionMode.select) {
      // Find hovered point for visual feedback
      final point = engine.selectPointAt(
        details.localPosition.dx,
        details.localPosition.dy,
      );
      if (point != hoveredPoint) {
        setState(() {
          hoveredPoint = point;
        });
      }
    }
  }

  void _createPoint(Offset position) {
    final point = engine.createFreePoint(position.dx, position.dy);
    setState(() {});
  }

  void _handleLineConstruction(Offset position) {
    final point = engine.selectPointAt(position.dx, position.dy);

    if (point != null) {
      selectedPoints.add(point);

      if (selectedPoints.length == 2) {
        engine.createLine(selectedPoints[0], selectedPoints[1]);
        selectedPoints.clear();
      }
    } else if (selectedPoints.length == 1) {
      // Create new point and line
      final newPoint = engine.createFreePoint(position.dx, position.dy);
      engine.createLine(selectedPoints[0], newPoint);
      selectedPoints.clear();
    }

    setState(() {});
  }

  void _handleCircleConstruction(Offset position) {
    final point = engine.selectPointAt(position.dx, position.dy);

    if (point != null) {
      selectedPoints.add(point);

      if (selectedPoints.length == 2) {
        engine.createCircle(selectedPoints[0], selectedPoints[1]);
        selectedPoints.clear();
      }
    } else if (selectedPoints.length == 1) {
      // Create new point and circle
      final newPoint = engine.createFreePoint(position.dx, position.dy);
      engine.createCircle(selectedPoints[0], newPoint);
      selectedPoints.clear();
    }

    setState(() {});
  }

  void _handleSelection(Offset position) {
    final point = engine.selectPointAt(position.dx, position.dy);
    if (point != null) {
      setState(() {
        if (selectedPoints.contains(point)) {
          selectedPoints.remove(point);
        } else {
          selectedPoints.add(point);
        }
      });
    }
  }

  void _handleIntersection(Offset position) {
    // Simplified intersection - just line-line for now
    if (engine.lines.length >= 2) {
      engine.createIntersectionLL(engine.lines[0], engine.lines[1]);
      setState(() {});
    }
  }
}
