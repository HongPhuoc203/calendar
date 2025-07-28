// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify that splash screen shows first
    expect(find.text('C Global Calendar'), findsOneWidget);
    expect(find.text('Quản lý lịch sự kiện thông minh'), findsNothing);
    
    // Wait for splash screen to complete
    await tester.pumpAndSettle(const Duration(seconds: 5));
    
    // Should navigate to login screen after splash
    expect(find.byType(TextField), findsWidgets);
  });
  
  testWidgets('SplashScreen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SplashScreen()));
    
    // Check if splash screen elements are present
    expect(find.text('C Global Calendar'), findsOneWidget);
    expect(find.byType(AnimatedBuilder), findsWidgets);
  });
}
