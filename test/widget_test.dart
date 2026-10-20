import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eme_world/screens/eme_world/widgets/eme_profile_card.dart';
import 'package:eme_world/screens/profile/widgets/server_card.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('Opens on Chats and navigates bottom bar tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    // Chats is the first and default tab
    expect(find.text('Search conversations...'), findsOneWidget);

    // Verify Bottom Navigation items
    expect(find.text('Chats'), findsWidgets);
    expect(find.text('Files'), findsOneWidget);
    expect(find.text('Search'), findsWidgets);
    expect(find.text('EME'), findsWidgets);

    // Tap on Files tab
    await tester.tap(find.text('Files'));
    await tester.pumpAndSettle();

    expect(find.text('Your Digital Legacy'), findsOneWidget);

    // Tap on Search tab
    await tester.tap(find.text('Search').last);
    await tester.pumpAndSettle();

    expect(find.text('EME Worldwide'), findsOneWidget);
    expect(find.text('EME Profiles Directory'), findsOneWidget);
    // Verify only EME profile cards exist in Search
    expect(find.byType(EmeProfileCard), findsWidgets);
    expect(find.text('The Administrator'), findsOneWidget);
    expect(find.text('Dr. Maya Lin'), findsNothing);
    expect(find.text('Marcus Chen'), findsNothing);

    // Perform top search in Eme World Screen
    final searchField = find.byType(TextField).first;
    await tester.enterText(searchField, 'admin');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify search result from /mediadb/services/module/user/usersearch.json
    expect(find.text('The Administrator'), findsOneWidget);

    // Tap on EME (profile) tab, last in the bar
    await tester.tap(find.text('EME').last);
    await tester.pumpAndSettle();

    // Verify Profile Header elements for authenticated user
    expect(find.textContaining('Christopher'), findsWidgets);
    expect(find.text('chris@emeworld.org'), findsOneWidget);
    expect(find.text('ACCOUNT PROFILE'), findsOneWidget);

    // Verify Action Buttons
    // Self-chat button and the app bar profile button both read "EME <first name>"
    expect(find.text('EME Christopher'), findsNWidgets(2));
    expect(find.byTooltip('Edit Profile'), findsOneWidget);

    // Verify My Joined Servers Section
    expect(find.byType(ServerCard), findsWidgets);
    expect(find.text('Lakeview Stays & House Rentals'), findsOneWidget);
  });

  testWidgets('Menu button opens Navigation Drawer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    // Tap the menu icon in AppBar
    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pumpAndSettle();

    // Verify Drawer is open
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('EME World v1.0.0'), findsOneWidget);
  });
}
