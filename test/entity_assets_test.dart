import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/entity_asset/entity_asset_viewer_screen.dart';
import 'package:eme_world/screens/project/project_screen.dart';
import 'package:eme_world/widgets/files/files_section.dart';
import 'test_helpers.dart';

void main() {
  const asset = EntityAssetModel(id: 'ea_1', name: 'Land Deed');

  testWidgets('Digital Legacy lists the user\'s entity assets', (tester) async {
    final api = MockApiService()..entityAssets['me'] = [asset];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(api)],
        child: const MaterialApp(home: Scaffold(body: FilesSection())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your Digital Legacy'), findsOneWidget);
    expect(find.text('Land Deed'), findsOneWidget);
    expect(find.bySemanticsIdentifier('entity_asset_ea_1'), findsOneWidget);
  });

  testWidgets('empty list says so', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(MockApiService())],
        child: const MaterialApp(home: Scaffold(body: FilesSection())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No entity assets yet.'), findsOneWidget);
  });

  testWidgets('project menu opens that project\'s entity assets', (
    tester,
  ) async {
    const collection = LibraryCollectionModel(id: 'coll_123', name: 'Water');
    final api = MockApiService()..entityAssets['coll_123'] = [asset];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(api)],
        child: MaterialApp(home: ProjectScreen.fromCollection(collection)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('project_menu_button'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('project_menu_entity_assets'));
    await tester.pumpAndSettle();

    expect(find.text('Land Deed'), findsOneWidget);
  });

  testWidgets('tapping an asset shows its details', (tester) async {
    final detailed = EntityAssetModel(
      id: 'ea_2',
      name: 'Land Deed',
      tags: const ['legal', 'land'],
      uploadDate: DateTime(2026, 9, 11, 12),
      mediaUrl: 'http://localhost/deed.pdf',
      mediaType: 'pdf',
    );
    final api = MockApiService()..entityAssets['me'] = [detailed];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiServiceProvider.overrideWithValue(api)],
        child: const MaterialApp(home: Scaffold(body: FilesSection())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('entity_asset_ea_2'));
    await tester.pumpAndSettle();

    expect(find.text('Land Deed'), findsOneWidget);
    expect(find.text('legal'), findsOneWidget);
    expect(find.text('land'), findsOneWidget);
    expect(find.text('2026-09-11'), findsOneWidget);
    expect(
      find.bySemanticsIdentifier('entity_asset_thumbnail'),
      findsOneWidget,
    );
  });

  testWidgets('other file types offer a download', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(
        home: EntityAssetViewerScreen(
          asset: EntityAssetModel(
            id: 'ea_3',
            name: 'Archive',
            mediaUrl: 'http://localhost/a.zip',
            mediaType: 'other',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsIdentifier('entity_asset_download'), findsOneWidget);
  });
}
