import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/server_model.dart';
import '../../../theme/app_colors.dart';

class ServerModuleDefinition {
  final String key;
  final String title;
  final IconData icon;
  final IconData activeIcon;

  const ServerModuleDefinition({
    required this.key,
    required this.title,
    required this.icon,
    required this.activeIcon,
  });
}

class ServerBottomNav extends StatelessWidget {
  final ServerModel server;
  final String activeModuleKey;
  final String primaryModuleKey;
  final ValueChanged<String> onSelectModule;

  const ServerBottomNav({
    super.key,
    required this.server,
    required this.activeModuleKey,
    required this.primaryModuleKey,
    required this.onSelectModule,
  });

  ServerModuleDefinition _getPrimaryModuleDef() {
    switch (primaryModuleKey) {
      case 'finance':
        return const ServerModuleDefinition(
          key: 'finance',
          title: 'Finance',
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet_rounded,
        );
      case 'goals':
        return const ServerModuleDefinition(
          key: 'goals',
          title: 'Goals',
          icon: Icons.track_changes_outlined,
          activeIcon: Icons.track_changes_rounded,
        );
      case 'products':
      default:
        return const ServerModuleDefinition(
          key: 'products',
          title: 'Products',
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
        );
    }
  }

  List<ServerModuleDefinition> _getMoreModules() {
    final allModules = [
      const ServerModuleDefinition(
        key: 'goals',
        title: 'Goals & OKRs',
        icon: Icons.track_changes_outlined,
        activeIcon: Icons.track_changes_rounded,
      ),
      const ServerModuleDefinition(
        key: 'finance',
        title: 'DAO Finance',
        icon: Icons.account_balance_wallet_outlined,
        activeIcon: Icons.account_balance_wallet_rounded,
      ),
      const ServerModuleDefinition(
        key: 'products',
        title: 'Products & Store',
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
      ),
      const ServerModuleDefinition(
        key: 'blog',
        title: 'Blog & Updates',
        icon: Icons.article_outlined,
        activeIcon: Icons.article_rounded,
      ),
      const ServerModuleDefinition(
        key: 'files',
        title: 'Files & Drive',
        icon: Icons.folder_open_rounded,
        activeIcon: Icons.folder_rounded,
      ),
    ];

    // Exclude overview, chat, and the current primary module from the More menu
    return allModules.where((m) => m.key != primaryModuleKey).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryDef = _getPrimaryModuleDef();
    final moreModules = _getMoreModules();

    final isMoreSelected = moreModules.any((m) => m.key == activeModuleKey);
    final selectedMoreItem = isMoreSelected
        ? moreModules.firstWhere((m) => m.key == activeModuleKey)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
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
              // 1. Overview Tab
              _buildNavItem(
                context,
                title: 'Overview',
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                isSelected: activeModuleKey == 'overview',
                onTap: () => onSelectModule('overview'),
                isDark: isDark,
              ),

              // 2. Chat Tab (Server Specific)
              _buildNavItem(
                context,
                title: 'Chat',
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                isSelected: activeModuleKey == 'chat',
                onTap: () => onSelectModule('chat'),
                isDark: isDark,
              ),

              // 3. Primary Feature Tab (e.g. Products / Finance / Goals)
              _buildNavItem(
                context,
                title: primaryDef.title,
                icon: primaryDef.icon,
                activeIcon: primaryDef.activeIcon,
                isSelected: activeModuleKey == primaryDef.key,
                onTap: () => onSelectModule(primaryDef.key),
                isDark: isDark,
              ),

              // 4. More Popup Menu Button
              _buildMorePopupMenu(
                context,
                isDark: isDark,
                isMoreSelected: isMoreSelected,
                selectedMoreItem: selectedMoreItem,
                moreModules: moreModules,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final activeColor = server.primaryColor;
    final inactiveColor = isDark ? AppColors.textDarkMuted : AppColors.textMuted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    size: 22,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMorePopupMenu(
    BuildContext context, {
    required bool isDark,
    required bool isMoreSelected,
    required ServerModuleDefinition? selectedMoreItem,
    required List<ServerModuleDefinition> moreModules,
  }) {
    final activeColor = server.primaryColor;
    final inactiveColor = isDark ? AppColors.textDarkMuted : AppColors.textMuted;

    return Expanded(
      child: PopupMenuButton<String>(
        tooltip: 'More Server Modules',
        position: PopupMenuPosition.over,
        offset: const Offset(0, -220),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        elevation: 12,
        onSelected: (moduleKey) {
          onSelectModule(moduleKey);
        },
        itemBuilder: (BuildContext ctx) {
          return moreModules.map((m) {
            final isItemActive = activeModuleKey == m.key;
            return PopupMenuItem<String>(
              value: m.key,
              height: 48,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isItemActive
                          ? activeColor.withValues(alpha: isDark ? 0.25 : 0.15)
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isItemActive ? m.activeIcon : m.icon,
                      size: 18,
                      color: isItemActive ? activeColor : (isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isItemActive ? FontWeight.w700 : FontWeight.w500,
                        color: isItemActive
                            ? activeColor
                            : (isDark ? AppColors.textDarkPrimary : AppColors.textPrimary),
                      ),
                    ),
                  ),
                  if (isItemActive)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: activeColor,
                    ),
                ],
              ),
            );
          }).toList();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isMoreSelected
                      ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isMoreSelected
                      ? (selectedMoreItem?.activeIcon ?? Icons.grid_view_rounded)
                      : Icons.more_horiz_rounded,
                  size: 22,
                  color: isMoreSelected ? activeColor : inactiveColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                isMoreSelected ? (selectedMoreItem?.title.split(' ').first ?? 'More') : 'More',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: isMoreSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isMoreSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
