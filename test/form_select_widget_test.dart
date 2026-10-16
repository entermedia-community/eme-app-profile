import 'package:flutter/material.dart' hide FormField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/server/tabs/server_chat_tab.dart';
import 'test_helpers.dart';

class _MockFormApiService extends MockApiService {
  final List<ChatMessage> mockMessages;
  _MockFormApiService(this.mockMessages);

  @override
  Future<List<ChatMessage>> fetchServerChatMessages(
    String channelId, {
    String? serverId,
    String? baseUrl,
  }) async {
    return mockMessages;
  }
}

void main() {
  group('ServerChatTab Form Select Dropdown Tests', () {
    const testServer = ServerModel(
      id: 'srv_form_test',
      name: 'Test Server',
      description: 'Test Server Description',
      category: ServerCategoryModel(id: 'all', name: 'All'),
      primaryColor: Color(0xFF2563EB),
    );

    testWidgets(
      'renders select dropdown with FormField options and allows selecting and submitting',
      (tester) async {
        final formMessage = ChatMessage(
          messageId: 'msg_form_1',
          channel: 'srv_form_test',
          userId: 'bot_form',
          message: 'Please complete the form',
          messageType: 'form',
          agentContextValues: AgentContextValues(
            messageRenderType: MessageRenderType.form,
          ),
          createdAt: DateTime.now(),
        );

        final mockApi = _MockFormApiService([formMessage]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [apiServiceProvider.overrideWithValue(mockApi)],
            child: const MaterialApp(
              home: Scaffold(body: ServerChatTab(server: testServer)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check that dropdown with initial value 'Technology' is rendered
        expect(find.text('Technology'), findsOneWidget);

        // Tap the dropdown to open it
        await tester.tap(find.text('Technology'));
        await tester.pumpAndSettle();

        // Verify the other options are visible in the overlay
        expect(find.text('Design').last, findsOneWidget);
        expect(find.text('Marketing').last, findsOneWidget);

        // Select 'Design'
        await tester.tap(find.text('Design').last);
        await tester.pumpAndSettle();

        // Submit the form
        expect(find.text('Submit'), findsOneWidget);
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        // Verify the submission badge and message are updated
        expect(find.text('SUBMITTED'), findsOneWidget);
        expect(find.textContaining('category: design'), findsOneWidget);
      },
    );
  });
}
