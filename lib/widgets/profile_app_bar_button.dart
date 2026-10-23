import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import 'notifications/notifications_sheet.dart';
import '../screens/settings/settings_screen.dart';

enum _MenuAction { profile, notifications, settings, toggleTheme, logout }

/// "EME" followed by the user's first name, e.g. "EME Christopher".
String emeProfileLabel(EmUser? user, ProfileModel profile) {
  final first = user?.firstname?.trim();
  if (first != null && first.isNotEmpty) return 'EME $first';
  final name = (user?.displayName ?? profile.name).trim();
  return name.isEmpty ? 'EME' : 'EME ${name.split(' ').first}';
}

/// App bar pill showing "EME" plus the user's first name, with a round portrait.
/// Tapping it opens a menu: My profile, Notifications, Settings, theme toggle
/// and Log out.
class ProfileAppBarButton extends ConsumerWidget {
  const ProfileAppBarButton({super.key});

  static const double _avatarSize = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider);
    final currentUser = ref.watch(authProvider).user;

    final initials =
        currentUser?.avatarInitials ??
        (profile.name.isNotEmpty ? profile.name.substring(0, 1) : 'E');
    final portraitUrl = currentUser != null
        ? currentUser.assetportrait
        : profile.avatarUrl;

    final isAuthenticated = ref.watch(authProvider).isAuthenticated;
    final dividerColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    return Semantics(
      identifier: 'app_bar_profile_button',
      button: true,
      label: 'Open EME menu',
      child: PopupMenuButton<_MenuAction>(
        tooltip: 'Menu',
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: EdgeInsets.zero,
        onSelected: (action) => _onSelected(context, ref, action),
        itemBuilder: (context) => [
          _item(
            _MenuAction.profile,
            'app_bar_menu_profile',
            Icons.person_rounded,
            'My profile',
          ),
          _item(
            _MenuAction.notifications,
            'app_bar_menu_notifications',
            Icons.notifications_rounded,
            'Notifications',
          ),
          PopupMenuDivider(color: dividerColor),
          _item(
            _MenuAction.settings,
            'app_bar_menu_settings',
            Icons.settings_rounded,
            'Settings',
          ),
          _themeSwitchItem(ref: ref, isDark: isDark),
          if (isAuthenticated) ...[
            PopupMenuDivider(color: dividerColor),
            _item(
              _MenuAction.logout,
              'app_bar_menu_logout',
              Icons.logout_rounded,
              'Log out',
              color: const Color(0xFFDC2626),
            ),
          ],
        ],
        child: Material(
          color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAvatar(portraitUrl, initials, isDark),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    emeProfileLabel(currentUser, profile),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textDarkPrimary
                          : AppColors.textPrimary,
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

  PopupMenuItem<_MenuAction> _item(
    _MenuAction value,
    String id,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: Semantics(
        identifier: id,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, size: 20, color: color),
          title: Text(label, style: TextStyle(color: color)),
        ),
      ),
    );
  }

  PopupMenuItem<_MenuAction> _themeSwitchItem({
    required WidgetRef ref,
    required bool isDark,
  }) {
    return PopupMenuItem(
      value: _MenuAction.toggleTheme,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          size: 20,
          color: isDark ? const Color(0xFFFBBF24) : null,
        ),
        title: Text(isDark ? 'Dark mode' : 'Light mode'),
        trailing: Semantics(
          identifier: 'overflow_theme_switch',
          child: Switch(
            value: isDark,
            activeThumbColor: AppColors.primary,
            onChanged: (value) {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
              Navigator.of(ref.context).pop();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _onSelected(
    BuildContext context,
    WidgetRef ref,
    _MenuAction action,
  ) async {
    switch (action) {
      case _MenuAction.profile:
        ref.read(navigationProvider.notifier).selectTab(NavTab.profile);
      case _MenuAction.notifications:
        await NotificationsSheet.show(context);
      case _MenuAction.settings:
        await SettingsScreen.open(context);
      case _MenuAction.toggleTheme:
        ref.read(themeModeProvider.notifier).toggleTheme();
      case _MenuAction.logout:
        await ref.read(authProvider.notifier).logout();
    }
  }

  Widget _buildAvatar(String? url, String initials, bool isDark) {
    final fallback = Center(
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );

    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                width: _avatarSize,
                height: _avatarSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              )
            : fallback,
      ),
    );
  }
}
