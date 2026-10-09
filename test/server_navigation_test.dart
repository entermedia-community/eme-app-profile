import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/profile/widgets/server_card.dart';
import 'package:eme_world/screens/server/server_chat_screen.dart';
import 'package:eme_world/screens/server/server_detail_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

void main() {
  testWidgets(
    'Clicking ServerCard opens ServerChatScreen, and top nav button opens ServerDetailScreen',
    (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify ServerCard is present and scroll until visible
      final serverCardFinder = find.byType(ServerCard).first;
      expect(serverCardFinder, findsOneWidget);
      await tester.ensureVisible(serverCardFinder);
      await tester.pumpAndSettle();

      // Click ServerCard
      await tester.tap(serverCardFinder);
      await tester.pumpAndSettle();

      // Verify ServerChatScreen is opened
      expect(find.byType(ServerChatScreen), findsOneWidget);
      expect(find.text('Console'), findsOneWidget);

      // Click the Console button in the top nav bar area
      await tester.tap(find.text('Console'));
      await tester.pumpAndSettle();

      // Verify ServerDetailScreen is opened
      expect(find.byType(ServerDetailScreen), findsOneWidget);

      // Pop back from ServerDetailScreen
      await tester.tap(find.byTooltip('Back').first);
      await tester.pumpAndSettle();

      // Verify we're back on ServerChatScreen
      expect(find.byType(ServerChatScreen), findsOneWidget);
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
}
