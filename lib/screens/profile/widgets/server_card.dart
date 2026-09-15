import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/server_model.dart';
import '../../../theme/app_colors.dart';
import '../../server/server_detail_screen.dart';

class ServerCard extends ConsumerWidget {
  final ServerModel server;

  const ServerCard({super.key, required this.server});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = server.statusColor ?? const Color(0xFF10B981);
    final notificationText =
        server.lastNotification ?? 'All systems operational and synced';
    final timeText = server.lastNotificationTime ?? 'Live';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openServerScreen(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Avatar Icon + Status / Alert Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar Icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: server.primaryColor.withValues(
                          alpha: isDark ? 0.22 : 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: server.primaryColor.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          server.iconData,
                          size: 22,
                          color: isDark
                              ? server.primaryColor.withValues(alpha: 0.95)
                              : server.primaryColor,
                        ),
                      ),
                    ),

                    // Status Indicator Pill (Personalized, only on joined servers)
                    if (server.isJoined && server.status != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(
                            alpha: isDark ? 0.2 : 0.1,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              server.status!,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 10),

                // Server Name
                Text(
                  server.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 10),

                // Info Section (Personalized status for joined servers, description for others)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF131D31)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkCardBorder.withValues(alpha: 0.7)
                            : AppColors.lightCardBorder.withValues(alpha: 0.9),
                        width: 1,
                      ),
                    ),
                    child: server.isJoined
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.notifications_active_outlined,
                                    size: 11.5,
                                    color: statusColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'LATEST STATUS',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                        color: isDark
                                            ? AppColors.textDarkMuted
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    timeText,
                                    style: GoogleFonts.inter(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textDarkMuted
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notificationText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : const Color(0xFF475569),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.public_rounded,
                                    size: 11.5,
                                    color: isDark
                                        ? AppColors.textDarkMuted
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      server.category.toUpperCase(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                        color: isDark
                                            ? AppColors.textDarkMuted
                                            : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${server.memberCount} members',
                                    style: GoogleFonts.inter(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textDarkMuted
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                server.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : const Color(0xFF475569),
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openServerScreen(BuildContext context) {
    Navigator.of(context).push(ServerDetailScreen.route(server));
  }
}
