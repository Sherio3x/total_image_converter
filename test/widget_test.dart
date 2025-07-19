import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:total_image_converter/main.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TotalImageConverterApp());

    // Verify that the app title is displayed
    expect(find.text('Total Image Converter'), findsOneWidget);
    
    // Verify that the main components are present
    expect(find.text('محول الصور الشامل'), findsOneWidget);
    expect(find.text('صورة واحدة'), findsOneWidget);
    expect(find.text('عدة صور'), findsOneWidget);
    expect(find.text('تحويل الصور'), findsOneWidget);
  });
}

