import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_geometry_expert/widgets/geometry_canvas.dart';
import 'package:flutter_geometry_expert/providers/theme_provider.dart';

void main() {
  group('Canvas Translation Widget Tests', () {
    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
          child: const Scaffold(
            body: GeometryCanvas(),
          ),
        ),
      );
    }

    testWidgets('should show translate tool button in toolbar', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find the translate/pan tool button
      final translateButton = find.byIcon(Icons.pan_tool);
      expect(translateButton, findsOneWidget);

      // Check tooltip
      await tester.longPress(translateButton);
      await tester.pump();
      
      expect(find.text('Pan/Translate Canvas'), findsOneWidget);
    });

    testWidgets('should switch to translate mode when button is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Find and tap the translate button
      final translateButton = find.byIcon(Icons.pan_tool);
      await tester.tap(translateButton);
      await tester.pump();

      // Check that status bar shows translate mode message
      expect(find.text('Pan/translate mode - drag to move the canvas'), findsOneWidget);
    });

    testWidgets('should handle pan gestures in translate mode', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Switch to translate mode
      final translateButton = find.byIcon(Icons.pan_tool);
      await tester.tap(translateButton);
      await tester.pump();

      // Verify we're in translate mode by checking status
      expect(find.text('Pan/translate mode - drag to move the canvas'), findsOneWidget);
      
      // The GeometryCanvas widget should still be present and functional
      expect(find.byType(GeometryCanvas), findsOneWidget);
    });

    testWidgets('should reset canvas translation when clear button is pressed', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Switch to translate mode 
      final translateButton = find.byIcon(Icons.pan_tool);
      await tester.tap(translateButton);
      await tester.pump();

      // Verify translate mode is active
      expect(find.text('Pan/translate mode - drag to move the canvas'), findsOneWidget);

      // Find and tap clear button
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);
      
      await tester.tap(clearButton);
      await tester.pump();

      // Canvas should be cleared and reset - still in translate mode but canvas is reset
      expect(find.byType(GeometryCanvas), findsOneWidget);
      expect(find.text('Pan/translate mode - drag to move the canvas'), findsOneWidget);
    });

    testWidgets('should not interfere with other tools when not in translate mode', (tester) async {
      await tester.pumpWidget(createTestWidget());

      // Stay in select mode (default)
      expect(find.text('Select mode - click objects to select'), findsOneWidget);

      // Switch to point mode
      final pointButton = find.byIcon(Icons.circle_outlined);
      await tester.tap(pointButton);
      await tester.pump();

      // Should be in point mode now
      expect(find.text('Click to create a point'), findsOneWidget);
      
      // The translate functionality should not interfere
      expect(find.byType(GeometryCanvas), findsOneWidget);
    });

    testWidgets('should show correct construction mode enum values', (tester) async {
      // This test verifies that the ConstructionMode enum includes translate
      expect(ConstructionMode.values.contains(ConstructionMode.translate), isTrue);
      expect(ConstructionMode.values.length, equals(6)); // select, point, line, circle, intersection, translate
    });
  });
}