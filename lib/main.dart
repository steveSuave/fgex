// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/geometry_canvas.dart';
import 'providers/theme_provider.dart';

void main() {
  runApp(const GeometryExpertApp());
}

class GeometryExpertApp extends StatelessWidget {
  const GeometryExpertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Flutter Geometry Expert',
            theme: themeProvider.currentTheme,
            home: const GeometryExpertHome(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class GeometryExpertHome extends StatelessWidget {
  const GeometryExpertHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: GeometryCanvas());
  }
}
