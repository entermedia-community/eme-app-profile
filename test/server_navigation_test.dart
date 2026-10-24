import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/profile/widgets/server_card.dart';
import 'package:eme_world/screens/server/server_detail_screen.dart';
import 'package:eme_world/screens/server/tabs/server_chat_tab.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets(
    'Joined server in the chat list opens ServerDetailScreen on the Chat tab',
    (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Joined servers are listed in the chat list under the Servers filter
      await tester.tap(find.bySemanticsIdentifier('chat_filter_servers'));
      await tester.pumpAndSettle();
      expect(find.text('Lakeview Stays & House Rentals'), findsOneWidget);
      await tester.tap(find.text('Lakeview Stays & House Rentals'));
      await tester.pumpAndSettle();

      expect(find.byType(ServerDetailScreen), findsOneWidget);
      expect(find.byType(ServerChatTab), findsOneWidget);
    },
  );

  testWidgets(
    'ServerCard renders Connect button for unjoined servers and handles tap',
    (WidgetTester tester) async {
      final unjoinedServer = const ServerModel(
        id: 'srv_unjoined_99',
        name: 'Unjoined Server',
        description: 'Test unjoined server description',
        category: ServerCategoryModel(
          id: 'software_tools',
          name: 'Software Tools',
        ),
        isJoined: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: ServerCard(server: unjoinedServer)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Connect'), findsOneWidget);
      await tester.tap(find.text('Connect'));
      await tester.pump();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'ServerDetailScreen Leave Server menu option calls toggleJoin and returns to Chats',
    (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Joined servers are listed in the chat list under the Servers filter
      await tester.tap(find.bySemanticsIdentifier('chat_filter_servers'));
      await tester.pumpAndSettle();
      expect(find.text('Lakeview Stays & House Rentals'), findsOneWidget);
      await tester.tap(find.text('Lakeview Stays & House Rentals'));
      await tester.pumpAndSettle();

      expect(find.byType(ServerDetailScreen), findsOneWidget);

      // Open PopupMenuButton
      await tester.tap(find.byTooltip('Server Options'));
      await tester.pumpAndSettle();

      // Tap 'Leave Server'
      expect(find.text('Leave Server'), findsOneWidget);
      await tester.tap(find.text('Leave Server'));
      await tester.pumpAndSettle();

      // Verify popped back to the main app screen (Chats)
      expect(find.byType(ServerDetailScreen), findsNothing);
    },
  );

  testWidgets(
    'Search (Servers filter) lists servers and tapping a card opens its chat',
    (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsIdentifier('chats_open_search'));
      await tester.pumpAndSettle();

      // Show only servers so the first result is a server
      await tester.tap(find.bySemanticsIdentifier('search_type_servers'));
      await tester.pumpAndSettle();

      final card = find.bySemanticsIdentifier('search_result_0');
      expect(card, findsOneWidget);
      await tester.tap(card);
      await tester.pumpAndSettle();

      // Search shows a preview card first; its primary action opens the server
      await tester.tap(find.bySemanticsIdentifier('server_preview_primary'));
      await tester.pumpAndSettle();

      expect(find.byType(ServerDetailScreen), findsOneWidget);
    },
  );
}
