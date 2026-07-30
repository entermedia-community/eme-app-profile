import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eme_world/services/deep_link_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeepLinkService URI Parsing Tests', () {
    test('Parses custom scheme emeworld://workspace/minsur', () {
      final uri = Uri.parse('emeworld://workspace/minsur');
      final ws = DeepLinkService.parseWorkspaceFromUri(uri);
      expect(ws, isNotNull);
      expect(ws!.id, equals('minsur'));
      expect(ws.name, equals('Minsur'));
    });

    test('Parses custom scheme emeworld://workspace/eme', () {
      final uri = Uri.parse('emeworld://workspace/eme');
      final ws = DeepLinkService.parseWorkspaceFromUri(uri);
      expect(ws, isNotNull);
      expect(ws!.id, equals('eme'));
      expect(ws.name, equals('EME'));
    });

    test('Parses custom scheme emeworld://development', () {
      final uri = Uri.parse('emeworld://development');
      final ws = DeepLinkService.parseWorkspaceFromUri(uri);
      expect(ws, isNotNull);
      expect(ws!.id, equals('development'));
      expect(ws.name, equals('Development'));
    });

    test('Parses query parameter emeworld://workspace?id=minsur', () {
      final uri = Uri.parse('emeworld://workspace?id=minsur');
      final ws = DeepLinkService.parseWorkspaceFromUri(uri);
      expect(ws, isNotNull);
      expect(ws!.id, equals('minsur'));
    });

    test('Parses query parameter emeworld://workspace?workspace=eme', () {
      final uri = Uri.parse('emeworld://workspace?workspace=eme');
      final ws = DeepLinkService.parseWorkspaceFromUri(uri);
      expect(ws, isNotNull);
      expect(ws!.id, equals('eme'));
    });

    test('Parses HTTPS universal link https://eme.world/workspace/minsur', () {
      final uri = Uri.parse('https://eme.world/workspace/minsur');
      final ws = DeepLinkService.parseWorkspaceFromUri(uri);
      expect(ws, isNotNull);
      expect(ws!.id, equals('minsur'));
    });

    test('Parses HTTPS universal link https://eme.world/eme', () {
      final uri = Uri.parse('https://eme.world/eme');
      final ws = DeepLinkService.parseWorkspaceFromUri(uri);
      expect(ws, isNotNull);
      expect(ws!.id, equals('eme'));
    });

    test('Returns null for unknown workspace target', () {
      final uri = Uri.parse('emeworld://workspace/unknown_workspace_id');
      final ws = DeepLinkService.parseWorkspaceFromUri(uri);
      expect(ws, isNull);
    });

    test('Returns null for empty or invalid URIs', () {
      final uri = Uri.parse('emeworld://');
      final ws = DeepLinkService.parseWorkspaceFromUri(uri);
      expect(ws, isNull);
    });
  });

  group('DeepLinkService Parameter Parsing Tests', () {
    test('Extracts standard query parameters', () {
      final uri = Uri.parse(
        'https://app.eme.world/?workspace=minsur&user=admin&entermediakey=secret123&ref=campaign',
      );
      final params = DeepLinkService.parseParametersFromUri(uri);
      expect(params['workspace'], equals('minsur'));
      expect(params['user'], equals('admin'));
      expect(params['entermediakey'], equals('secret123'));
      expect(params['ref'], equals('campaign'));
    });

    test('Extracts fragment query parameters on Flutter Web', () {
      final uri = Uri.parse(
        'http://localhost:8080/#/?workspace=eme&username=john&token=tok_xyz&route=dashboard',
      );
      final params = DeepLinkService.parseParametersFromUri(uri);
      expect(params['workspace'], equals('eme'));
      expect(params['user'], equals('john'));
      expect(params['entermediakey'], equals('tok_xyz'));
      expect(params['route'], equals('dashboard'));
    });

    test('Normalizes parameter key aliases (ws, userId, key, otp)', () {
      final uri = Uri.parse(
        'https://eme.world/?ws=minsur&userId=usr1&key=k1&otp=654321',
      );
      final params = DeepLinkService.parseParametersFromUri(uri);
      expect(params['workspace'], equals('minsur'));
      expect(params['user'], equals('usr1'));
      expect(params['entermediakey'], equals('k1'));
      expect(params['templogincode'], equals('654321'));
    });

    test('Parses web hash fragment path workspace', () {
      final uri = Uri.parse('http://localhost:8080/#/workspace/minsur?lang=en');
      final params = DeepLinkService.parseParametersFromUri(uri);
      expect(params['workspace'], equals('minsur'));
      expect(params['lang'], equals('en'));
      final ws = DeepLinkService.parseWorkspaceFromUri(uri);
      expect(ws, isNotNull);
      expect(ws!.id, equals('minsur'));
    });

    test('Resolves dynamic workspace from mediadbroot parameter in URL', () {
      final uri = Uri.parse(
        'http://localhost:8080/?mediadbroot=https://dynamic-server.com/site/mediadb',
      );
      final ws = DeepLinkService.parseWorkspaceFromUri(uri);
      expect(ws, isNotNull);
      expect(ws!.id, equals('dynamic-server'));
      expect(ws.name, equals('Dynamic-server'));
      expect(ws.mediaDBRoot, equals('https://dynamic-server.com/site/mediadb'));
      expect(ws.iconAsset, isNull);
    });
  });
}
