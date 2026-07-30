import 'package:flutter_test/flutter_test.dart';
import 'package:eme_world/models/workspace.dart';
import 'package:eme_world/services/auth_service.dart';
import 'package:eme_world/services/topic_service.dart';
import 'package:eme_world/services/workspace_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Workspace & WorkspaceService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      // Reset active workspace to default before each test
      WorkspaceService.setActiveWorkspaceByName('Minsur');
    });

    test(
      'WorkspaceService loads 3 static workspaces (Minsur, EME, Development)',
      () {
        final workspaces = WorkspaceService.workspaces;
        expect(workspaces.length, equals(3));

        final names = workspaces.map((w) => w.name).toList();
        expect(names, containsAll(['Minsur', 'EME', 'Development']));

        final minsur = WorkspaceService.getWorkspaceByName('Minsur');
        expect(minsur.id, equals('minsur'));
        expect(
          minsur.mediaDBRoot,
          equals('https://minsur.genailabs.tech/site/mediadb'),
        );

        final eme = WorkspaceService.getWorkspaceByName('EME');
        expect(eme.id, equals('eme'));
        expect(eme.mediaDBRoot, equals('https://eme.world/site/mediadb'));

        final dev = WorkspaceService.getWorkspaceByName('Development');
        expect(dev.id, equals('development'));
        expect(
          dev.mediaDBRoot,
          equals('http://localhost.com:8080/site/mediadb'),
        );
      },
    );

    test(
      'Switching active workspace updates WorkspaceService and AuthService.mediaDBRoot',
      () {
        expect(WorkspaceService.activeWorkspace.name, equals('Minsur'));
        expect(
          AuthService.mediaDBRoot,
          equals('https://minsur.genailabs.tech/site/mediadb'),
        );

        // Switch to EME
        WorkspaceService.setActiveWorkspaceByName('EME');
        expect(WorkspaceService.activeWorkspace.name, equals('EME'));
        expect(
          WorkspaceService.currentMediaDBRoot,
          equals('https://eme.world/site/mediadb'),
        );
        expect(
          AuthService.mediaDBRoot,
          equals('https://eme.world/site/mediadb'),
        );

        // Switch to Development
        WorkspaceService.setActiveWorkspaceByName('Development');
        expect(WorkspaceService.activeWorkspace.name, equals('Development'));
        expect(
          WorkspaceService.currentMediaDBRoot,
          equals('http://localhost.com:8080/site/mediadb'),
        );
        expect(
          AuthService.mediaDBRoot,
          equals('http://localhost.com:8080/site/mediadb'),
        );

        // TopicService should also reflect current active workspace mediaDBRoot
        final topicService = TopicService();
        expect(
          topicService.mediaDBRoot,
          equals('http://localhost.com:8080/site/mediadb'),
        );
      },
    );

    test('Workspace model JSON serialization', () {
      final ws = const Workspace(
        id: 'test_id',
        name: 'Test Workspace',
        mediaDBRoot: 'http://test.com/site/mediadb',
        iconAsset: 'assets/test.png',
      );

      final json = ws.toJson();
      expect(json['id'], equals('test_id'));
      expect(json['name'], equals('Test Workspace'));
      expect(json['mediaDBRoot'], equals('http://test.com/site/mediadb'));
      expect(json['iconAsset'], equals('assets/test.png'));

      final deserialized = Workspace.fromJson(json);
      expect(deserialized, equals(ws));
    });
  });
}
