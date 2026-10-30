import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eme_world/screens/chats/chat_detail_screen.dart';
import 'package:eme_world/screens/chats/session_history_screen.dart';
import 'test_helpers.dart';

void main() {
  testWidgets(
    'Chat screen full navigation, search, QR modal, and Info drawer test',
    (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // App opens on Chats (home); DMs live under the People tab
      await tester.tap(find.bySemanticsIdentifier('home_tab_people'));
      await tester.pumpAndSettle();
      expect(find.text('The Administrator'), findsWidgets);

      // Tap on the first chat item
      await tester.tap(find.text('The Administrator').first);
      await tester.pumpAndSettle();

      // Verify ChatDetailScreen is open
      expect(find.byType(ChatDetailScreen), findsOneWidget);
      expect(find.text('The Administrator'), findsOneWidget);
      // Search, QR and Info live in the three-dot menu
      expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

      // 1. Test Search Toggle
      await tester.tap(find.bySemanticsIdentifier('chat_overflow_menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('chat_menu_search'));
      await tester.pumpAndSettle();

      expect(find.text('Search in conversation...'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byType(TextField).first, 'Direct');
      await tester.pumpAndSettle();

      expect(find.text('Welcome to EME Direct Messaging.'), findsOneWidget);

      // Close search
      await tester.tap(find.bySemanticsIdentifier('chat_overflow_menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('chat_menu_search'));
      await tester.pumpAndSettle();
      expect(find.text('Search in conversation...'), findsNothing);

      // Session History is the first menu entry and opens its screen
      await tester.tap(find.bySemanticsIdentifier('chat_overflow_menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('chat_menu_sessions'));
      await tester.pumpAndSettle();
      expect(find.byType(SessionHistoryScreen), findsOneWidget);
      expect(find.text('No earlier sessions yet'), findsOneWidget);
      expect(find.bySemanticsIdentifier('session_history_new'), findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('session_history_close'));
      await tester.pumpAndSettle();

      // 2. Test QR Code Modal
      await tester.tap(find.bySemanticsIdentifier('chat_overflow_menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('chat_menu_qr'));
      await tester.pumpAndSettle();

      expect(find.text('Connect via QR'), findsOneWidget);
      expect(find.text('Save QR'), findsOneWidget);
      expect(find.text('Copy Link'), findsOneWidget);

      // Tap Save QR button
      await tester.tap(find.text('Save QR'));
      await tester.pumpAndSettle();

      expect(find.text('QR code saved to your device!'), findsOneWidget);
      expect(find.text('Connect via QR'), findsNothing);

      // 3. Tapping the header shows that user's profile
      await tester.tap(find.text('The Administrator'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsIdentifier('profile_details_close'),
        findsOneWidget,
      );
      await tester.tap(find.bySemanticsIdentifier('profile_details_close'));
      await tester.pumpAndSettle();

      // Pop Chat detail screen back to chats list
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(ChatDetailScreen), findsNothing);
      expect(find.bySemanticsIdentifier('home_tab_people'), findsOneWidget);
    },
  );
}
