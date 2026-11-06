import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/server/tabs/server_chat_tab.dart';
import 'package:eme_world/widgets/chat/session_resume_prompt.dart';
import 'package:flutter/material.dart' hide FormField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

class _HistoryApi extends MockApiService {
  _HistoryApi(this.lastMessageAge);
  final Duration lastMessageAge;
  final created = <String>[];

  @override
  Future<List<ChatMessage>> fetchServerChatMessages(
    String channelId, {
    String? serverId,
    String? baseUrl,
  }) async => channelId == 'new_session'
      ? const []
      : [
          ChatMessage(
            messageId: 'm1',
            channel: channelId,
            userId: 'someone',
            message: 'Earlier message',
            createdAt: DateTime.now().subtract(lastMessageAge),
          ),
        ];

  @override
  Future<ChatSession> createChatSession({
    String? toUser,
    String? serverId,
    String? collectionId,
    String? baseUrl,
  }) {
    created.add('$serverId');
    return super.createChatSession(serverId: serverId);
  }
}

const _server = ServerModel(
  id: 'srv_resume',
  name: 'Provider',
  description: 'd',
  category: ServerCategoryModel(id: 'all', name: 'All'),
);

Future<void> _pump(WidgetTester tester, MockApiService api) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiServiceProvider.overrideWithValue(api)],
      child: const MaterialApp(
        home: Scaffold(body: ServerChatTab(server: _server)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an idle session asks to continue or start a new one', (
    tester,
  ) async {
    final api = _HistoryApi(const Duration(hours: 5));
    await _pump(tester, api);

    expect(find.text('Earlier message'), findsOneWidget);
    expect(find.text('This session was last active 5 hours ago.'), findsOne);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionResumePrompt), findsNothing);
    expect(find.text('Earlier message'), findsOneWidget);
    expect(api.created, isEmpty);
  });

  testWidgets('New session starts one and leaves the old messages behind', (
    tester,
  ) async {
    final api = _HistoryApi(const Duration(days: 2));
    await _pump(tester, api);

    await tester.tap(find.text('New session'));
    await tester.pumpAndSettle();

    expect(api.created, ['srv_resume']);
    expect(find.byType(SessionResumePrompt), findsNothing);
    expect(find.text('Earlier message'), findsNothing);
  });

  testWidgets('a recent session opens without a prompt', (tester) async {
    await _pump(tester, _HistoryApi(const Duration(minutes: 10)));

    expect(find.text('Earlier message'), findsOneWidget);
    expect(find.byType(SessionResumePrompt), findsNothing);
  });

  test('sessionAgeLabel', () {
    final now = DateTime(2026, 11, 7, 12);
    expect(
      sessionAgeLabel(now.subtract(const Duration(minutes: 90)), now: now),
      '1 hour ago',
    );
    expect(
      sessionAgeLabel(now.subtract(const Duration(days: 3)), now: now),
      '3 days ago',
    );
  });
}
