import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_world/main.dart';

void main() {
  testWidgets('Renders Profile screen and navigates bottom bar tabs', (WidgetTester tester) async {
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

    // Verify Collective Intelligence Servers Section
    expect(find.text('Collective Intelligence Servers'), findsOneWidget);
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

    expect(find.text('EME Drive & Files'), findsOneWidget);

    // Tap on EME World tab
    await tester.tap(find.text('EME World').last);
    await tester.pumpAndSettle();

    expect(find.text('EME World Ecosystem'), findsOneWidget);
  });
}
