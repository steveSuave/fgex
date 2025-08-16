import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geometry_expert/widgets/geometry_painter.dart';
import 'package:provider/provider.dart';
import '../constants/geometry_constants.dart';
import '../providers/theme_provider.dart';
import '../controllers/geometry_controller.dart'; // Import the new controller

class GeometryCanvas extends StatefulWidget {
  const GeometryCanvas({super.key});

  @override
  State<GeometryCanvas> createState() => _GeometryCanvasState();
}

class _GeometryCanvasState extends State<GeometryCanvas> {
  final FocusNode _focusNode = FocusNode();
  late GeometryController _controller;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = Provider.of<GeometryController>(context);
    _controller.addListener(_handleControllerChanges);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanges);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChanges() {
    if (_controller.errorMessage != null) {
      // Clear any existing SnackBars first
      ScaffoldMessenger.of(context).clearSnackBars();

      // Then show the new error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: Colors.lightBlue,
          duration: const Duration(seconds: 3),
        ),
      );
      _controller.clearErrorMessage();
    }
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
      child: SafeArea(
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
                    child: MouseRegion(
                      onHover: (details) =>
                          _controller.handlePointerHover(details.localPosition),
                      child: GestureDetector(
                        onTapDown: (details) {
                          _focusNode.requestFocus();
                          _controller.handleTapDown(details.localPosition);
                        },
                        onPanStart: (details) {
                          _controller.handlePanStart(details.localPosition);
                        },
                        onPanUpdate: _controller.handlePanUpdate,
                        onPanEnd: _controller.handlePanEnd,
                        child: CustomPaint(
                          painter: GeometryPainter(
                            engine: _controller.engine,
                            selectedPoints: _controller.selectedPoints,
                            selectedObjects: _controller.selectedObjects,
                            hoveredObject: _controller.hoveredObject,
                            themeProvider: themeProvider,
                            canvasTranslation: _controller.canvasTranslation,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildStatusBar(),
          ],
        ),
      ),
    );
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      // Undo with Backspace
      if (key == LogicalKeyboardKey.backspace) {
        _controller.undo();
        return true;
      }
      // Redo with Enter
      if (key == LogicalKeyboardKey.enter) {
        _controller.redo();
        return true;
      }

      if (key == LogicalKeyboardKey.keyP) {
        _controller.selectTool(
          ConstructionMode.point,
          PointConstructionMode.point,
        );
        return true;
      } else if (key == LogicalKeyboardKey.keyL) {
        _controller.selectTool(
          ConstructionMode.line,
          null,
          LineConstructionMode.infinite,
        );
        return true;
      } else if (key == LogicalKeyboardKey.keyS) {
        _controller.selectTool(
          ConstructionMode.line,
          null,
          LineConstructionMode.segment,
        );
        return true;
      } else if (key == LogicalKeyboardKey.keyR) {
        _controller.selectTool(
          ConstructionMode.line,
          null,
          LineConstructionMode.ray,
        );
        return true;
      } else if (key == LogicalKeyboardKey.digit2) {
        _controller.selectTool(
          ConstructionMode.line,
          null,
          LineConstructionMode.perpendicular,
        );
        return true;
      } else if (key == LogicalKeyboardKey.keyC) {
        _controller.selectTool(
          ConstructionMode.circle,
          null,
          null,
          CircleConstructionMode.centerPoint,
        );
        return true;
      } else if (key == LogicalKeyboardKey.digit3) {
        _controller.selectTool(
          ConstructionMode.circle,
          null,
          null,
          CircleConstructionMode.threePoint,
        );
        return true;
      } else if (key == LogicalKeyboardKey.keyI) {
        _controller.selectTool(
          ConstructionMode.point,
          PointConstructionMode.intersection,
        );
        return true;
      } else if (key == LogicalKeyboardKey.keyM) {
        _controller.selectTool(
          ConstructionMode.point,
          PointConstructionMode.midpoint,
        );
        return true;
      } else if (key == LogicalKeyboardKey.keyT) {
        _controller.selectTool(ConstructionMode.translate);
        return true;
      } else if (key == LogicalKeyboardKey.keyD) {
        _controller.selectTool(ConstructionMode.drag);
        return true;
      }
    }
    return false;
  }

  Widget _buildToolbar() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          height: GeometryConstants.toolbarHeight,
          color: themeProvider.toolbarBackground,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toolButton(Icons.mouse, ConstructionMode.select, 'Select'),
                _buildPointToolButton(),
                _buildLineToolButton(),
                _buildCircleToolButton(),
                _toolButton(
                  Icons.pan_tool,
                  ConstructionMode.drag,
                  'Drag Objects',
                ),
                _toolButton(
                  Icons.open_with,
                  ConstructionMode.translate,
                  'Pan/Translate Canvas',
                ),
                SizedBox(width: 20),
                IconButton(
                  icon: Icon(Icons.undo),
                  onPressed: () {
                    _controller.undo();
                  },
                  tooltip: 'Undo (Backspace)',
                ),
                IconButton(
                  icon: Icon(Icons.redo),
                  onPressed: () {
                    _controller.redo();
                  },
                  tooltip: 'Redo (Enter)',
                ),
                IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _controller.clearCanvas();
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
          ),
        );
      },
    );
  }

  Widget _toolButton(IconData icon, ConstructionMode toolMode, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () => _controller.selectTool(toolMode),
        child: Consumer<GeometryController>(
          builder: (context, controller, child) {
            return Container(
              width: GeometryConstants.toolButtonSize,
              height: GeometryConstants.toolButtonSize,
              decoration: BoxDecoration(
                color: controller.mode == toolMode
                    ? Provider.of<ThemeProvider>(context).toolButtonActive
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: controller.mode == toolMode
                    ? Provider.of<ThemeProvider>(context).toolButtonActiveIcon
                    : Provider.of<ThemeProvider>(
                        context,
                      ).toolButtonInactiveIcon,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPointToolButton() {
    return PopupMenuButton<PointConstructionMode>(
      onSelected: (PointConstructionMode selectedMode) {
        _controller.selectTool(ConstructionMode.point, selectedMode);
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
        PopupMenuItem<PointConstructionMode>(
          value: PointConstructionMode.midpoint,
          child: Text('Midpoint'),
        ),
      ],
      child: Consumer2<ThemeProvider, GeometryController>(
        builder: (context, themeProvider, controller, child) {
          return Container(
            width: GeometryConstants.toolButtonSize,
            height: GeometryConstants.toolButtonSize,
            decoration: BoxDecoration(
              color: controller.mode == ConstructionMode.point
                  ? themeProvider.toolButtonActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.circle,
              color: controller.mode == ConstructionMode.point
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
        _controller.selectTool(ConstructionMode.line, null, selectedMode);
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
        PopupMenuItem<LineConstructionMode>(
          value: LineConstructionMode.perpendicular,
          child: Text('Perpendicular'),
        ),
      ],
      child: Consumer2<ThemeProvider, GeometryController>(
        builder: (context, themeProvider, controller, child) {
          return Container(
            width: GeometryConstants.toolButtonSize,
            height: GeometryConstants.toolButtonSize,
            decoration: BoxDecoration(
              color: controller.mode == ConstructionMode.line
                  ? themeProvider.toolButtonActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.linear_scale,
              color: controller.mode == ConstructionMode.line
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
        _controller.selectTool(
          ConstructionMode.circle,
          null,
          null,
          selectedMode,
        );
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
      child: Consumer2<ThemeProvider, GeometryController>(
        builder: (context, themeProvider, controller, child) {
          return Container(
            width: GeometryConstants.toolButtonSize,
            height: GeometryConstants.toolButtonSize,
            decoration: BoxDecoration(
              color: controller.mode == ConstructionMode.circle
                  ? themeProvider.toolButtonActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.circle_outlined,
              color: controller.mode == ConstructionMode.circle
                  ? themeProvider.toolButtonActiveIcon
                  : themeProvider.toolButtonInactiveIcon,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBar() {
    return Consumer2<ThemeProvider, GeometryController>(
      builder: (context, themeProvider, controller, child) {
        return Container(
          height: GeometryConstants.statusBarHeight,
          color: themeProvider.statusBarBackground,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                controller.getStatusMessage(),
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
}
