import 'dart:convert';

import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/chats/chat_detail_screen.dart';
import 'package:eme_world/widgets/chat/agent_status_widgets.dart';
import 'package:eme_world/widgets/delta_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

/// A chat history with one agent reply per [MessageStatus].
class _HistoryApi extends MockApiService {
  final List<ChatMessage> history;
  _HistoryApi(this.history);

  @override
  Future<List<ChatMessage>> fetchUserChatMessages(String channelId) async =>
      history;
}

ChatMessage _agentReply(String id, String text, {MessageStatus? status}) {
  return ChatMessage.fromJson({
    'messageid': id,
    'channel': 'chan',
    'user': 'agent',
    'messagetype': 'message',
    'message': jsonEncode({
      'ops': [
        {'insert': '$text\n'},
      ],
    }),
    if (status != null)
      'agentcontextvalues': jsonEncode({'messagestatus': status.name}),
    'date': '2026-11-12T10:00:00Z',
  });
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AgentStatusIndicator', () {
    testWidgets('working shows a spinner, streaming shows dots', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AgentStatusIndicator(id: 'm1', status: MessageStatus.working),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Working…'), findsOneWidget);
      expect(find.byType(TypingDots), findsNothing);
      expect(find.bySemanticsIdentifier('agent_status_m1'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          const AgentStatusIndicator(id: 'm1', status: MessageStatus.streaming),
        ),
      );
      expect(find.byType(TypingDots), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a finished, failed or plain message shows nothing', (
      tester,
    ) async {
      for (final status in [MessageStatus.done, MessageStatus.error, null]) {
        await tester.pumpWidget(
          _wrap(AgentStatusIndicator(id: 'm1', status: status)),
        );
        expect(find.bySemanticsIdentifier('agent_status_m1'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(TypingDots), findsNothing);
      }
    });
  });

  group('DeltaViewer', () {
    testWidgets('repaints when the same widget gets new ops', (tester) async {
      final ops = ValueNotifier<List<dynamic>>([
        {'insert': 'Hello\n'},
      ]);
      await tester.pumpWidget(
        _wrap(
          ValueListenableBuilder<List<dynamic>>(
            valueListenable: ops,
            builder: (context, value, _) =>
                DeltaViewer(deltaOps: value, onLinkTap: (link, data) {}),
          ),
        ),
      );
      expect(find.textContaining('Hello', findRichText: true), findsOneWidget);

      ops.value = [
        {'insert': 'Hello world\n'},
      ];
      await tester.pump();
      expect(
        find.textContaining('Hello world', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('ChatDetailScreen', () {
    const chat = ChatModel(
      channelId: 'chan',
      username: 'agent',
      displayName: 'Agent',
      lastMessage: '',
      time: '',
      avatarColor: Colors.teal,
    );

    Future<void> openWith(
      WidgetTester tester,
      List<ChatMessage> history,
    ) async {
      final api = _HistoryApi(history);
      final auth = AuthenticatedMockAuthService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(auth),
            apiServiceProvider.overrideWithValue(api),
          ],
          child: const MaterialApp(
            home: ChatDetailScreen(chat: chat, promptIdle: false),
          ),
        ),
      );
      // A status animation never settles, so pump a few frames instead
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    testWidgets('shows a status for each agent reply that has one', (
      tester,
    ) async {
      await openWith(tester, [
        _agentReply('w', 'working text', status: MessageStatus.working),
        _agentReply('s', 'streaming text', status: MessageStatus.streaming),
        _agentReply('d', 'done text', status: MessageStatus.done),
        _agentReply('e', 'error text', status: MessageStatus.error),
        _agentReply('p', 'plain text'),
      ]);

      expect(find.bySemanticsIdentifier('agent_status_w'), findsOneWidget);
      expect(find.bySemanticsIdentifier('agent_status_s'), findsOneWidget);
      expect(find.bySemanticsIdentifier('agent_status_d'), findsNothing);
      expect(find.bySemanticsIdentifier('agent_status_e'), findsNothing);
      expect(find.bySemanticsIdentifier('agent_status_p'), findsNothing);
      expect(
        find.textContaining('error text', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('the input and send button have semantics identifiers', (
      tester,
    ) async {
      await openWith(tester, [_agentReply('p', 'plain text')]);
      expect(find.bySemanticsIdentifier('chat_detail_input'), findsOneWidget);
      expect(find.bySemanticsIdentifier('chat_detail_send'), findsOneWidget);
    });
  });
}
