import 'package:flutter_riverpod/flutter_riverpod.dart';

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
