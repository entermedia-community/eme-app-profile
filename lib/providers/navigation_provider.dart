import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/search/unified_search_screen.dart';

/// Top-level pages of the main shell. Chats is home; the EME profile is
/// opened from the app bar profile button.
enum NavTab {
  chats('Chats'),
  profile('EME');

  final String label;
  const NavTab(this.label);
}

class NavigationNotifier extends StateNotifier<int> {
  NavigationNotifier() : super(0);

  void setTab(int tabIndex) {
    if (tabIndex >= 0 && tabIndex < NavTab.values.length) {
      state = tabIndex;
    }
  }

  void selectTab(NavTab tab) {
    state = tab.index;
  }
}

final navigationProvider = StateNotifierProvider<NavigationNotifier, int>((
  ref,
) {
  return NavigationNotifier();
});

/// Bottom tabs of the Chats home page.
enum HomeTab {
  myEme('My EME', Icons.person_pin_rounded, 'my_eme'),
  servers('Servers', Icons.dns_rounded, 'servers'),
  projects('Projects', Icons.folder_special_rounded, 'projects'),
  people('People', Icons.people_alt_rounded, 'people');

  final String label;
  final IconData icon;
  final String id;
  const HomeTab(this.label, this.icon, this.id);

  /// What Search pre-selects when opened from this tab.
  SearchResultType get searchType {
    switch (this) {
      case HomeTab.myEme:
        return SearchResultType.all;
      case HomeTab.servers:
        return SearchResultType.servers;
      case HomeTab.projects:
        return SearchResultType.projects;
      case HomeTab.people:
        return SearchResultType.people;
    }
  }
}

final homeTabProvider = StateProvider<HomeTab>((ref) => HomeTab.myEme);
