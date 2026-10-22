import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/project/project_screen.dart';
import 'package:eme_world/screens/project/tabs/project_settings_tab.dart';
import 'package:eme_world/screens/server/tabs/server_chat_tab.dart';
import 'package:eme_world/screens/server/tabs/server_finance_tab.dart';
import 'package:eme_world/screens/server/tabs/server_goals_tab.dart';
import 'test_helpers.dart';

void main() {
  const testServer = ServerModel(
    id: 'proj_alpha',
    name: 'Alpha Collective',
    description: 'Autonomous open community collective project',
    category: ServerCategoryModel(id: 'collab', name: 'Collaboration'),
    primaryColor: Color(0xFF2563EB),
    memberCount: 8,
  );

  Widget createSubject({ProjectView initialView = ProjectView.chat}) {
    final mockApi = MockApiService();
    return ProviderScope(
      overrides: [apiServiceProvider.overrideWithValue(mockApi)],
      child: MaterialApp(
        home: ProjectScreen(server: testServer, initialView: initialView),
      ),
    );
  }

  testWidgets('ProjectScreen renders with default chat view', (tester) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // Verify Project Name is present
    expect(find.text('Alpha Collective'), findsOneWidget);

    // Verify Dropdown exists and defaults to Chat
    expect(
      find.byKey(const ValueKey('project_chat_proj_alpha')),
      findsOneWidget,
    );
    expect(find.byType(ServerChatTab), findsOneWidget);

    // Verify Semantics identifiers
    expect(find.bySemanticsIdentifier('project_back_button'), findsOneWidget);
    expect(find.bySemanticsIdentifier('project_view_dropdown'), findsOneWidget);
  });

  testWidgets('ProjectScreen can switch views', (tester) async {
    await tester.pumpWidget(createSubject(initialView: ProjectView.settings));
    await tester.pumpAndSettle();

    expect(find.byType(ProjectSettingsTab), findsOneWidget);
    expect(find.text('Project Details'), findsOneWidget);
    expect(find.text('Notifications & Preferences'), findsOneWidget);
  });

  testWidgets('ProjectScreen switches views using top dropdown', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    // Switch to Goals by opening dropdown and tapping Goals
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('project_view_item_goals')).last,
    );
    await tester.pumpAndSettle();

    expect(find.byType(ServerGoalsTab), findsOneWidget);
    expect(find.byType(ServerChatTab), findsNothing);

    // Switch to Finances
    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('project_view_item_finances')).last,
    );
    await tester.pumpAndSettle();

    expect(find.byType(ServerFinanceTab), findsOneWidget);
  });

  testWidgets('ProjectScreen can be created from LibraryCollectionModel', (
    tester,
  ) async {
    const collection = LibraryCollectionModel(
      id: 'coll_123',
      name: 'Clean Water Initiative',
      description: 'Decentralized ecological project',
      collectionType: 'Ecological',
    );

    final mockApi = MockApiService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(mockApi)],
        child: MaterialApp(home: ProjectScreen.fromCollection(collection)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Clean Water Initiative'), findsOneWidget);
    expect(find.byType(ServerChatTab), findsOneWidget);
  });
}
