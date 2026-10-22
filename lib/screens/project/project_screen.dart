import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../server/tabs/server_chat_tab.dart';
import '../server/tabs/server_finance_tab.dart';
import '../server/tabs/server_goals_tab.dart';
import 'tabs/project_settings_tab.dart';

/// Available views for [ProjectScreen].
enum ProjectView {
  chat('Chat', Icons.chat_bubble_outline_rounded),
  goals('Goals', Icons.flag_outlined),
  finances('Finances', Icons.account_balance_wallet_outlined),
  settings('Settings', Icons.settings_outlined);

  final String label;
  final IconData icon;

  const ProjectView(this.label, this.icon);
}

/// Project screen with multi-participant chat as default view and a top dropdown
/// to switch between Chat, Goals, Finances, and Settings.
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

  static ServerModel _serverFromCollection(LibraryCollectionModel collection) {
    return ServerModel(
      id: collection.id,
      name: collection.name.isNotEmpty ? collection.name : 'Project',
      description: collection.displayDescription,
      category: ServerCategoryModel(
        id: collection.collectionType ?? 'project',
        name: collection.collectionType ?? 'Project',
      ),
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

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final serverState = ref.watch(serverProvider);

    final currentServer = serverState.servers.firstWhere(
      (s) => s.id == widget.server.id,
      orElse: () => widget.server,
    );

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
                  _buildViewDropdown(isDark),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          Semantics(
            identifier: 'project_theme_toggle',
            child: IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20,
                color: isDark
                    ? const Color(0xFFFBBF24)
                    : AppColors.textSecondary,
              ),
              tooltip: isDark ? 'Light Mode' : 'Dark Mode',
              onPressed: () {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _buildBody(currentServer),
      ),
    );
  }

  Widget _buildViewDropdown(bool isDark) {
    return Semantics(
      identifier: 'project_view_dropdown',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProjectView>(
          value: _activeView,
          isDense: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: isDark
                ? AppColors.textDarkSecondary
                : AppColors.textSecondary,
          ),
          dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: widget.server.primaryColor,
          ),
          items: ProjectView.values.map((view) {
            return DropdownMenuItem<ProjectView>(
              key: ValueKey('project_view_item_${view.name}'),
              value: view,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    view.icon,
                    size: 14,
                    color: _activeView == view
                        ? widget.server.primaryColor
                        : (isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textSecondary),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    view.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: _activeView == view
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _activeView == view
                          ? widget.server.primaryColor
                          : (isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (newView) {
            if (newView != null && newView != _activeView) {
              setState(() {
                _activeView = newView;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildBody(ServerModel server) {
    switch (_activeView) {
      case ProjectView.chat:
        return ServerChatTab(
          key: ValueKey('project_chat_${server.id}'),
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
      case ProjectView.settings:
        return ProjectSettingsTab(
          key: ValueKey('project_settings_${server.id}'),
          server: server,
          collection: widget.collection,
        );
    }
  }
}
