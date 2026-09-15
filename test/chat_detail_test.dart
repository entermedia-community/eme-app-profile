import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_world/main.dart';
import 'package:eme_world/screens/chats/chat_detail_screen.dart';
import 'package:eme_world/screens/chats/chat_info_screen.dart';

void main() {
  testWidgets('Chat screen full navigation, search, QR modal, and Info drawer test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EmeWorldApp()));
    await tester.pumpAndSettle();

    // Navigate to Chats tab
    await tester.tap(find.text('Chats').last);
    await tester.pumpAndSettle();

    expect(find.text('Search conversations...'), findsOneWidget);
    expect(find.text('Atitlan Core Team'), findsWidgets);

    // Tap on the first chat item
    await tester.tap(find.text('Atitlan Core Team').first);
    await tester.pumpAndSettle();

    // Verify ChatDetailScreen is open
    expect(find.byType(ChatDetailScreen), findsOneWidget);
    expect(find.text('Atitlan Core Team'), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

    // 1. Test Search Toggle
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Search in conversation...'), findsOneWidget);

    // Enter search query
    await tester.enterText(find.byType(TextField).first, 'sprint');
    await tester.pumpAndSettle();

    expect(find.text('Next micro-grant sprint starts this Friday at 10 AM UTC.'), findsOneWidget);

    // Close search
    await tester.tap(find.byIcon(Icons.search_off_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Search in conversation...'), findsNothing);

    // 2. Test QR Code Modal
    await tester.tap(find.byIcon(Icons.qr_code_2_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Connect via QR'), findsOneWidget);
    expect(find.text('Save QR'), findsOneWidget);
    expect(find.text('Copy Link'), findsOneWidget);

    // Tap Save QR button
    await tester.tap(find.text('Save QR'));
    await tester.pumpAndSettle();

    expect(find.text('QR code saved to your device!'), findsOneWidget);
    expect(find.text('Connect via QR'), findsNothing);

    // 3. Test Info Screen (animated from right, empty TBD)
    await tester.tap(find.byIcon(Icons.info_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(ChatInfoScreen), findsOneWidget);
    expect(find.text('Chat Info'), findsOneWidget);

    // Pop Info screen
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(ChatInfoScreen), findsNothing);
    expect(find.byType(ChatDetailScreen), findsOneWidget);

    // Pop Chat detail screen back to chats list
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(ChatDetailScreen), findsNothing);
    expect(find.text('Search conversations...'), findsOneWidget);
  });
}
