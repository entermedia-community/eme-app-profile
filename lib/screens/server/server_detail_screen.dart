import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import 'tabs/server_chat_tab.dart';

// TODO(server-tabs): Overview and Products tabs are removed; everything
// happens through the chat.
// import 'tabs/server_overview_tab.dart';
// import 'tabs/server_products_tab.dart';

class ServerDetailScreen extends ConsumerStatefulWidget {
  final ServerModel server;

  const ServerDetailScreen({super.key, required this.server});

  /// Custom route animation for server transition
  static Route<void> route(ServerModel server) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ServerDetailScreen(server: server),
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
  ConsumerState<ServerDetailScreen> createState() => _ServerDetailScreenState();
}

class _ServerDetailScreenState extends ConsumerState<ServerDetailScreen> {
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
              width: 34,
              height: 34,
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
                            fontSize: 12,
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
                          fontSize: 12,
                          color: currentServer.primaryColor,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentServer.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
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
                      Text(
                        '${currentServer.memberCount} members • ${currentServer.categoryLabel}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textMuted,
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
          // Server Options Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 22),
            tooltip: 'Server Options',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (value) async {
              if (value == 'join') {
                final wasJoined = currentServer.isJoined;
                final success = await ref
                    .read(serverProvider.notifier)
                    .toggleJoin(currentServer.id);
                if (!context.mounted) return;
                if (success) {
                  ref.invalidate(userServersProvider);
                  if (wasJoined) {
                    ref
                        .read(navigationProvider.notifier)
                        .selectTab(NavTab.chats);
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Left ${currentServer.name}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Joined ${currentServer.name}'),
                        backgroundColor: AppColors.greenAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else {
                  final error =
                      ref.read(serverProvider).error ??
                      (wasJoined
                          ? 'Failed to leave server'
                          : 'Failed to join server');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error),
                      backgroundColor: AppColors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (value == 'share') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Server invite link copied: https://eme.world/s/${currentServer.id}',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else if (value == 'qr') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Server QR Code generated'),
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
                      color: currentServer.isJoined
                          ? const Color(0xFFEF4444)
                          : AppColors.greenAccent,
                    ),
                    const SizedBox(width: 10),
                    Text(currentServer.isJoined ? 'Leave Server' : 'Join'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Share Server Link'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'qr',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Server QR Code'),
                  ],
                ),
              ),
            ],
          ),
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
