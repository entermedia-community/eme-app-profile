import 'package:shared_preferences/shared_preferences.dart';
import '../models/workspace.dart';

class WorkspaceService {
  static const List<Workspace> workspaces = [
    Workspace(
      id: 'development',
      name: 'Development',
      mediaDBRoot: 'http://localhost.com:8080/site/mediadb',
    ),
    Workspace(
      id: 'minsur',
      name: 'Minsur',
      mediaDBRoot: 'https://minsur.genailabs.tech/site/mediadb',
      iconAsset: 'assets/minsur.png',
    ),
    Workspace(
      id: 'eme',
      name: 'EME',
      mediaDBRoot: 'https://eme.world/site/mediadb',
    ),
  ];

  static Workspace _activeWorkspace = workspaces.first;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('selected_workspace_id');
    if (savedId != null && savedId.isNotEmpty) {
      final found = workspaces.firstWhere(
        (w) =>
            w.id.toLowerCase() == savedId.toLowerCase() ||
            w.name.toLowerCase() == savedId.toLowerCase(),
        orElse: () => workspaces.first,
      );
      _activeWorkspace = found;
    }
  }

  static Workspace get activeWorkspace => _activeWorkspace;

  static String get currentMediaDBRoot => _activeWorkspace.mediaDBRoot;

  static Future<void> setActiveWorkspace(Workspace workspace) async {
    _activeWorkspace = workspace;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_workspace_id', workspace.id);
  }

  static Future<void> setActiveWorkspaceByName(String name) async {
    final lowerName = name.toLowerCase();
    final found = workspaces.firstWhere(
      (w) =>
          w.name.toLowerCase() == lowerName || w.id.toLowerCase() == lowerName,
      orElse: () => workspaces.first,
    );
    await setActiveWorkspace(found);
  }

  static Workspace getWorkspaceByName(String name) {
    final lowerName = name.toLowerCase();
    return workspaces.firstWhere(
      (w) =>
          w.name.toLowerCase() == lowerName || w.id.toLowerCase() == lowerName,
      orElse: () => workspaces.first,
    );
  }
}
