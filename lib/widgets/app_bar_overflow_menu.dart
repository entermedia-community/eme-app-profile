import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import 'settings_dialog.dart';

enum _MenuAction { settings, lightTheme, darkTheme, logout }

/// Three-dot app bar menu: Settings, theme selector and Log out.
class AppBarOverflowMenu extends ConsumerWidget {
  const AppBarOverflowMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
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
          const PopupMenuDivider(),
          _themeItem(
            _MenuAction.lightTheme,
            Icons.light_mode_rounded,
            'Light theme',
            themeMode == ThemeMode.light,
          ),
          _themeItem(
            _MenuAction.darkTheme,
            Icons.dark_mode_rounded,
            'Dark theme',
            themeMode == ThemeMode.dark,
          ),
          if (isAuthenticated) ...[
            const PopupMenuDivider(),
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

  PopupMenuItem<_MenuAction> _themeItem(
    _MenuAction value,
    IconData icon,
    String label,
    bool selected,
  ) {
    return PopupMenuItem(
      value: value,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 20),
        title: Text(label),
        trailing: selected
            ? const Icon(
                Icons.check_rounded,
                size: 20,
                color: AppColors.primary,
              )
            : null,
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
      case _MenuAction.lightTheme:
        ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
      case _MenuAction.darkTheme:
        ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
      case _MenuAction.logout:
        await ref.read(authProvider.notifier).logout();
    }
  }
}
