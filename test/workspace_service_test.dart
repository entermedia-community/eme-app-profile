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

    test('Dynamic Workspace creation requiring only mediaDBRoot', () {
      final ws1 = Workspace.fromMediaDBRoot('https://minsur.genailabs.tech/site/mediadb');
      expect(ws1.id, equals('minsur'));
      expect(ws1.name, equals('Minsur'));
      expect(ws1.mediaDBRoot, equals('https://minsur.genailabs.tech/site/mediadb'));
      expect(ws1.iconAsset, isNull);

      final ws2 = Workspace.fromMediaDBRoot('http://localhost:8080/site/mediadb');
      expect(ws2.id, equals('localhost'));
      expect(ws2.name, equals('Localhost'));
      expect(ws2.iconAsset, isNull);

      final ws3 = Workspace.fromJson({
        'mediadbroot': 'https://custom-portal.org/site/mediadb',
      });
      expect(ws3.id, equals('custom-portal'));
      expect(ws3.name, equals('Custom-portal'));
      expect(ws3.iconAsset, isNull);
    });

    test('WorkspaceService dynamically registers new workspace from mediaDBRoot', () {
      final dynWs = WorkspaceService.getOrCreateWorkspaceFromMediaDBRoot(
        'https://newdomain.com/site/mediadb',
      );
      expect(dynWs.id, equals('newdomain'));
      expect(dynWs.name, equals('Newdomain'));
      expect(dynWs.mediaDBRoot, equals('https://newdomain.com/site/mediadb'));
      expect(WorkspaceService.workspaces, contains(dynWs));
    });

    test('WorkspaceService removes workspace and falls back active workspace', () async {
      final dynWs = WorkspaceService.getOrCreateWorkspaceFromMediaDBRoot(
        'https://deleteme.com/site/mediadb',
      );
      expect(WorkspaceService.workspaces, contains(dynWs));

      await WorkspaceService.setActiveWorkspace(dynWs);
      expect(WorkspaceService.activeWorkspace.id, equals('deleteme'));

      final canDel = WorkspaceService.canDeleteWorkspace(dynWs);
      expect(canDel, isTrue);

      final success = await WorkspaceService.removeWorkspace(dynWs);
      expect(success, isTrue);
      expect(WorkspaceService.workspaces, isNot(contains(dynWs)));
      expect(WorkspaceService.activeWorkspace.id, isNot(equals('deleteme')));
    });
  });
}
