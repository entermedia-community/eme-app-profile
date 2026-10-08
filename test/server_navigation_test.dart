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
      expect(find.text('Details'), findsOneWidget);

      // Click the Details button in the top nav bar area
      await tester.tap(find.text('Details'));
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
}
