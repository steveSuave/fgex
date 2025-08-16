// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/geometry_canvas.dart';
import 'providers/theme_provider.dart';
import 'controllers/geometry_controller.dart'; // Import the new controller

void main() {
  runApp(const GeometryExpertApp());
}

class GeometryExpertApp extends StatelessWidget {
  const GeometryExpertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => GeometryController()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Flutter Geometry Expert',
            theme: themeProvider.currentTheme,
            home: const PlaenHome(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class PlaenHome extends StatelessWidget {
  const PlaenHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: GeometryCanvas());
  }
}
