import 'package:flutter_test/flutter_test.dart';
import 'package:eme_world/services/deep_link_service.dart';

void main() {
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
}
