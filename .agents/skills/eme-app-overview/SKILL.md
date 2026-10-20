---
name: eme-app-overview
description: Architecture map of the EME Collective Intelligence chat app (Flutter package eme_world, repo eme-app-profile) — a WhatsApp-style app for chatting with other users and with EME Servers picked from a list. Use before making UI/feature changes, or when the user asks where a screen lives, how navigation works, how user chat vs server chat vs MCP chat are wired, or how to run, reload or build the app.
---

# EME Collective Intelligence app — Overview

A Flutter chat app loosely modelled on WhatsApp. Users can:
- chat 1:1 with other users (DMs),
- browse a list of **EME Servers**, join them, and chat with a server (the server replies with
  text, rich Quill deltas, forms, assets, or products),
- add their own **MCP servers** and chat with or call tools on them.

Package name: `eme_world` (imports are `package:eme_world/...`). Everything non-UI — models,
REST, WebSocket, auth, providers — lives in the sibling SDK `../eme-app-sdk`
(`import 'package:eme_app_sdk/eme_app_sdk.dart';`). Changing data or protocol usually means changing
the SDK first. See the `eme-sdk-overview` skill there.

## Startup (`lib/main.dart`)

`DioUtil.init()` → `OpenI().initialize({mediadb, siteroot, catalogid})` →
`PushNotificationService` → `DeepLinkService` → `ProviderScope(EmeWorldApp)` →
`AuthGate` (shows `AuthScreen` until logged in, then `MainShellScreen`).

Backend URL: release builds use `https://eme.world`, debug builds use `http://localhost.com:8080`.
Override with `--dart-define=SITEROOT=...` (and optionally `MEDIADB=...`).

## Layout

| Path | Purpose |
|---|---|
| `lib/screens/main_shell_screen.dart` | Scaffold + AppBar + drawer + bottom nav; switches tabs on `navigationProvider` |
| `lib/providers/navigation_provider.dart` | `NavTab { profile, chats, files, emeWorld }`, `navigationProvider` (int index) |
| `lib/screens/profile/` | Home "EME Profile" tab: header card, **joined servers** (`servers_section.dart`, `server_card.dart`), add server sheet |
| `lib/screens/chats/` | WhatsApp-like list (`chats_screen.dart` uses `unifiedChatsProvider`), DM screen `chat_detail_screen.dart`, MCP chat `mcp_chat_detail_screen.dart`, `chat_info_screen.dart`, `widgets/` (QR connect, add MCP server, tool invocation) |
| `lib/screens/server/` | `server_picker_screen.dart` (browse/search/categories/join), `server_detail_screen.dart` (tabbed server view), `server_chat_screen.dart`, `tabs/` (chat, products, goals, finance, blog, files, overview), `widgets/server_bottom_nav.dart` |
| `lib/screens/eme_world/` | Directory of people/specialists (`EmeProfileModel`) |
| `lib/screens/files/` | Files tab |
| `lib/screens/auth/` | `AuthGate`, `AuthScreen`. OTP widgets are in `lib/widgets/auth/` |
| `lib/widgets/` | Shared: `app_drawer`, `custom_bottom_nav`, `pill_badge`, `delta_viewer` (Quill read-only), `chat/` (product card/sheet/modal), `notifications/` |
| `lib/services/deep_link_handler.dart` | Opens a DM from `emeworld://chat/<user>` or a push-notification tap, using `rootNavigatorKey` |
| `lib/theme/` | `AppColors` (constants), `AppTheme.lightTheme/darkTheme`. `themeModeProvider` is in `lib/providers/theme_provider.dart` |

## The three chat paths

| | Screen | Transport |
|---|---|---|
| User ↔ user | `screens/chats/chat_detail_screen.dart` | `ChatSocketService.connectUser` → `connect` → `messageStream` / `sendMessage`; history `fetchUserChatMessages` |
| User ↔ EME Server | `screens/server/tabs/server_chat_tab.dart` (hosted by `server_detail_screen` / `server_chat_screen`) | `connectChat(serverId)` → `connect(baseUrl: server.serverMediaDBUrl)`; history `fetchServerChatMessages`; form submit via `connectChat(..., params:)` |
| User ↔ MCP server | `screens/chats/mcp_chat_detail_screen.dart` | `mcpConversationsProvider` / `McpClientService` |

DM and server chat each have their **own** `_buildMessageContent` switch over `MessageRenderType`.
Keep them in step. See the `eme-app-chat-ui` skill.

## Conventions

- State: Riverpod 2 (`ConsumerWidget` / `ConsumerStatefulWidget`, `ref.watch` for providers,
  `.when(data:, loading:, error:)` for `AsyncValue`). Data always comes through SDK providers so
  tests can override `apiServiceProvider` / `authServiceProvider`.
- Theming: read `isDark` from `ref.watch(themeModeProvider) == ThemeMode.dark` or
  `Theme.of(context).brightness`. Use `AppColors.*` instead of raw hex. Fonts via `google_fonts`.
- Navigation: `Navigator.push(MaterialPageRoute(...))` for detail screens,
  `ref.read(navigationProvider.notifier).selectTab(NavTab.chats)` for tabs, `showModalBottomSheet`
  for sheets (the app uses many).
- Maestro hooks: wrap tappable or targetable widgets in `Semantics(identifier: 'snake_case_id', ...)`
  (e.g. `joined_server_list`, `server_card_0`, `server_chat_input`, `server_chat_send`). Don't
  rename existing identifiers without updating `.maestro/*.yaml`.
- No mock/fallback data in `lib/` (AGENTS.md). Show the real loading, error and empty states.
- Strings are currently hardcoded English. The `flutter-arb-localization-extractor` skill covers moving them to ARB files.

## Commands

```bash
flutter pub get
flutter run -d chrome                                   # dev backend at localhost.com:8080
flutter run -d chrome --dart-define=SITEROOT=https://eme.world
flutter analyze
flutter test
./build_web.sh        # release wasm web build, base-href /site/app/, copied to BUILD_PATH from .env
maestro test .maestro/basic.yaml                         # on a device/emulator, appId world.eme.main
```

## Reloading the running app (Chrome)

Refreshing the browser tab alone does **not** pick up changes; it reloads the last compiled build.

- **Terminal (`flutter run -d chrome`)**: press `R` (capital) to hot restart. This picks up code and
  asset changes (e.g. a replaced `assets/icon/logo.svg`). Lowercase `r` (hot reload) keeps state and
  only works on web in newer Flutter versions, so prefer `R` after changing assets.
- **VS Code (F5)**: Ctrl+Shift+F5 or the green circular-arrow button on the debug toolbar (hot restart).
- **Still stale** (usually cached images): Ctrl+Shift+R in the Chrome tab. If that fails, stop the app
  (`q` in the terminal or Shift+F5 in VS Code) and run `flutter run -d chrome` again.

Related skills: `eme-app-add-feature`, `eme-app-chat-ui`, `eme-app-testing`.
