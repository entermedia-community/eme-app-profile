import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_world/main.dart';
import 'package:eme_world/screens/eme_world/widgets/eme_profile_card.dart';
import 'package:eme_world/screens/profile/widgets/server_card.dart';

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
    expect(find.byType(ServerCard), findsWidgets);
    expect(find.text('Lakeview Stays & House Rentals'), findsOneWidget);

    // Verify Bottom Navigation items
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Chats'), findsWidgets);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('EME World'), findsWidgets);

    // Tap on Chats tab
    await tester.tap(find.text('Chats').last);
    await tester.pumpAndSettle();

    expect(find.text('Search conversations...'), findsOneWidget);

    // Tap on Files tab
    await tester.tap(find.text('Files'));
    await tester.pumpAndSettle();

    expect(find.text('Your Digital Legacy'), findsOneWidget);

    // Tap on EME World tab
    await tester.tap(find.text('EME World').last);
    await tester.pumpAndSettle();

    expect(find.text('EME Worldwide'), findsOneWidget);
    expect(find.text('EME Profiles Directory'), findsOneWidget);
    // Verify only EME profile cards exist in EME World
    expect(find.byType(EmeProfileCard), findsWidgets);
    expect(find.text('Dr. Maya Lin'), findsOneWidget);
    expect(find.text('Marcus Chen'), findsOneWidget);
  });

  testWidgets('Menu button opens Navigation Drawer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EmeWorldApp()));
    await tester.pumpAndSettle();

    // Tap the menu icon in AppBar
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    // Verify Drawer is open
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('EME World v1.0.0'), findsOneWidget);
  });
}
