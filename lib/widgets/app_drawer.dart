import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/navigation_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final currentTab = ref.watch(navigationProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      elevation: 1,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with User Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        profile.name.isNotEmpty ? profile.name.substring(0, 1) : 'C',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                profile.role,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '• Online',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.greenAccent,
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

            const SizedBox(height: 12),

            // Navigation Items as in Mockup
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    title: 'EME Profile',
                    icon: Icons.person_rounded,
                    isSelected: currentTab == 0,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(navigationProvider.notifier).setTab(0);
                    },
                  ),
                  _DrawerItem(
                    title: 'Chats',
                    icon: Icons.chat_bubble_rounded,
                    isSelected: currentTab == 1,
                    badgeCount: 3,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(navigationProvider.notifier).setTab(1);
                    },
                  ),
                  _DrawerItem(
                    title: 'EME World',
                    icon: Icons.public_rounded,
                    isSelected: currentTab == 3,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(navigationProvider.notifier).setTab(3);
                    },
                  ),
                  _DrawerItem(
                    title: 'Drive',
                    icon: Icons.folder_rounded,
                    isSelected: currentTab == 2,
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(navigationProvider.notifier).setTab(2);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _DrawerItem(
                    title: 'Settings',
                    icon: Icons.settings_rounded,
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showSettingsDialog(context, ref);
                    },
                  ),
                ],
              ),
            ),

            // Bottom theme toggle & version footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'EME World v1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: isDark ? const Color(0xFFFBBF24) : AppColors.textSecondary,
                    ),
                    tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
                    onPressed: () {
                      ref.read(themeModeProvider.notifier).toggleTheme();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Push Notifications'),
              trailing: Switch(value: true, onChanged: (v) {}),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.security_outlined),
              title: const Text('Privacy & Security'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language (English)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final int? badgeCount;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selected: isSelected,
        selectedTileColor: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
        leading: Icon(
          icon,
          color: isSelected
              ? (isDark ? AppColors.primaryLight : AppColors.primary)
              : (isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? (isDark ? AppColors.primaryLight : AppColors.primary)
                : (isDark ? AppColors.textDarkPrimary : AppColors.textPrimary),
          ),
        ),
        trailing: badgeCount != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badgeCount',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
