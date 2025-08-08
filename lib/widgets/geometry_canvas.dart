import 'package:flutter/material.dart';
import 'package:flutter_geometry_expert/widgets/geometry_painter.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/geometry_engine.dart';
import '../constants/geometry_constants.dart';
import '../exceptions/geometry_exceptions.dart';
import '../providers/theme_provider.dart';

enum ConstructionMode { select, point, line, circle, intersection }

enum LineConstructionMode { infinite, ray, segment }

enum CircleConstructionMode { centerPoint, threePoint }

class GeometryCanvas extends StatefulWidget {
  const GeometryCanvas({super.key});

  @override
  State<GeometryCanvas> createState() => _GeometryCanvasState();
}

class _GeometryCanvasState extends State<GeometryCanvas> {
  final GeometryEngine engine = GeometryEngine();
  ConstructionMode mode = ConstructionMode.select;
  LineConstructionMode lineMode = LineConstructionMode.infinite;
  CircleConstructionMode circleMode = CircleConstructionMode.centerPoint;
  List<GPoint> selectedPoints = [];
  List<GeometricObject> selectedObjects = [];
  GPoint? hoveredPoint;
  bool showLineDropdown = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Container(
                width: double.infinity,
                height: double.infinity,
                color: themeProvider.canvasBackground,
                child: GestureDetector(
                  onTapDown: _handleTapDown,
                  onPanUpdate: _handlePanUpdate,
                  child: CustomPaint(
                    painter: GeometryPainter(
                      engine: engine,
                      selectedPoints: selectedPoints,
                      selectedObjects: selectedObjects,
                      hoveredPoint: hoveredPoint,
                      lineColor: themeProvider.geometryLineColor,
                      selectedLineColor:
                          themeProvider.geometrySelectedLineColor,
                      pointColor: themeProvider.geometryPointColor,
                      selectedPointColor:
                          themeProvider.geometrySelectedPointColor,
                      hoveredPointColor:
                          themeProvider.geometryHoveredPointColor,
                      textColor: themeProvider.geometryTextColor,
                    ),
                    size: Size.infinite,
                  ),
                ),
              );
            },
          ),
        ),
        _buildStatusBar(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          height: GeometryConstants.toolbarHeight,
          color: themeProvider.toolbarBackground,
          child: Row(
            children: [
              _toolButton(Icons.mouse, ConstructionMode.select, 'Select'),
              _toolButton(
                Icons.circle_outlined,
                ConstructionMode.point,
                'Point',
              ),
              _buildLineToolButton(),
              _buildCircleToolButton(),
              _toolButton(
                Icons.close,
                ConstructionMode.intersection,
                'Intersect',
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    engine.clear();
                    selectedPoints.clear();
                    selectedObjects.clear();
                    hoveredPoint = null;
                  });
                },
              ),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return IconButton(
                    icon: Icon(
                      themeProvider.isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    onPressed: () {
                      themeProvider.toggleTheme();
                    },
                    tooltip: themeProvider.isDarkMode
                        ? 'Switch to Light Mode'
                        : 'Switch to Dark Mode',
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _toolButton(IconData icon, ConstructionMode toolMode, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => setState(() {
          mode = toolMode;
          selectedPoints.clear();
          selectedObjects.clear();
          if (toolMode != ConstructionMode.line) {
            showLineDropdown = false;
          }
        }),
        child: Container(
          width: GeometryConstants.toolButtonSize,
          height: GeometryConstants.toolButtonSize,
          decoration: BoxDecoration(
            color: mode == toolMode
                ? Provider.of<ThemeProvider>(context).toolButtonActive
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: mode == toolMode
                ? Provider.of<ThemeProvider>(context).toolButtonActiveIcon
                : Provider.of<ThemeProvider>(context).toolButtonInactiveIcon,
          ),
        ),
      ),
    );
  }

  Widget _buildLineToolButton() {
    return PopupMenuButton<LineConstructionMode>(
      onSelected: (LineConstructionMode selectedMode) {
        setState(() {
          lineMode = selectedMode;
          mode = ConstructionMode.line;
          selectedPoints.clear();
          selectedObjects.clear();
        });
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<LineConstructionMode>(
          value: LineConstructionMode.infinite,
          child: Text('Line'),
        ),
        PopupMenuItem<LineConstructionMode>(
          value: LineConstructionMode.ray,
          child: Text('Ray'),
        ),
        PopupMenuItem<LineConstructionMode>(
          value: LineConstructionMode.segment,
          child: Text('Segment'),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            width: GeometryConstants.toolButtonSize,
            height: GeometryConstants.toolButtonSize,
            decoration: BoxDecoration(
              color: mode == ConstructionMode.line
                  ? themeProvider.toolButtonActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.linear_scale,
              color: mode == ConstructionMode.line
                  ? themeProvider.toolButtonActiveIcon
                  : themeProvider.toolButtonInactiveIcon,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCircleToolButton() {
    return PopupMenuButton<CircleConstructionMode>(
      onSelected: (CircleConstructionMode selectedMode) {
        setState(() {
          circleMode = selectedMode;
          mode = ConstructionMode.circle;
          selectedPoints.clear();
          selectedObjects.clear();
        });
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<CircleConstructionMode>(
          value: CircleConstructionMode.centerPoint,
          child: Text('Circle (Center + Point)'),
        ),
        PopupMenuItem<CircleConstructionMode>(
          value: CircleConstructionMode.threePoint,
          child: Text('Circle (3 Points)'),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            width: GeometryConstants.toolButtonSize,
            height: GeometryConstants.toolButtonSize,
            decoration: BoxDecoration(
              color: mode == ConstructionMode.circle
                  ? themeProvider.toolButtonActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.circle,
              color: mode == ConstructionMode.circle
                  ? themeProvider.toolButtonActiveIcon
                  : themeProvider.toolButtonInactiveIcon,
            ),
          );
        },
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
        String lineTypeStr = lineMode == LineConstructionMode.infinite
            ? 'line'
            : lineMode == LineConstructionMode.ray
            ? 'ray'
            : 'segment';
        status = selectedPoints.isEmpty
            ? 'Select first point for $lineTypeStr'
            : 'Select second point for $lineTypeStr';
        break;
      case ConstructionMode.circle:
        if (circleMode == CircleConstructionMode.centerPoint) {
          status = selectedPoints.isEmpty
              ? 'Select center point for circle'
              : 'Select point on circle';
        } else {
          status = selectedPoints.isEmpty
              ? 'Select first point for 3-point circle'
              : selectedPoints.length == 1
              ? 'Select second point for 3-point circle'
              : 'Select third point for 3-point circle';
        }
        break;
      case ConstructionMode.intersection:
        status = selectedObjects.isEmpty
            ? 'Click on first object to intersect'
            : selectedObjects.length == 1
            ? 'Click on second object to intersect'
            : 'Two objects selected - creating intersections';
        break;
      case ConstructionMode.select:
        status = 'Select mode - click objects to select';
        break;
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          height: GeometryConstants.statusBarHeight,
          color: themeProvider.statusBarBackground,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                status,
                style: TextStyle(
                  fontSize: GeometryConstants.statusFontSize,
                  color: themeProvider.textColor,
                ),
              ),
            ),
          ),
        );
      },
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
    try {
      engine.createFreePoint(position.dx, position.dy);
      setState(() {});
    } on GeometryException catch (e) {
      _showError('Error creating point: ${e.message}');
    }
  }

  void _handleLineConstruction(Offset position) {
    final point = engine.selectPointAt(position.dx, position.dy);

    if (point != null) {
      selectedPoints.add(point);
    } else {
      // Create new point if no existing point found
      try {
        final newPoint = engine.createFreePoint(position.dx, position.dy);
        selectedPoints.add(newPoint);
      } on GeometryException catch (e) {
        _showError('Error creating point: ${e.message}');
        return;
      }
    }

    if (selectedPoints.length == 2) {
      try {
        switch (lineMode) {
          case LineConstructionMode.infinite:
            engine.createInfiniteLine(selectedPoints[0], selectedPoints[1]);
            break;
          case LineConstructionMode.ray:
            engine.createRay(selectedPoints[0], selectedPoints[1]);
            break;
          case LineConstructionMode.segment:
            engine.createSegment(selectedPoints[0], selectedPoints[1]);
            break;
        }
        selectedPoints.clear();
      } on GeometryException catch (e) {
        _showError('Error creating line: ${e.message}');
        selectedPoints.clear();
      }
    }

    setState(() {});
  }

  void _handleCircleConstruction(Offset position) {
    final point = engine.selectPointAt(position.dx, position.dy);

    if (point != null) {
      selectedPoints.add(point);
    } else {
      // Create new point if no existing point found
      try {
        final newPoint = engine.createFreePoint(position.dx, position.dy);
        selectedPoints.add(newPoint);
      } on GeometryException catch (e) {
        _showError('Error creating point: ${e.message}');
        return;
      }
    }

    if (circleMode == CircleConstructionMode.centerPoint) {
      if (selectedPoints.length == 2) {
        try {
          engine.createCircle(selectedPoints[0], selectedPoints[1]);
          selectedPoints.clear();
        } on GeometryException catch (e) {
          _showError('Error creating circle: ${e.message}');
          selectedPoints.clear();
        }
      }
    } else {
      // Three-point circle
      if (selectedPoints.length == 3) {
        try {
          engine.createThreePointCircle(
            selectedPoints[0],
            selectedPoints[1],
            selectedPoints[2],
          );
          selectedPoints.clear();
        } on GeometryException catch (e) {
          _showError('Error creating 3-point circle: ${e.message}');
          selectedPoints.clear();
        }
      }
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
    // Try to select an object at this position
    GLine? line = engine.selectLineAt(position.dx, position.dy);
    GCircle? circle = engine.selectCircleAt(position.dx, position.dy);

    GeometricObject? selectedObject;
    if (line != null) {
      selectedObject = line;
    } else if (circle != null) {
      selectedObject = circle;
    }

    if (selectedObject != null) {
      _addObjectToSelection(selectedObject);

      if (selectedObjects.length == 2) {
        _processObjectIntersection();
      }
    } else {
      _showError(
        'Click directly on a line or circle to select it for intersection',
      );
    }
  }

  void _addObjectToSelection(GeometricObject object) {
    setState(() {
      if (!selectedObjects.contains(object)) {
        selectedObjects.add(object);
      }
    });
  }

  void _processObjectIntersection() {
    if (selectedObjects.length < 2) return;
    try {
      _createIntersectionForSelectedObjects();
    } on GeometryException catch (e) {
      _showError('Error creating intersection: ${e.message}');
    } finally {
      _clearObjectSelection();
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

  void _clearObjectSelection() {
    setState(() {
      selectedObjects.clear();
    });
  }

  bool _createIntersectionForSelectedObjects() {
    if (selectedObjects.length < 2) return false;

    final obj1 = selectedObjects[0];
    final obj2 = selectedObjects[1];

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
