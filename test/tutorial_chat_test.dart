import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/server/tabs/server_chat_tab.dart';
import 'package:eme_world/widgets/chat/tutorial_cards.dart';
import 'package:flutter/material.dart' hide FormField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_helpers.dart';

class _TutorialApi extends MockApiService {
  final bool failTopics;
  _TutorialApi({this.failTopics = false});

  @override
  Future<List<TutorialTopic>> fetchTutorialTopics({String? baseUrl}) async {
    if (failTopics) throw Exception('server offline');
    return tutorialTopics;
  }

  @override
  Future<List<ChatMessage>> fetchServerChatMessages(
    String channelId, {
    String? serverId,
    String? baseUrl,
  }) async => channelId.startsWith('tutor_')
      ? const []
      : [
          ChatMessage(
            messageId: 'w1',
            channel: channelId,
            userId: 'agent',
            message: 'Welcome to the server',
            agentContextValues: AgentContextValues(
              messageRenderType: MessageRenderType.welcome,
            ),
            createdAt: DateTime.now(),
          ),
        ];
}

const _server = ServerModel(
  id: 'srv_tutorials',
  name: 'Learning Server',
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
  testWidgets('welcome menu → topics → tutorials → starts the tutorial', (
    tester,
  ) async {
    final api = _TutorialApi()
      ..tutorialTopics.add(const TutorialTopic(id: 'tp1', title: 'Safety'))
      ..tutorialsByTopic['tp1'] = [
        const TutorialSummary(id: 't1', title: 'Fire drills'),
      ];
    await _pump(tester, api);

    await tester.tap(find.text('Tutorials'));
    await tester.pumpAndSettle();
    expect(find.text('Safety'), findsOneWidget);

    await tester.tap(find.text('Safety'));
    await tester.pumpAndSettle();
    expect(find.text('Fire drills'), findsOneWidget);

    await tester.tap(find.text('Fire drills'));
    // The wait spinner animates forever, so settle by time, not by frames.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(api.startedTutorials, ['t1@tutor_t1']);
    // Tutorial mode: the banner shows the title with an exit, and the welcome
    // menu of the server chat is gone.
    expect(find.text('Fire drills'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
    expect(find.text('Tutorials'), findsNothing);

    // Dispose so the tutor-response timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a failing server shows the error, not made-up topics', (
    tester,
  ) async {
    await _pump(tester, _TutorialApi(failTopics: true));

    await tester.tap(find.text('Tutorials'));
    await tester.pumpAndSettle();

    expect(find.textContaining('server offline'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  group('TutorialQuestionCard', () {
    const question = TutorialQuestion(
      id: 'q1',
      question: 'Which is red?',
      options: {'option_a': 'Apple', 'option_b': 'Sky'},
      correctOption: 'A',
    );

    Widget host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

    testWidgets('submit needs an option and a confidence', (tester) async {
      (String, TutorialConfidence)? submitted;
      await tester.pumpWidget(
        host(
          TutorialQuestionCard(
            question: question,
            enabled: true,
            accent: Colors.blue,
            isDark: false,
            onSubmit: (o, c) => submitted = (o, c),
          ),
        ),
      );

      FilledButton button() =>
          tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button().onPressed, isNull);

      await tester.tap(find.text('Apple'));
      await tester.pump();
      expect(button().onPressed, isNull);

      await tester.tap(find.text('Mostly sure'));
      await tester.pump();
      await tester.tap(find.text('Submit'));

      expect(submitted, ('option_a', TutorialConfidence.mostlysure));
    });

    testWidgets('answered card is read-only and reveals the verdict', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          TutorialQuestionCard(
            question: question,
            enabled: false,
            reveal: true,
            selectedOption: 'option_b',
            confidence: TutorialConfidence.confident,
            accent: Colors.blue,
            isDark: false,
            onSubmit: (_, _) => fail('must not submit'),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget); // A
      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget); // B
    });
  });
}
