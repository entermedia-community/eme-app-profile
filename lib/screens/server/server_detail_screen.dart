import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/server_model.dart';
import '../../providers/server_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import 'tabs/server_blog_tab.dart';
import 'tabs/server_chat_tab.dart';
import 'tabs/server_files_tab.dart';
import 'tabs/server_goals_tab.dart';
import 'tabs/server_finance_tab.dart';
import 'tabs/server_overview_tab.dart';
import 'tabs/server_products_tab.dart';
import 'widgets/server_bottom_nav.dart';

class ServerDetailScreen extends ConsumerStatefulWidget {
  final ServerModel server;
  final String initialModuleKey;

  const ServerDetailScreen({
    super.key,
    required this.server,
    this.initialModuleKey = 'overview',
  });

  /// Custom route animation for server transition
  static Route<void> route(ServerModel server, {String initialModuleKey = 'overview'}) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => ServerDetailScreen(
        server: server,
        initialModuleKey: initialModuleKey,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  @override
  ConsumerState<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends ConsumerState<ServerDetailScreen> {
  late String _activeModuleKey;

  @override
  void initState() {
    super.initState();
    _activeModuleKey = widget.initialModuleKey;
  }

  String _getPrimaryModuleKey(ServerModel server) {
    final cat = server.category.toLowerCase();
    if (cat.contains('finance')) {
      return 'finance';
    } else if (cat.contains('social') || cat.contains('software')) {
      return 'goals';
    } else {
      return 'products';
    }
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Find the latest updated instance of this server if available
    final currentServer = serverState.servers.firstWhere(
      (s) => s.id == widget.server.id,
      orElse: () => widget.server,
    );

    final primaryModuleKey = _getPrimaryModuleKey(currentServer);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: currentServer.primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: currentServer.primaryColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                currentServer.iconData,
                size: 18,
                color: currentServer.primaryColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentServer.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.greenAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${currentServer.memberCount} members • ${currentServer.category}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: isDark ? const Color(0xFFFBBF24) : AppColors.textSecondary,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          // Server Options Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            tooltip: 'Server Options',
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (value) {
              if (value == 'join') {
                ref.read(serverProvider.notifier).toggleJoin(currentServer.id);
              } else if (value == 'share') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Server invite link copied: https://eme.world/s/${currentServer.id}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (value == 'qr') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Node QR Code generated'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'join',
                child: Row(
                  children: [
                    Icon(
                      currentServer.isJoined
                          ? Icons.remove_circle_outline_rounded
                          : Icons.add_circle_outline_rounded,
                      size: 18,
                      color: currentServer.isJoined ? const Color(0xFFEF4444) : AppColors.greenAccent,
                    ),
                    const SizedBox(width: 10),
                    Text(currentServer.isJoined ? 'Leave Node' : 'Join Node'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Share Node Link'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Node QR Code'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildCurrentModule(currentServer),
      ),
      bottomNavigationBar: ServerBottomNav(
        server: currentServer,
        activeModuleKey: _activeModuleKey,
        primaryModuleKey: primaryModuleKey,
        onSelectModule: (moduleKey) {
          setState(() {
            _activeModuleKey = moduleKey;
          });
        },
      ),
    );
  }

  Widget _buildCurrentModule(ServerModel server) {
    switch (_activeModuleKey) {
      case 'chat':
        return ServerChatTab(
          key: ValueKey('chat_${server.id}'),
          server: server,
        );
      case 'products':
        return ServerProductsTab(
          key: ValueKey('products_${server.id}'),
          server: server,
        );
      case 'goals':
        return ServerGoalsTab(
          key: ValueKey('goals_${server.id}'),
          server: server,
        );
      case 'finance':
        return ServerFinanceTab(
          key: ValueKey('finance_${server.id}'),
          server: server,
        );
      case 'blog':
        return ServerBlogTab(
          key: ValueKey('blog_${server.id}'),
          server: server,
        );
      case 'files':
        return ServerFilesTab(
          key: ValueKey('files_${server.id}'),
          server: server,
        );
      case 'overview':
      default:
        return ServerOverviewTab(
          key: ValueKey('overview_${server.id}'),
          server: server,
          onNavigateToModule: (moduleKey) {
            setState(() {
              _activeModuleKey = moduleKey;
            });
          },
        );
    }
  }
}
