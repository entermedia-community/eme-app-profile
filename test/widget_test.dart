import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eme_world/screens/search/unified_search_screen.dart';
import 'package:eme_world/screens/files/files_section.dart';
import 'test_helpers.dart';

void main() {
  testWidgets('Opens on Chats, Search sheet, and EME profile page', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    // Chats is home; there is no bottom nav or drawer
    expect(find.text('Search conversations...'), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsNothing);

    // "EME Search" button is as tall as the conversation search input
    expect(find.text('EME Search'), findsOneWidget);
    expect(
      tester.getSize(find.bySemanticsIdentifier('chats_open_search')).height,
      tester.getSize(find.bySemanticsIdentifier('chats_search_input')).height,
    );

    // Search button opens combined people + servers search, full screen
    await tester.tap(find.bySemanticsIdentifier('chats_open_search'));
    await tester.pumpAndSettle();

    expect(find.byType(UnifiedSearchScreen), findsOneWidget);

    // People and servers are combined in one results list
    expect(find.bySemanticsIdentifier('search_results'), findsOneWidget);
    expect(find.text('Person'), findsWidgets);
    expect(find.text('Server'), findsWidgets);
    expect(find.text('The Administrator'), findsWidgets);
    expect(find.text('Lakeview Stays & House Rentals'), findsOneWidget);

    // Category pills include the EME profile categories (scroll the pill row)
    final pillRow = find.descendant(
      of: find.bySemanticsIdentifier('search_category_bar'),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      find.text('Mobility & Rides'),
      200,
      scrollable: pillRow.first,
    );
    expect(find.text('Mobility & Rides'), findsOneWidget);
    await tester.drag(pillRow.first, const Offset(2000, 0));
    await tester.pumpAndSettle();

    // Type filter: People hides servers, Servers hides people
    await tester.tap(find.bySemanticsIdentifier('search_type_people'));
    await tester.pumpAndSettle();
    expect(find.text('Server'), findsNothing);
    expect(find.text('Person'), findsWidgets);
    await tester.tap(find.bySemanticsIdentifier('search_type_servers'));
    await tester.pumpAndSettle();
    expect(find.text('Person'), findsNothing);
    expect(find.text('Server'), findsWidgets);
    await tester.tap(find.bySemanticsIdentifier('search_type_all'));
    await tester.pumpAndSettle();

    // Category filter applies to both: Rental & Gear keeps only that server
    await tester.scrollUntilVisible(
      find.text('Rental & Gear'),
      200,
      scrollable: pillRow.first,
    );
    await tester.tap(find.text('Rental & Gear'));
    await tester.pumpAndSettle();
    expect(find.text('Lakeview Stays & House Rentals'), findsOneWidget);
    expect(find.text('Artisan Goods & Organic Market'), findsNothing);
    await tester.drag(pillRow.first, const Offset(2000, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('search_category_0'));
    await tester.pumpAndSettle();

    // One query searches both
    await tester.enterText(
      find.descendant(
        of: find.bySemanticsIdentifier('search_input'),
        matching: find.byType(TextField),
      ),
      'admin',
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // Verify search result from /mediadb/services/module/user/usersearch.json
    expect(
      find.descendant(
        of: find.byType(UnifiedSearchScreen),
        matching: find.text('The Administrator'),
      ),
      findsOneWidget,
    );

    // Tapping a profile card shows the details sheet with a greeting draft
    await tester.tap(
      find.descendant(
        of: find.byType(UnifiedSearchScreen),
        matching: find.text('The Administrator'),
      ),
    );
    await tester.pumpAndSettle();
    final greeting = tester.widget<TextField>(
      find.descendant(
        of: find.bySemanticsIdentifier('profile_greeting_input'),
        matching: find.byType(TextField),
      ),
    );
    expect(greeting.controller!.text, startsWith("Hi The, I'm Christopher."));
    expect(find.bySemanticsIdentifier('profile_greeting_send'), findsOneWidget);
    await tester.tap(find.bySemanticsIdentifier('profile_details_close'));
    await tester.pumpAndSettle();

    // Close the search
    await tester.tap(find.bySemanticsIdentifier('search_back'));
    await tester.pumpAndSettle();
    expect(find.text('EME Worldwide'), findsNothing);

    // Open the EME profile page from the app bar profile button
    await tester.tap(find.bySemanticsIdentifier('app_bar_profile_button'));
    await tester.pumpAndSettle();

    // Verify Profile Header elements for authenticated user
    expect(find.textContaining('Christopher'), findsWidgets);
    expect(find.text('chris@emeworld.org'), findsOneWidget);
    expect(find.text('ACCOUNT PROFILE'), findsOneWidget);

    // App bar button and the message box heading both read "EME <first name>"
    expect(find.text('EME Christopher'), findsNWidgets(2));
    expect(find.byTooltip('Edit Profile'), findsOneWidget);

    // Message box for your own chat sits above Files
    expect(find.bySemanticsIdentifier('profile_chat_input'), findsOneWidget);
    expect(find.bySemanticsIdentifier('profile_chat_send'), findsOneWidget);
    expect(
      tester.getTopLeft(find.bySemanticsIdentifier('profile_chat_input')).dy,
      lessThan(tester.getTopLeft(find.byType(FilesSection)).dy),
    );

    // Files section replaces the servers section
    expect(find.byType(FilesSection), findsOneWidget);
    expect(find.text('Your Digital Legacy'), findsOneWidget);

    // Back arrow returns to Chats
    await tester.tap(find.bySemanticsIdentifier('app_bar_back_to_chats'));
    await tester.pumpAndSettle();
    expect(find.text('Search conversations...'), findsOneWidget);
  });

  testWidgets('Three-dot menu shows Settings, theme and Log out', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More options'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Light theme'), findsOneWidget);
    expect(find.text('Dark theme'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });
}
