// lib/main.dart
import 'package:flutter/material.dart';
import 'widgets/geometry_canvas.dart';

void main() {
  runApp(const GeometryExpertApp());
}

class GeometryExpertApp extends StatelessWidget {
  const GeometryExpertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Geometry Expert',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const GeometryExpertHome(),
    );
  }
}

class GeometryExpertHome extends StatelessWidget {
  const GeometryExpertHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Geometry Expert MVP'),
        backgroundColor: Colors.blue[600],
      ),
      body: GeometryCanvas(),
    );
  }
}
