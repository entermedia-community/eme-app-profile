import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ModuleNavItem {
  final String key;
  final String title;
  final IconData icon;
  final IconData activeIcon;

  const ModuleNavItem({
    required this.key,
    required this.title,
    required this.icon,
    required this.activeIcon,
  });
}

/// Bottom tab bar shared by the server and project screens.
class ModuleBottomNav extends StatelessWidget {
  final List<ModuleNavItem> items;
  final String activeKey;
  final Color color;
  final ValueChanged<String> onSelect;

  /// Prefix for the Semantics identifiers: `<idPrefix>_<item key>`.
  final String idPrefix;

  const ModuleBottomNav({
    super.key,
    required this.items,
    required this.activeKey,
    required this.color,
    required this.onSelect,
    required this.idPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark
        ? AppColors.textDarkMuted
        : AppColors.textMuted;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.lightCardBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final item in items)
                _buildItem(item, isDark: isDark, inactiveColor: inactiveColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(
    ModuleNavItem item, {
    required bool isDark,
    required Color inactiveColor,
  }) {
    final isSelected = item.key == activeKey;

    return Expanded(
      child: Semantics(
        identifier: '${idPrefix}_${item.key}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelect(item.key),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: isDark ? 0.22 : 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      size: 22,
                      color: isSelected ? color : inactiveColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? color : inactiveColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
