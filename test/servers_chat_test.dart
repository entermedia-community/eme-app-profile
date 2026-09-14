import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_world/main.dart';
import 'package:eme_world/screens/server/server_detail_screen.dart';
import 'package:eme_world/screens/server/tabs/server_chat_tab.dart';

void main() {
  testWidgets('Servers Chat row renders and tapping server opens ServerChatTab', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EmeWorldApp()));
    await tester.pumpAndSettle();

    // Navigate to Chats tab
    await tester.tap(find.text('Chats').last);
    await tester.pumpAndSettle();

    // Verify Servers Chat header and nodes
    expect(find.text('SERVERS CHAT'), findsOneWidget);
    expect(find.text('Atitlan Exchange'), findsWidgets);

    // Verify badge on Atitlan Exchange (4 unread)
    expect(find.text('4'), findsOneWidget);

    // Tap on Atitlan Exchange server icon in the Servers Chat row
    await tester.tap(find.text('Atitlan Exchange').first);
    await tester.pumpAndSettle();

    // Verify ServerDetailScreen opened and ServerChatTab is displayed
    expect(find.byType(ServerDetailScreen), findsOneWidget);
    expect(find.byType(ServerChatTab), findsOneWidget);
    expect(find.text('#general'), findsOneWidget);
  });
}
