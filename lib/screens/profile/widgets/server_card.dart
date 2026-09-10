import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/server_model.dart';
import '../../../providers/server_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/pill_badge.dart';

class ServerCard extends ConsumerWidget {
  final ServerModel server;

  const ServerCard({super.key, required this.server});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showServerDetails(context, ref),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Visual Brand / Banner Header
              _buildCardBanner(context, isDark),

              // Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            server.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                              height: 1.2,
                            ),
                          ),

                          if (server.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              server.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : const Color(0xFF64748B),
                                height: 1.3,
                              ),
                            ),
                          ],

                          const SizedBox(height: 8),

                          // Tags
                          if (server.tags.isNotEmpty)
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: server.tags.take(2).map<Widget>((tag) {
                                return PillBadge.forCategory(
                                  tag,
                                  isDark: isDark,
                                  fontSize: 9.5,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2.5,
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),

                      // Bottom info & Action
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Members Count
                            Row(
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 13,
                                  color: isDark
                                      ? AppColors.textDarkMuted
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${server.memberCount}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textDarkMuted
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),

                            // Join / Open Button
                            InkWell(
                              onTap: () {
                                ref.read(serverProvider.notifier).toggleJoin(server.id);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: server.isJoined
                                      ? (isDark
                                          ? const Color(0xFF064E3B)
                                          : const Color(0xFFDCFCE7))
                                      : AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: server.isJoined
                                        ? (isDark
                                            ? const Color(0xFF059669)
                                            : const Color(0xFF86EFAC))
                                        : AppColors.primary.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      server.isJoined
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.add_circle_outline_rounded,
                                      size: 12,
                                      color: server.isJoined
                                          ? (isDark
                                              ? const Color(0xFF86EFAC)
                                              : const Color(0xFF166534))
                                          : (isDark
                                              ? AppColors.primaryLight
                                              : AppColors.primary),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      server.isJoined ? 'Joined' : 'Join',
                                      style: GoogleFonts.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: server.isJoined
                                            ? (isDark
                                                ? const Color(0xFF86EFAC)
                                                : const Color(0xFF166534))
                                            : (isDark
                                                ? AppColors.primaryLight
                                                : AppColors.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildCardBanner(BuildContext context, bool isDark) {
    if (server.bannerSvgOrType == 'gear_eco') {
      return Container(
        height: 105,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              right: -15,
              bottom: -15,
              child: Icon(
                Icons.settings_rounded,
                size: 80,
                color: (isDark ? Colors.white : const Color(0xFF059669))
                    .withValues(alpha: 0.06),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF022C22) : Colors.white,
                    border: Border.all(
                      color: const Color(0xFF059669),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.energy_savings_leaf_rounded,
                    size: 24,
                    color: Color(0xFF059669),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    server.subtitle?.toUpperCase() ?? 'STARTUPS FOR SOCIAL IMPACT',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (server.bannerSvgOrType == 'impact_bank') {
      return Container(
        height: 105,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF082F49) : const Color(0xFFF0F9FF),
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF0284C7), width: 2),
                    ),
                  ),
                  Container(width: 6, height: 2, color: const Color(0xFF0284C7)),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFF59E0B), width: 2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'IMPACT',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: const Color(0xFF0284C7),
                ),
              ),
              Text(
                'BANK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (server.bannerSvgOrType == 'infinity_loop') {
      return Container(
        height: 105,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            ),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.all_inclusive_rounded,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Punaryoji',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Vikas Services',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // Default stylized header
    return Container(
      height: 105,
      decoration: BoxDecoration(
        color: server.primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border.all(
                  color: server.primaryColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(
                server.iconData,
                size: 24,
                color: server.primaryColor,
              ),
            ),
            if (server.subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  server.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: server.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showServerDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      server.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (server.subtitle != null) ...[
                Text(
                  server.subtitle!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: server.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              if (server.location != null || server.servicePricing != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (server.location != null)
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            server.location!,
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    if (server.servicePricing != null)
                      Text(
                        server.servicePricing!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Text(
                server.description,
                style: GoogleFonts.inter(fontSize: 14, height: 1.5),
              ),
              if (server.servicesOffered.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Services & Capabilities:',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: server.servicesOffered.map((srv) {
                    return PillBadge(
                      label: srv,
                      backgroundColor: server.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                      textColor: isDark ? server.secondaryColor : server.primaryColor,
                      fontSize: 11.5,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Tags:',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: server.tags.map((tag) {
                  return PillBadge.forCategory(tag, isDark: isDark);
                }).toList(),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(serverProvider.notifier).toggleJoin(server.id);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: server.isJoined
                            ? const Color(0xFFEF4444)
                            : AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        server.isJoined ? 'Leave Server' : 'Join Server',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
