import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/project/project_screen.dart';
import 'package:eme_world/screens/server/tabs/server_files_tab.dart';
import 'package:eme_world/screens/server/tabs/server_chat_tab.dart';
import 'package:eme_world/screens/server/tabs/server_finance_tab.dart';
import 'package:eme_world/screens/server/tabs/server_goals_tab.dart';
import 'package:eme_world/widgets/delta_viewer.dart';
import 'package:eme_world/widgets/search/unified_search_screen.dart';
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

    // Verify the bottom tabs exist and default to Chat
    expect(
      find.byKey(const ValueKey('project_chat_proj_alpha')),
      findsOneWidget,
    );
    expect(find.byType(ServerChatTab), findsOneWidget);

    // Verify Semantics identifiers
    expect(find.bySemanticsIdentifier('project_back_button'), findsOneWidget);
    expect(find.bySemanticsIdentifier('project_nav_chat'), findsOneWidget);
  });

  testWidgets('Project tabs are Chat, Files, Goals, Finances', (tester) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(ProjectView.values.map((v) => v.label).toList(), [
      'Chat',
      'Files',
      'Goals',
      'Finances',
    ]);

    await tester.tap(find.bySemanticsIdentifier('project_nav_files'));
    await tester.pumpAndSettle();
    expect(find.byType(ServerFilesTab), findsOneWidget);
  });

  testWidgets('Info sheet says when no collection is linked', (tester) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('project_info_button'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not linked to a collection'), findsOneWidget);
  });

  testWidgets('ProjectScreen switches views using the bottom tabs', (
    tester,
  ) async {
    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsIdentifier('project_nav_goals'));
    await tester.pumpAndSettle();
    expect(find.byType(ServerGoalsTab), findsOneWidget);
    expect(find.byType(ServerChatTab), findsNothing);

    await tester.tap(find.bySemanticsIdentifier('project_nav_finances'));
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

    // Info sheet shows the web sidebar sections from the fetched collection.
    await tester.tap(find.bySemanticsIdentifier('project_info_button'));
    await tester.pumpAndSettle();

    expect(find.text('Agents'), findsOneWidget);
    expect(find.text('Alice Smith'), findsOneWidget);
    expect(find.text('Lead'), findsOneWidget);
    expect(find.text('Donate'), findsNWidgets(2));
    expect(find.text('Help us build wells'), findsOneWidget);
    expect(find.text('Testimonials'), findsOneWidget);
    final testimonial = tester.widget<DeltaViewer>(find.byType(DeltaViewer));
    expect(
      testimonial.deltaOps.map((op) => op['insert']).join(),
      contains('Changed our village.'),
    );
    expect(find.text('water@example.com'), findsOneWidget);
  });

  testWidgets('Info sheet shows the load error with retry', (tester) async {
    const collection = LibraryCollectionModel(id: 'missing', name: 'Gone');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(MockApiService())],
        child: MaterialApp(home: ProjectScreen.fromCollection(collection)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('project_info_button'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Could not load project details'),
      findsOneWidget,
    );
    expect(find.bySemanticsIdentifier('project_info_retry'), findsOneWidget);
  });

  group('Project from a collection', () {
    const collection = LibraryCollectionModel(
      id: 'coll_123',
      name: 'Clean Water Initiative',
    );

    Future<MockApiService> pumpProject(
      WidgetTester tester, {
      bool canEdit = true,
      String privacy = 'community',
      ProjectView initialView = ProjectView.chat,
      LibraryCollectionModel project = collection,
    }) async {
      final mockApi = MockApiService()
        ..projectCanEdit = canEdit
        ..projectPrivacy = privacy;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiServiceProvider.overrideWithValue(mockApi)],
          child: MaterialApp(
            home: ProjectScreen.fromCollection(
              project,
              initialView: initialView,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return mockApi;
    }

    List<String> visibleTabs() => ProjectView.values
        .where(
          (v) => find
              .bySemanticsIdentifier('project_nav_${v.name}')
              .evaluate()
              .isNotEmpty,
        )
        .map((v) => v.label)
        .toList();

    testWidgets('chat uses the project team channel', (tester) async {
      await pumpProject(tester);
      final chat = tester.widget<ServerChatTab>(find.byType(ServerChatTab));
      expect(chat.projectCollectionId, 'coll_123');
      expect(find.textContaining('Could not open the chat'), findsNothing);
    });

    testWidgets('editors see every tab', (tester) async {
      await pumpProject(tester);
      expect(visibleTabs(), ['Chat', 'Files', 'Goals', 'Finances']);
    });

    testWidgets('non-editors only see Chat, Files and Finances', (
      tester,
    ) async {
      await pumpProject(tester, canEdit: false);
      expect(visibleTabs(), ['Chat', 'Files', 'Finances']);
    });

    testWidgets('non-editors of a commercial project lose Finances', (
      tester,
    ) async {
      await pumpProject(tester, canEdit: false, privacy: 'commercial');
      expect(visibleTabs(), ['Chat', 'Files']);
    });

    testWidgets('a hidden initial view falls back to Chat', (tester) async {
      await pumpProject(tester, canEdit: false, initialView: ProjectView.goals);
      expect(find.byType(ServerGoalsTab), findsNothing);
      expect(find.byType(ServerChatTab), findsOneWidget);
    });

    testWidgets('Follow button toggles and shows followers', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final api = await pumpProject(tester);
      await tester.tap(find.bySemanticsIdentifier('project_info_button'));
      await tester.pumpAndSettle();

      expect(find.text('3 Followers'), findsOneWidget);
      await tester.tap(find.bySemanticsIdentifier('project_follow_button'));
      await tester.pumpAndSettle();
      expect(api.followToggles, 1);
    });

    testWidgets('chat shows an error when the project channel fails', (
      tester,
    ) async {
      await pumpProject(
        tester,
        project: const LibraryCollectionModel(id: 'missing', name: 'Gone'),
      );
      expect(find.textContaining('Could not open the chat'), findsOneWidget);
      expect(find.bySemanticsIdentifier('server_chat_retry'), findsOneWidget);
    });
  });

  test('chat list includes the user\'s projects', () async {
    const project = LibraryCollectionModel(id: 'coll_9', name: 'Wells');
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(MockApiService()),
        apiChatsProvider.overrideWith((ref) async => const []),
        userServersProvider.overrideWith((ref) async => const []),
        userProjectsProvider.overrideWith((ref) async => const [project]),
      ],
    );
    addTearDown(container.dispose);
    await container.read(userProjectsProvider.future);
    await container.read(apiChatsProvider.future);
    await container.read(userServersProvider.future);

    final items = container.read(unifiedChatsProvider).value!;
    final projects = items.where((i) => i.isProject).toList();
    expect(projects, hasLength(1));
    expect(projects.single.projectCollection, project);
    expect(projects.single.displayName, 'Wells');
  });

  group('Project info sheet actions', () {
    const collection = LibraryCollectionModel(
      id: 'coll_123',
      name: 'Clean Water Initiative',
    );

    Future<MockApiService> openInfo(
      WidgetTester tester, {
      bool canEdit = true,
      bool canViewSettings = false,
    }) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final mockApi = MockApiService()
        ..projectCanEdit = canEdit
        ..projectCanViewSettings = canViewSettings;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [apiServiceProvider.overrideWithValue(mockApi)],
          child: MaterialApp(home: ProjectScreen.fromCollection(collection)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('project_info_button'));
      await tester.pumpAndSettle();
      return mockApi;
    }

    testWidgets('Donate button and links are tappable', (tester) async {
      await openInfo(tester);
      expect(
        find.bySemanticsIdentifier('project_donate_button'),
        findsOneWidget,
      );
      expect(find.bySemanticsIdentifier('project_link_email'), findsOneWidget);
      expect(
        find.bySemanticsIdentifier('project_link_website'),
        findsOneWidget,
      );
    });

    testWidgets('edit pencil only with canviewsettings', (tester) async {
      await openInfo(tester);
      expect(find.bySemanticsIdentifier('project_edit_member_0'), findsNothing);
    });

    testWidgets('settings users edit a member\'s roles', (tester) async {
      final api = await openInfo(tester, canViewSettings: true);
      await tester.tap(find.bySemanticsIdentifier('project_edit_member_0'));
      await tester.pumpAndSettle();

      // Starts with the member's current role selected.
      final lead = tester.widget<FilterChip>(
        find.descendant(
          of: find.bySemanticsIdentifier('project_member_role_role_1'),
          matching: find.byType(FilterChip),
        ),
      );
      expect(lead.selected, true);

      await tester.tap(
        find.bySemanticsIdentifier('project_member_role_role_2'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('project_member_save'));
      await tester.pumpAndSettle();

      expect(api.memberUpdates, ['m1:true:role_1,role_2']);
    });

    testWidgets('non-editors do not get team actions', (tester) async {
      await openInfo(tester, canEdit: false);
      expect(find.bySemanticsIdentifier('project_add_agent'), findsNothing);
      expect(find.bySemanticsIdentifier('project_new_user'), findsNothing);
    });

    testWidgets('Add Agent searches people and adds one to the team', (
      tester,
    ) async {
      final api = await openInfo(tester);
      await tester.tap(find.bySemanticsIdentifier('project_add_agent'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.bySemanticsIdentifier('project_add_agent_input'),
          matching: find.byType(TextField),
        ),
        'admin',
      );
      await tester.tap(find.bySemanticsIdentifier('project_add_agent_search'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.bySemanticsIdentifier('project_add_agent_result_0'),
      );
      await tester.pumpAndSettle();

      expect(api.addedTeamMembers, ['admin']);
      expect(find.text('Added to the team'), findsOneWidget);
    });

    testWidgets('New User adds by email', (tester) async {
      final api = await openInfo(tester);
      await tester.tap(find.bySemanticsIdentifier('project_new_user'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: find.bySemanticsIdentifier('project_new_user_email'),
          matching: find.byType(TextField),
        ),
        'new@example.com',
      );
      await tester.tap(find.bySemanticsIdentifier('project_new_user_submit'));
      await tester.pumpAndSettle();

      expect(api.addedTeamMembers, ['new@example.com']);
    });
  });

  testWidgets('Search lists matching projects and opens one', (tester) async {
    const project = LibraryCollectionModel(
      id: 'coll_123',
      name: 'Clean Water Initiative',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(
            MockApiService()..searchableProjects.add(project),
          ),
        ],
        child: const MaterialApp(home: UnifiedSearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('search_type_projects'));
    await tester.pumpAndSettle();

    expect(find.text('Clean Water Initiative'), findsOneWidget);
    expect(find.text('Eco Collective Mobile App'), findsNothing);

    await tester.tap(find.bySemanticsIdentifier('search_result_0'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('project_preview_primary'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectScreen), findsOneWidget);
  });

  testWidgets('Info sheet from the live server matches the web sidebar', (
    tester,
  ) async {
    // Captured from GET librarycollection/data/{id} on a local
    // eme-server-world; the web project chat page for the same project
    // showed: Agents (Admin, Add Agent, New User), Donate, 0 Followers /
    // Follow, Testimonials, then the website and Facebook links.
    final hit =
        jsonDecode(
              File('test/fixtures/project_hit_live.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    final live = LibraryCollectionModel.fromJson(hit);
    final api = _LiveProjectApi(live)
      ..projectCanEdit = true
      ..projectCanViewSettings = true;

    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(api)],
        child: MaterialApp(home: ProjectScreen.fromCollection(live)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('project_info_button'));
    await tester.pumpAndSettle();

    expect(find.text('Claude Web Compare'), findsWidgets);
    expect(find.text('The Administrator'), findsOneWidget);
    expect(find.bySemanticsIdentifier('project_add_agent'), findsOneWidget);
    expect(find.bySemanticsIdentifier('project_new_user'), findsOneWidget);
    expect(find.bySemanticsIdentifier('project_edit_member_0'), findsOneWidget);
    expect(find.text('Be a Part of This Project'), findsOneWidget);
    expect(find.bySemanticsIdentifier('project_donate_button'), findsOneWidget);
    expect(find.text('0 Followers'), findsOneWidget);
    expect(find.bySemanticsIdentifier('project_follow_button'), findsOneWidget);
    expect(find.bySemanticsIdentifier('project_link_website'), findsOneWidget);
    expect(find.bySemanticsIdentifier('project_link_facebook'), findsOneWidget);

    // Same top-to-bottom order as the web sidebar.
    double top(String heading) =>
        tester.getTopLeft(find.text(heading).first).dy;
    final order = ['Agents', 'Donate', 'Followers', 'Testimonials', 'Links'];
    for (var i = 1; i < order.length; i++) {
      expect(top(order[i - 1]), lessThan(top(order[i])), reason: order[i]);
    }
  });
}

/// Serves the live-captured project instead of the canned one.
class _LiveProjectApi extends MockApiService {
  final LibraryCollectionModel live;

  _LiveProjectApi(this.live);

  @override
  Future<LibraryCollectionModel> fetchProjectCollection(
    String collectionId, {
    String? baseUrl,
  }) async => live;

  @override
  Future<ProjectChatConnection> connectProjectChat(
    String collectionId, {
    Map<String, dynamic>? params,
  }) async => ProjectChatConnection(
    channelId: 'AaFhNKJR3N_9x6csJT9l',
    canEditCollection: projectCanEdit,
    canViewSettings: projectCanViewSettings,
  );
}
