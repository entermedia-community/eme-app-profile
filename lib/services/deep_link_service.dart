import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:eme_world/utils/log.dart';
import '../models/workspace.dart';
import 'auth_service.dart';
import 'workspace_service.dart';

class DeepLinkService {
  static StreamSubscription<Uri>? _sub;
  static final AppLinks _appLinks = AppLinks();

  /// Initialize deep link listening.
  /// Calls [onWorkspaceOpened] when a valid workspace deep link is processed.
  static Future<void> init({
    void Function(Workspace workspace)? onWorkspaceOpened,
  }) async {
    // Handle initial link if app was launched via deep link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleUri(initialUri, onWorkspaceOpened);
      }
    } catch (e) {
      logPrint('Error getting initial deep link: $e');
    }

    // Listen for incoming deep links while app is running
    _sub?.cancel();
    _sub = _appLinks.uriLinkStream.listen(
      (uri) async {
        await _handleUri(uri, onWorkspaceOpened);
      },
      onError: (err) {
        logPrint('Deep link stream error: $err');
      },
    );
  }

  /// Parses a Workspace target from the provided Uri.
  /// Returns null if no matching workspace could be found.
  static Workspace? parseWorkspaceFromUri(Uri uri) {
    String? target;

    // 1. Check query parameters (?workspace=misur or ?id=misur or ?name=misur)
    if (uri.queryParameters.containsKey('workspace')) {
      target = uri.queryParameters['workspace'];
    } else if (uri.queryParameters.containsKey('id')) {
      target = uri.queryParameters['id'];
    } else if (uri.queryParameters.containsKey('name')) {
      target = uri.queryParameters['name'];
    }

    // 2. Check path segments
    if (target == null || target.isEmpty) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

      for (int i = 0; i < segments.length; i++) {
        if (segments[i].toLowerCase() == 'workspace') {
          if (i + 1 < segments.length) {
            target = segments[i + 1];
            break;
          }
        }
      }

      if ((target == null || target.isEmpty) && segments.isNotEmpty) {
        if (uri.host.toLowerCase() == 'workspace') {
          target = segments.first;
        } else if (segments.first.toLowerCase() != 'workspace') {
          target = segments.first;
        }
      }
    }

    // 3. Check scheme host if custom scheme like emeworld://misur
    if ((target == null || target.isEmpty) && uri.host.isNotEmpty) {
      if (uri.host.toLowerCase() != 'workspace' &&
          uri.host.toLowerCase() != 'eme.world' &&
          uri.host.toLowerCase() != 'localhost') {
        target = uri.host;
      }
    }

    if (target == null || target.trim().isEmpty) {
      return null;
    }

    final cleanedTarget = target.trim().toLowerCase();

    // Match with available workspaces
    for (final ws in WorkspaceService.workspaces) {
      if (ws.id.toLowerCase() == cleanedTarget ||
          ws.name.toLowerCase() == cleanedTarget) {
        return ws;
      }
    }

    return null;
  }

  static Future<void> _handleUri(
    Uri uri,
    void Function(Workspace workspace)? onWorkspaceOpened,
  ) async {
    logPrint('Handling deep link URI: $uri');
    final workspace = parseWorkspaceFromUri(uri);
    if (workspace != null) {
      logPrint('Deep link resolved workspace: ${workspace.name} (${workspace.id})');
      await WorkspaceService.setActiveWorkspace(workspace);
      await AuthService.loadSessionForActiveWorkspace();
      if (onWorkspaceOpened != null) {
        onWorkspaceOpened(workspace);
      }
    } else {
      logPrint('No matching workspace found for deep link URI: $uri');
    }
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
