import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import 'settings_dialog.dart';

enum _MenuAction { settings, toggleTheme, logout }

/// Three-dot app bar menu: Settings, theme toggle switch and Log out.
class AppBarOverflowMenu extends ConsumerWidget {
  const AppBarOverflowMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;

    return Semantics(
      identifier: 'app_bar_overflow_menu',
      child: PopupMenuButton<_MenuAction>(
        icon: const Icon(Icons.more_vert_rounded),
        tooltip: 'More options',
        position: PopupMenuPosition.under,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onSelected: (action) => _onSelected(context, ref, action),
        itemBuilder: (context) => [
          _item(_MenuAction.settings, Icons.settings_rounded, 'Settings'),
          PopupMenuDivider(
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.lightCardBorder,
          ),
          _themeSwitchItem(ref: ref, isDark: isDark),
          if (isAuthenticated) ...[
            PopupMenuDivider(
              color: isDark
                  ? AppColors.darkCardBorder
                  : AppColors.lightCardBorder,
            ),
            _item(
              _MenuAction.logout,
              Icons.logout_rounded,
              'Log out',
              color: const Color(0xFFDC2626),
            ),
          ],
        ],
      ),
    );
  }

  PopupMenuItem<_MenuAction> _item(
    _MenuAction value,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: value,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 20, color: color),
        title: Text(label, style: TextStyle(color: color)),
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
      case _MenuAction.settings:
        await SettingsDialog.show(context);
      case _MenuAction.toggleTheme:
        ref.read(themeModeProvider.notifier).toggleTheme();
      case _MenuAction.logout:
        await ref.read(authProvider.notifier).logout();
    }
  }
}
