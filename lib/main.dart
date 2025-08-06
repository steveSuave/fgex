// lib/main.dart
import 'package:flutter/material.dart';
import 'widgets/geometry_canvas.dart';

void main() {
  runApp(GeometryExpertApp());
}

class GeometryExpertApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Geometry Expert',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: GeometryExpertHome(),
    );
  }
}

class GeometryExpertHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Geometry Expert MVP'),
        backgroundColor: Colors.blue[600],
      ),
      body: GeometryCanvas(),
    );
  }
}
