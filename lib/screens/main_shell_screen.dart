import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_bar_overflow_menu.dart';
import '../widgets/notifications/notifications_sheet.dart';
import '../widgets/profile_app_bar_button.dart';
import '../services/deep_link_handler.dart';
import 'chats/chats_screen.dart';
import 'profile/profile_screen.dart';

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
    final onProfile = currentTab == NavTab.profile.index;

    return Scaffold(
      appBar: AppBar(
        // No drawer: Chats is home, the profile page gets a back arrow.
        automaticallyImplyLeading: false,
        leading: onProfile
            ? Semantics(
                identifier: 'app_bar_back_to_chats',
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back to Chats',
                  onPressed: () => ref
                      .read(navigationProvider.notifier)
                      .selectTab(NavTab.chats),
                ),
              )
            : null,
        title: SvgPicture.asset('assets/icon/logo.svg', height: 22),
        actions: [
          // Notification Bell
          Stack(
            alignment: Alignment.center,
            children: [
              Semantics(
                identifier: 'app_bar_notifications',
                child: IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 24),
                  tooltip: 'Notifications',
                  onPressed: () {
                    NotificationsSheet.show(context);
                  },
                ),
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
          const SizedBox(width: 8),
          const ProfileAppBarButton(),
          const SizedBox(width: 8),
          const AppBarOverflowMenu(),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: currentTab,
        children: const [ChatsScreen(), ProfileScreen()],
      ),
    );
  }
}
