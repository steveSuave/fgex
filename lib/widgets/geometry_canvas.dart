import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geometry_expert/widgets/geometry_painter.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/geometry_engine.dart';
import '../constants/geometry_constants.dart';
import '../exceptions/geometry_exceptions.dart';
import '../providers/theme_provider.dart';

enum ConstructionMode { select, point, line, circle, translate }

enum PointConstructionMode { point, intersection }

enum LineConstructionMode { infinite, ray, segment }

enum CircleConstructionMode { centerPoint, threePoint }

class GeometryCanvas extends StatefulWidget {
  const GeometryCanvas({super.key});

  @override
  State<GeometryCanvas> createState() => _GeometryCanvasState();
}

class _GeometryCanvasState extends State<GeometryCanvas> {
  final GeometryEngine engine = GeometryEngine();
  final FocusNode _focusNode = FocusNode();
  ConstructionMode mode = ConstructionMode.select;
  PointConstructionMode pointMode = PointConstructionMode.point;
  LineConstructionMode lineMode = LineConstructionMode.infinite;
  CircleConstructionMode circleMode = CircleConstructionMode.centerPoint;
  List<GPoint> selectedPoints = [];
  List<GeometricObject> selectedObjects = [];
  GPoint? hoveredPoint;
  bool showLineDropdown = false;
  Offset canvasTranslation = Offset.zero;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        return _handleKeyEvent(event)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      },
      autofocus: true,
      child: Column(
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
                    onTapDown: (details) {
                      _focusNode.requestFocus();
                      _handleTapDown(details);
                    },
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
                        canvasTranslation: canvasTranslation,
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
      ),
    );
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.keyP) {
        _selectTool(ConstructionMode.point, PointConstructionMode.point);
        return true;
      } else if (key == LogicalKeyboardKey.keyL) {
        _selectTool(ConstructionMode.line, null, LineConstructionMode.infinite);
        return true;
      } else if (key == LogicalKeyboardKey.keyS) {
        _selectTool(ConstructionMode.line, null, LineConstructionMode.segment);
        return true;
      } else if (key == LogicalKeyboardKey.keyR) {
        _selectTool(ConstructionMode.line, null, LineConstructionMode.ray);
        return true;
      } else if (key == LogicalKeyboardKey.keyC) {
        _selectTool(
          ConstructionMode.circle,
          null,
          null,
          CircleConstructionMode.centerPoint,
        );
        return true;
      } else if (key == LogicalKeyboardKey.digit3) {
        _selectTool(
          ConstructionMode.circle,
          null,
          null,
          CircleConstructionMode.threePoint,
        );
        return true;
      } else if (key == LogicalKeyboardKey.keyI) {
        _selectTool(ConstructionMode.point, PointConstructionMode.intersection);
        return true;
      } else if (key == LogicalKeyboardKey.keyT) {
        _selectTool(ConstructionMode.translate);
        return true;
      }
    }
    return false;
  }

  void _selectTool(
    ConstructionMode newMode, [
    PointConstructionMode? newPointMode,
    LineConstructionMode? newLineMode,
    CircleConstructionMode? newCircleMode,
  ]) {
    setState(() {
      mode = newMode;
      if (newPointMode != null) pointMode = newPointMode;
      if (newLineMode != null) lineMode = newLineMode;
      if (newCircleMode != null) circleMode = newCircleMode;
      selectedPoints.clear();
      selectedObjects.clear();
      if (newMode != ConstructionMode.line) {
        showLineDropdown = false;
      }
    });
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
              _buildPointToolButton(),
              _buildLineToolButton(),
              _buildCircleToolButton(),
              _toolButton(
                Icons.pan_tool,
                ConstructionMode.translate,
                'Pan/Translate Canvas',
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
                    canvasTranslation = Offset.zero;
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
        onTap: () => _selectTool(toolMode),
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

  Widget _buildPointToolButton() {
    return PopupMenuButton<PointConstructionMode>(
      onSelected: (PointConstructionMode selectedMode) {
        _selectTool(ConstructionMode.point, selectedMode);
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<PointConstructionMode>(
          value: PointConstructionMode.point,
          child: Text('Point'),
        ),
        PopupMenuItem<PointConstructionMode>(
          value: PointConstructionMode.intersection,
          child: Text('Intersection'),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Container(
            width: GeometryConstants.toolButtonSize,
            height: GeometryConstants.toolButtonSize,
            decoration: BoxDecoration(
              color: mode == ConstructionMode.point
                  ? themeProvider.toolButtonActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.circle_outlined,
              color: mode == ConstructionMode.point
                  ? themeProvider.toolButtonActiveIcon
                  : themeProvider.toolButtonInactiveIcon,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLineToolButton() {
    return PopupMenuButton<LineConstructionMode>(
      onSelected: (LineConstructionMode selectedMode) {
        _selectTool(ConstructionMode.line, null, selectedMode);
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
        _selectTool(ConstructionMode.circle, null, null, selectedMode);
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          height: GeometryConstants.statusBarHeight,
          color: themeProvider.statusBarBackground,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _getStatusMessage(),
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

  String _getStatusMessage() {
    switch (mode) {
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
    }
  }

  String _getPointModeStatus() {
    if (pointMode == PointConstructionMode.point) {
      return 'Click to create a point';
    }

    // Intersection mode
    if (selectedObjects.isEmpty) {
      return 'Click on first object to intersect';
    }

    if (selectedObjects.length == 1) {
      return 'Click on second object to intersect';
    }

    return 'Two objects selected - creating intersections';
  }

  String _getLineModeStatus() {
    final String lineTypeName = _getLineTypeName();

    if (selectedPoints.isEmpty) {
      return 'Select first point for $lineTypeName';
    }

    return 'Select second point for $lineTypeName';
  }

  String _getLineTypeName() {
    const Map<LineConstructionMode, String> lineTypeNames = {
      LineConstructionMode.infinite: 'line',
      LineConstructionMode.ray: 'ray',
      LineConstructionMode.segment: 'segment',
    };

    return lineTypeNames[lineMode] ?? 'line';
  }

  String _getCircleModeStatus() {
    if (circleMode == CircleConstructionMode.centerPoint) {
      return _getCenterPointCircleStatus();
    }

    return _getThreePointCircleStatus();
  }

  String _getCenterPointCircleStatus() {
    if (selectedPoints.isEmpty) {
      return 'Select center point for circle';
    }

    return 'Select point on circle';
  }

  String _getThreePointCircleStatus() {
    if (selectedPoints.isEmpty) {
      return 'Select first point for 3-point circle';
    }

    if (selectedPoints.length == 1) {
      return 'Select second point for 3-point circle';
    }

    return 'Select third point for 3-point circle';
  }

  /// Adjusts screen position to account for canvas translation
  Offset _adjustPositionForTranslation(Offset position) {
    return Offset(
      position.dx - canvasTranslation.dx,
      position.dy - canvasTranslation.dy,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final position = details.localPosition;

    switch (mode) {
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
        // Translation is handled by pan gestures, not tap
        break;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (mode == ConstructionMode.select) {
      // Find hovered point for visual feedback
      final point = engine.selectPointAt(
        details.localPosition.dx - canvasTranslation.dx,
        details.localPosition.dy - canvasTranslation.dy,
      );
      if (point != hoveredPoint) {
        setState(() {
          hoveredPoint = point;
        });
      }
    } else if (mode == ConstructionMode.translate) {
      // Translate the canvas
      setState(() {
        canvasTranslation += details.delta;
      });
    }
  }

  void _handlePointConstruction(Offset position) {
    // Adjust position for canvas translation
    final adjustedPosition = Offset(
      position.dx - canvasTranslation.dx,
      position.dy - canvasTranslation.dy,
    );

    try {
      switch (pointMode) {
        case PointConstructionMode.point:
          // Check if there's already a point at this location
          final existingPoint = engine.selectPointAt(
            adjustedPosition.dx,
            adjustedPosition.dy,
          );

          if (existingPoint == null) {
            // No existing point - create new point
            engine.createFreePoint(adjustedPosition.dx, adjustedPosition.dy);
          }
          // If there's already a point, do nothing (don't create duplicate)
          break;
        case PointConstructionMode.intersection:
          _handleIntersection(adjustedPosition);
          break;
      }

      setState(() {});
    } on GeometryException catch (e) {
      _showError('Error creating point: ${e.message}');
    }
  }

  void _handleLineConstruction(Offset position) {
    final adjustedPosition = _adjustPositionForTranslation(position);
    final point = engine.selectPointAt(
      adjustedPosition.dx,
      adjustedPosition.dy,
    );

    if (point != null) {
      selectedPoints.add(point);
    } else {
      // Create new point if no existing point found
      try {
        final newPoint = engine.createFreePoint(
          adjustedPosition.dx,
          adjustedPosition.dy,
        );
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
    final adjustedPosition = _adjustPositionForTranslation(position);
    final point = engine.selectPointAt(
      adjustedPosition.dx,
      adjustedPosition.dy,
    );

    if (point != null) {
      selectedPoints.add(point);
    } else {
      // Create new point if no existing point found
      try {
        final newPoint = engine.createFreePoint(
          adjustedPosition.dx,
          adjustedPosition.dy,
        );
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
    final adjustedPosition = _adjustPositionForTranslation(position);
    final point = engine.selectPointAt(
      adjustedPosition.dx,
      adjustedPosition.dy,
    );
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
        backgroundColor: Colors.lightBlue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
