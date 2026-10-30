import 'package:eme_world/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../providers/navigation_provider.dart';
import '../widgets/profile_app_bar_button.dart';
import '../services/deep_link_handler.dart';
import '../widgets/search/unified_search_screen.dart';
import 'chats/chats_screen.dart';
import 'chats/my_eme_screen.dart';
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
    final homeTab = ref.watch(homeTabProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        title: SvgPicture.asset(
          isDark ? 'assets/icon/logo_dark.svg' : 'assets/icon/logo_light.svg',
          height: 26,
        ),
        actions: [
          Semantics(
            identifier: 'chats_open_search',
            child: IconButton(
              icon: const Icon(Icons.search_rounded, color: AppColors.primary),
              tooltip: 'EME Search',
              onPressed: () => UnifiedSearchScreen.show(
                context,
                initialType: ref.read(homeTabProvider).searchType,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const ProfileAppBarButton(),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(
        index: currentTab,
        children: [
          IndexedStack(
            index: homeTab.index,
            children: const [
              MyEmeScreen(),
              ChatsScreen(filter: ChatFilter.servers),
              ChatsScreen(filter: ChatFilter.projects),
              ChatsScreen(filter: ChatFilter.users),
            ],
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: onProfile
          ? null
          : NavigationBar(
              selectedIndex: homeTab.index,
              onDestinationSelected: (i) =>
                  ref.read(homeTabProvider.notifier).state = HomeTab.values[i],
              destinations: [
                for (final tab in HomeTab.values)
                  Semantics(
                    identifier: 'home_tab_${tab.id}',
                    child: NavigationDestination(
                      icon: Icon(tab.icon),
                      label: tab.label,
                    ),
                  ),
              ],
            ),
    );
  }
}
