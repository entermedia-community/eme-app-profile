import '../models/workspace.dart';

class WorkspaceService {
  static const List<Workspace> workspaces = [
    Workspace(
      id: 'development',
      name: 'Development',
      mediaDBRoot: 'http://localhost.com:8080/site/mediadb',
    ),
    Workspace(
      id: 'misur',
      name: 'Misur',
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

  static Workspace get activeWorkspace => _activeWorkspace;

  static String get currentMediaDBRoot => _activeWorkspace.mediaDBRoot;

  static void setActiveWorkspace(Workspace workspace) {
    _activeWorkspace = workspace;
  }

  static void setActiveWorkspaceByName(String name) {
    final lowerName = name.toLowerCase();
    final found = workspaces.firstWhere(
      (w) =>
          w.name.toLowerCase() == lowerName || w.id.toLowerCase() == lowerName,
      orElse: () => workspaces.first,
    );
    _activeWorkspace = found;
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
