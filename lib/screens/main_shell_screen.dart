import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_bottom_nav.dart';
import 'chats/chats_screen.dart';
import 'eme_world/eme_world_screen.dart';
import 'files/files_screen.dart';
import 'profile/profile_screen.dart';
import 'server/server_picker_screen.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(navigationProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    final titles = ['EME Profile', 'Chats', 'FIles', 'EME World'];

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 26),
            tooltip: 'Open Navigation Drawer',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.language_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              titles[currentTab],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 22,
              color: isDark ? const Color(0xFFFBBF24) : AppColors.textSecondary,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),
          // Notification Bell
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24),
                tooltip: 'Notifications',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No new notifications'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: currentTab,
        children: const [
          ProfileScreen(),
          ChatsScreen(),
          FilesScreen(),
          EmeWorldScreen(),
        ],
      ),
      floatingActionButton: currentTab == 0
          ? ElevatedButton.icon(
              onPressed: () => _openServerPicker(context),
              icon: const Icon(Icons.add, size: 22),
              label: const Text('Servers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenAccent,
                foregroundColor: Colors.white,
              ),
            )
          : null,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: currentTab,
        onTabSelected: (index) {
          ref.read(navigationProvider.notifier).setTab(index);
        },
      ),
    );
  }

  void _openServerPicker(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ServerPickerScreen()));
  }
}
