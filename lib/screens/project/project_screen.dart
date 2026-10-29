import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../server/tabs/server_chat_tab.dart';
import '../server/tabs/server_files_tab.dart';
import '../server/tabs/server_finance_tab.dart';
import '../server/tabs/server_goals_tab.dart';
import 'widgets/project_info_sheet.dart';
import 'widgets/project_team_sheet.dart';

/// Views of [ProjectScreen], shown as bottom tabs in this order.
enum ProjectView {
  chat('Chat', Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded),
  files('Files', Icons.folder_open_rounded, Icons.folder_rounded),
  goals('Goals', Icons.flag_outlined, Icons.flag_rounded),
  finances(
    'Finances',
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet_rounded,
  );

  final String label;
  final IconData icon;
  final IconData activeIcon;

  const ProjectView(this.label, this.icon, this.activeIcon);

  /// Mirrors the web menu's rules: Goals needs edit rights
  /// (`caneditcollection`), Finances is open unless the project is commercial.
  bool isVisible({required bool canEdit, required bool isCommercial}) {
    switch (this) {
      case ProjectView.goals:
        return canEdit;
      case ProjectView.finances:
        return canEdit || !isCommercial;
      case ProjectView.chat:
      case ProjectView.files:
        return true;
    }
  }
}

/// Project screen, the app's version of the web project chat page
/// (`project/chat/index.html`): team chat as the default view, bottom tabs
/// for the other menu sections, and an info button that opens the web page's
/// right sidebar (team, donate, testimonials, links) as a sheet.
class ProjectScreen extends ConsumerStatefulWidget {
  final ServerModel server;
  final LibraryCollectionModel? collection;
  final ProjectView initialView;

  const ProjectScreen({
    super.key,
    required this.server,
    this.collection,
    this.initialView = ProjectView.chat,
  });

  /// Factory helper to build a [ProjectScreen] directly from a [LibraryCollectionModel].
  factory ProjectScreen.fromCollection(
    LibraryCollectionModel collection, {
    ProjectView initialView = ProjectView.chat,
  }) {
    return ProjectScreen(
      server: _serverFromCollection(collection),
      collection: collection,
      initialView: initialView,
    );
  }

  static Route<void> routeForCollection(
    LibraryCollectionModel collection, {
    ProjectView initialView = ProjectView.chat,
  }) {
    return route(
      server: _serverFromCollection(collection),
      collection: collection,
      initialView: initialView,
    );
  }

  static ServerModel _serverFromCollection(LibraryCollectionModel collection) {
    return ServerModel(
      id: collection.id,
      name: collection.name.isNotEmpty ? collection.name : 'Project',
      description: collection.displayDescription,
      category: const ServerCategoryModel(id: 'project', name: 'Project'),
      primaryColor: const Color(0xFF3B82F6),
      avatarUrl: collection.primaryImageUrl,
      serverMediaDBUrl: '',
      memberCount: 1,
    );
  }

  static Route<void> route({
    required ServerModel server,
    LibraryCollectionModel? collection,
    ProjectView initialView = ProjectView.chat,
  }) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => ProjectScreen(
        server: server,
        collection: collection,
        initialView: initialView,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  late ProjectView _activeView;

  @override
  void initState() {
    super.initState();
    _activeView = widget.initialView;
  }

  /// The project's `librarycollection` id, or null for an EME Server listed
  /// as a project (no collection behind it).
  String? get _collectionId {
    final id = widget.collection?.id;
    return (id == null || id.isEmpty) ? null : id;
  }

  /// Key for [projectCollectionProvider], or null without a collection.
  ProjectCollectionKey? get _collectionKey {
    final id = _collectionId;
    if (id == null) return null;
    return (collectionId: id, baseUrl: widget.server.serverMediaDBUrl);
  }

  /// Views the user may open. For a collection, edit rights come from the
  /// chat connection (`caneditcollection`); until it loads, or if it fails,
  /// only the views open to everyone are shown. An EME Server project has no
  /// collection permissions, so it shows every view.
  List<ProjectView> _visibleViews(LibraryCollectionModel? collection) {
    final id = _collectionId;
    if (id == null) return ProjectView.values;
    final canEdit =
        ref
            .watch(projectChatConnectionProvider(id))
            .valueOrNull
            ?.canEditCollection ??
        false;
    return ProjectView.values
        .where(
          (v) => v.isVisible(
            canEdit: canEdit,
            isCommercial: collection?.isCommercial ?? false,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final serverState = ref.watch(serverProvider);

    final currentServer = serverState.servers.firstWhere(
      (s) => s.id == widget.server.id,
      orElse: () => widget.server,
    );

    final key = _collectionKey;
    final AsyncValue<LibraryCollectionModel>? collectionAsync = key == null
        ? null
        : ref.watch(projectCollectionProvider(key));
    final collection = collectionAsync?.valueOrNull ?? widget.collection;
    final views = _visibleViews(collection);
    final activeView = views.contains(_activeView)
        ? _activeView
        : ProjectView.chat;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'project_back_button',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Project Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: currentServer.primaryColor.withValues(
                  alpha: isDark ? 0.25 : 0.12,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: currentServer.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  currentServer.avatarUrl != null &&
                      currentServer.avatarUrl!.isNotEmpty
                  ? Image.network(
                      currentServer.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          currentServer.displayInitials,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: currentServer.primaryColor,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        currentServer.displayInitials,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          color: currentServer.primaryColor,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 8),

            // Project Title & View Selector Dropdown
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentServer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textDarkPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Semantics(
            identifier: 'project_menu_button',
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'More',
              onSelected: (value) {
                switch (value) {
                  case 'teams':
                    ProjectTeamSheet.show(context, collectionKey: key);
                  case 'entity_assets':
                    // TODO: list the entity assets associated with this project.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Entity Assets is not available yet'),
                      ),
                    );
                  case 'settings':
                    ProjectInfoSheet.show(
                      context,
                      server: currentServer,
                      collectionKey: key,
                    );
                }
              },
              itemBuilder: (_) => [
                _menuItem('teams', 'Teams', Icons.groups_rounded),
                _menuItem(
                  'entity_assets',
                  'Entity Assets',
                  Icons.perm_media_outlined,
                ),
                _menuItem(
                  'settings',
                  'Project Settings',
                  Icons.settings_outlined,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildBody(currentServer, activeView),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Semantics(
        identifier: 'project_menu_$value',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ServerModel server, ProjectView activeView) {
    switch (activeView) {
      case ProjectView.chat:
        return ServerChatTab(
          key: ValueKey('project_chat_${server.id}'),
          server: server,
          projectCollectionId: _collectionId,
        );
      case ProjectView.files:
        return ServerFilesTab(
          key: ValueKey('project_files_${server.id}'),
          server: server,
        );
      case ProjectView.goals:
        return ServerGoalsTab(
          key: ValueKey('project_goals_${server.id}'),
          server: server,
        );
      case ProjectView.finances:
        return ServerFinanceTab(
          key: ValueKey('project_finance_${server.id}'),
          server: server,
        );
    }
  }
}
