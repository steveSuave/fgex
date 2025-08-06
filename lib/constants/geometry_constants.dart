// lib/constants/geometry_constants.dart
class GeometryConstants {
  // Numerical tolerances
  static const double parallelLinesTolerance = 1e-10;
  static const double pointSelectionTolerance = 20.0;
  static const double pointLocationTolerance = 1e-6;

  // Visual constants
  static const double defaultStrokeWidth = 1.5;
  static const double pointRadius = 3.0;
  static const double selectedPointRadius = 4.0;
  static const double hoveredPointRadius = 4.0;

  // UI dimensions
  static const double toolbarHeight = 60.0;
  static const double statusBarHeight = 30.0;
  static const double toolButtonSize = 50.0;
  static const double pointNameOffset = 8.0;
  static const double pointNameVerticalOffset = -20.0;

  // Text styles
  static const double pointNameFontSize = 12.0;
  static const double statusFontSize = 12.0;
}
