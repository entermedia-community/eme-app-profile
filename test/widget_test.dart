import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_world/main.dart';
import 'package:eme_world/screens/server/server_picker_screen.dart';
import 'package:eme_world/screens/eme_world/widgets/individual_card.dart';

void main() {
  testWidgets('Renders Profile screen and navigates bottom bar tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EmeWorldApp()));
    await tester.pumpAndSettle();

    // Verify Profile Header elements
    expect(find.text('Christopher.B'), findsWidgets);
    expect(find.text('CEO'), findsWidgets);
    expect(find.text('PORTFOLIO'), findsOneWidget);
    expect(find.text('Cool guy'), findsOneWidget);
    expect(find.text('Programmer'), findsOneWidget);
    expect(find.text('Dude'), findsOneWidget);

    // Verify Action Buttons
    expect(find.text('Open Chat'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);

    // Verify My Joined Servers Section
    expect(find.text('My Joined Servers'), findsOneWidget);
    expect(find.text('Atitlan Exchange'), findsOneWidget);

    // Verify Bottom Navigation items
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Chats'), findsWidgets);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('EME World'), findsWidgets);

    // Verify Floating Action Button exists on Profile tab
    expect(find.byType(FloatingActionButton), findsOneWidget);

    // Tap on Chats tab
    await tester.tap(find.text('Chats').last);
    await tester.pumpAndSettle();

    expect(find.text('Messages & Chats'), findsOneWidget);

    // Tap on Files tab
    await tester.tap(find.text('Files'));
    await tester.pumpAndSettle();

    expect(find.text('Your Digital Legacy'), findsOneWidget);

    // Tap on EME World tab
    await tester.tap(find.text('EME World').last);
    await tester.pumpAndSettle();

    expect(find.text('EME Worldwide'), findsOneWidget);
    expect(find.text('EME Profile Directory'), findsOneWidget);
    // Verify only individual cards exist in EME World
    expect(find.byType(IndividualCard), findsWidgets);
    expect(find.text('Dr. Maya Lin'), findsOneWidget);
    expect(find.text('Marcus Chen'), findsOneWidget);
  });

  testWidgets('FAB on Profile tab navigates to ServerPickerScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EmeWorldApp()));
    await tester.pumpAndSettle();

    // Tap the FAB on Profile screen
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verify ServerPickerScreen is pushed
    expect(find.byType(ServerPickerScreen), findsOneWidget);
    expect(find.text('Pick a Server'), findsOneWidget);
    expect(find.text('All Servers'), findsWidgets);
    expect(find.text('Available'), findsWidgets);
    expect(find.text('Joined'), findsWidgets);
    expect(find.text('Atitlan Exchange'), findsOneWidget);
    expect(find.text('Neural Matrix Collective'), findsOneWidget);
  });

  testWidgets('Explore All button in Profile navigates to ServerPickerScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EmeWorldApp()));
    await tester.pumpAndSettle();

    // Tap Explore All button
    await tester.tap(find.text('Explore All'));
    await tester.pumpAndSettle();

    // Verify ServerPickerScreen is pushed
    expect(find.byType(ServerPickerScreen), findsOneWidget);
    expect(find.text('Pick a Server'), findsOneWidget);
  });
}
