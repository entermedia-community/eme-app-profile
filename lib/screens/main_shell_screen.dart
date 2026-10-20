import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_bar_overflow_menu.dart';
import '../widgets/app_drawer.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/notifications/notifications_sheet.dart';
import '../widgets/profile_app_bar_button.dart';
import '../services/deep_link_handler.dart';
import 'chats/chats_screen.dart';
import 'eme_world/eme_world_screen.dart';
import 'files/files_screen.dart';
import 'profile/profile_screen.dart';
import 'server/server_picker_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinkHandler.instance.checkPendingDeepLink(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(navigationProvider);


    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 26),
            tooltip: 'Open Navigation Drawer',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: SvgPicture.asset('assets/icon/logo.svg', height: 22),
        actions: [
          // Notification Bell
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24),
                tooltip: 'Notifications',
                onPressed: () {
                  NotificationsSheet.show(context);
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
          const ProfileAppBarButton(),
          const AppBarOverflowMenu(),
        ],
      ),
      drawer: const AppDrawer(),
      body: IndexedStack(
        index: currentTab,
        children: const [
          ChatsScreen(),
          FilesScreen(),
          EmeWorldScreen(),
          ProfileScreen(),
        ],
      ),
      floatingActionButton: currentTab == NavTab.profile.index
          ? ElevatedButton.icon(
              onPressed: () => _openServerPicker(context),
              icon: const Icon(Icons.add, size: 22),
              label: const Text('Browse'),
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
