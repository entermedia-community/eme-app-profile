import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/auth/auth_gate.dart';
import '../screens/chats/chat_detail_screen.dart';
import '../screens/server/server_detail_screen.dart';
import '../screens/server/server_loader_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Route paths. Build locations with these helpers so call sites never
/// hand-assemble URLs.
abstract final class AppRoutes {
  static const home = '/';
  static const chat = '/chat/:username';
  static const server = '/server/:serverId';

  static String chatPath(String username) =>
      '/chat/${Uri.encodeComponent(username)}';
  static String serverPath(String serverId) =>
      '/server/${Uri.encodeComponent(serverId)}';
}

/// Pass as `extra` when pushing [AppRoutes.chat] to skip resolving the chat.
/// [promptIdle] mirrors [ChatDetailScreen.promptIdle].
class ChatRouteExtra {
  const ChatRouteExtra(this.chat, {this.promptIdle = true});
  final ChatModel chat;
  final bool promptIdle;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Re-run redirects whenever the signed-in state flips.
  final refresh = ValueNotifier<bool>(ref.read(authProvider).isAuthenticated);
  ref.listen<AuthState>(authProvider, (_, next) {
    refresh.value = next.isAuthenticated;
  });
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      // AuthGate renders the sign-in flow at '/', so every other route
      // requires a session and falls back there.
      final signedIn = ref.read(authProvider).isAuthenticated;
      if (!signedIn && state.matchedLocation != AppRoutes.home) {
        return AppRoutes.home;
      }
      return null;
    },
    onException: (context, state, router) => router.go(AppRoutes.home),
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is ChatRouteExtra) {
            return ChatDetailScreen(
              chat: extra.chat,
              promptIdle: extra.promptIdle,
            );
          }
          final username = state.pathParameters['username']!;
          return ChatDetailScreen(
            chat: ChatModel(
              username: username,
              displayName: username,
              lastMessage: '',
              time: '',
              avatarColor: const Color(0xFF0284C7),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.server,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is ServerModel) return ServerDetailScreen(server: extra);
          return ServerLoaderScreen(
            serverId: state.pathParameters['serverId']!,
          );
        },
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
