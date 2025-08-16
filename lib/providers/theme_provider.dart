import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors
  static const Color lightCanvasBackground = Colors.white;
  static const Color lightToolbarBackground = Color(0xFFEEEEEE);
  static const Color lightStatusBarBackground = Color(0xFFF5F5F5);
  static const Color lightToolButtonActive = Color(0xFFBBDEFB);
  static const Color lightToolButtonActiveIcon = Color(0xFF1565C0);
  static const Color lightToolButtonInactiveIcon = Color(0xFF616161);
  static const Color lightText = Colors.black87;

  // Light geometry colors
  static const Color lightGeometryLine = Color(0xFF212121);
  static const Color lightGeometrySelectedLine = Color(0xFFD32F2F);
  static const Color lightGeometryPoint = Color(0xFF1976D2);
  static const Color lightGeometrySelectedPoint = Color(0xFFD32F2F);
  static const Color lightGeometryHoveredPoint = Color(0xFFFF9800);
  static const Color lightGeometryText = Color(0xFF212121);

  // Dark theme colors
  static const Color darkCanvasBackground = Color(0xFF424242);
  static const Color darkToolbarBackground = Color(0xFF303030);
  static const Color darkStatusBarBackground = Color(0xFF212121);
  static const Color darkToolButtonActive = Color(0xFF1976D2);
  static const Color darkToolButtonActiveIcon = Color(0xFFBBDEFB);
  static const Color darkToolButtonInactiveIcon = Color(0xFFBDBDBD);
  static const Color darkText = Colors.white70;

  // Dark geometry colors
  static const Color darkGeometryLine = Color(0xFFE0E0E0);
  static const Color darkGeometrySelectedLine = Color(0xFFEF5350);
  static const Color darkGeometryPoint = Color(0xFF42A5F5);
  static const Color darkGeometrySelectedPoint = Color(0xFFEF5350);
  static const Color darkGeometryHoveredPoint = Color(0xFFFFB74D);
  static const Color darkGeometryText = Color(0xFFE0E0E0);
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Color getters for current theme
  Color get canvasBackground => _isDarkMode
      ? AppColors.darkCanvasBackground
      : AppColors.lightCanvasBackground;
  Color get toolbarBackground => _isDarkMode
      ? AppColors.darkToolbarBackground
      : AppColors.lightToolbarBackground;
  Color get statusBarBackground => _isDarkMode
      ? AppColors.darkStatusBarBackground
      : AppColors.lightStatusBarBackground;
  Color get toolButtonActive => _isDarkMode
      ? AppColors.darkToolButtonActive
      : AppColors.lightToolButtonActive;
  Color get toolButtonActiveIcon => _isDarkMode
      ? AppColors.darkToolButtonActiveIcon
      : AppColors.lightToolButtonActiveIcon;
  Color get toolButtonInactiveIcon => _isDarkMode
      ? AppColors.darkToolButtonInactiveIcon
      : AppColors.lightToolButtonInactiveIcon;
  Color get textColor => _isDarkMode ? AppColors.darkText : AppColors.lightText;

  // Geometry color getters
  Color get geometryLineColor =>
      _isDarkMode ? AppColors.darkGeometryLine : AppColors.lightGeometryLine;
  Color get geometrySelectedLineColor => _isDarkMode
      ? AppColors.darkGeometrySelectedLine
      : AppColors.lightGeometrySelectedLine;
  Color get geometryPointColor =>
      _isDarkMode ? AppColors.darkGeometryPoint : AppColors.lightGeometryPoint;
  Color get geometrySelectedPointColor => _isDarkMode
      ? AppColors.darkGeometrySelectedPoint
      : AppColors.lightGeometrySelectedPoint;
  Color get geometryHoveredPointColor => _isDarkMode
      ? AppColors.darkGeometryHoveredPoint
      : AppColors.lightGeometryHoveredPoint;
  Color get geometryTextColor =>
      _isDarkMode ? AppColors.darkGeometryText : AppColors.lightGeometryText;

  ThemeData get lightTheme => ThemeData(
    primarySwatch: Colors.blue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightCanvasBackground,
    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.white, // Or any color you prefer
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightCanvasBackground,
      foregroundColor: AppColors.lightText,
      elevation: 1,
    ),
  );

  ThemeData get darkTheme => ThemeData(
    primarySwatch: Colors.blue,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkCanvasBackground,
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF303030), // Dark gray or any color you prefer for dark mode
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkCanvasBackground,
      foregroundColor: AppColors.darkText,
      elevation: 1,
    ),
  );

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
