import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import 'server_detail_screen.dart';
import 'tabs/server_chat_tab.dart';

class ServerChatScreen extends ConsumerStatefulWidget {
  final ServerModel server;

  const ServerChatScreen({super.key, required this.server});

  /// Custom route animation for server transition
  static Route<void> route(ServerModel server) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ServerChatScreen(server: server),
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
  ConsumerState<ServerChatScreen> createState() => _ServerChatScreenState();
}

class _ServerChatScreenState extends ConsumerState<ServerChatScreen> {
  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Find latest server instance
    final currentServer = serverState.servers.firstWhere(
      (s) => s.id == widget.server.id,
      orElse: () => widget.server,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            Navigator.of(context).push(ServerDetailScreen.route(currentServer));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
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
                  child: Icon(
                    currentServer.iconData,
                    size: 18,
                    color: currentServer.primaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentServer.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textDarkPrimary
                              : AppColors.textPrimary,
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
                          Expanded(
                            child: Text(
                              '${currentServer.memberCount} members • ${currentServer.category.label}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textDarkMuted
                                    : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Top Nav Button to navigate directly to Server Details Screen
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.of(
                    context,
                  ).push(ServerDetailScreen.route(currentServer));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: currentServer.primaryColor.withValues(
                      alpha: isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentServer.primaryColor.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.terminal,
                        size: 15,
                        color: currentServer.primaryColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Console',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textDarkPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Server Options Menu

          const SizedBox(width: 4),
        ],
      ),
      body: ServerChatTab(
        key: ValueKey('chat_${currentServer.id}'),
        server: currentServer,
      ),
    );
  }
}
