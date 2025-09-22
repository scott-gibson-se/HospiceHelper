// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:hospice_meds/main.dart';
import 'package:hospice_meds/providers/medication_provider.dart';

void main() {
  testWidgets('App loads and shows home screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HospiceMedsApp());

    // Verify that the app loads with the home screen
    expect(find.text('Hospice Medication Tracker'), findsOneWidget);
    expect(find.text('No medications added yet'), findsOneWidget);
  });

  testWidgets('Add medication button is present', (WidgetTester tester) async {
    await tester.pumpWidget(const HospiceMedsApp());
    
    // Verify that the floating action button is present
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('Settings and history buttons are present', (WidgetTester tester) async {
    await tester.pumpWidget(const HospiceMedsApp());
    
    // Verify that the app bar action buttons are present
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
