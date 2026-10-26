---
name: eme-app-overview
description: Architecture map of the EME Collective Intelligence chat app (Flutter package eme_world, repo eme-app-profile) — a WhatsApp-style app for chatting with other users and with EME Servers picked from a list. Use before making UI/feature changes, or when the user asks where a screen lives, how navigation works, how user chat vs server chat vs MCP chat are wired, or how to run, reload or build the app.
---

# EME Collective Intelligence app — Overview

A Flutter chat app loosely modelled on WhatsApp. Users can:
- chat 1:1 with other users (DMs), and with themselves ("EME <first name>"),
- find people and **EME Servers** in one Search, join servers, and chat with a server (the server
  replies with text, rich Quill deltas, forms, assets, or products),
- add their own **MCP servers** and chat with or call tools on them.

**Before any UI change, read the `eme-app-ui` skill** — it holds the owner's UI preferences
(app bar layout, naming, no bottom nav/drawer, Search design) and reusable patterns.

Package name: `eme_world` (imports are `package:eme_world/...`). Everything non-UI — models,
REST, WebSocket, auth, providers — lives in the sibling SDK `../eme-app-sdk`
(`import 'package:eme_app_sdk/eme_app_sdk.dart';`). Changing data or protocol usually means changing
the SDK first. See the `eme-sdk-overview` skill there.

## Startup (`lib/main.dart`)

`DioUtil.init()` → `OpenI().initialize({mediadb, siteroot, catalogid})` →
`PushNotificationService` → `DeepLinkService` → `ProviderScope(EmeWorldApp)` →
`AuthGate` (shows `AuthScreen` until logged in, then `MainShellScreen`).

Backend URL: release builds use `https://eme.world`, debug builds use `http://localhost:8080`.
Override with `--dart-define=SITEROOT=...` (and optionally `MEDIADB=...`).

## Layout

| Path | Purpose |
|---|---|
| `lib/screens/main_shell_screen.dart` | Scaffold + AppBar (logo, bell, profile button, three-dot menu) + `IndexedStack` of Chats / Profile. **No drawer, no bottom nav.** Back arrow on the profile page |
| `lib/providers/navigation_provider.dart` | `NavTab { chats, profile }` (Chats is home), `navigationProvider` (int index) |
| `lib/screens/chats/` | Home. WhatsApp-like list (`chats_screen.dart` uses `unifiedChatsProvider`: DMs + MCP servers + joined EME Servers; filters People / Servers / All), DM screen `chat_detail_screen.dart`, MCP chat `mcp_chat_detail_screen.dart`, `chat_info_screen.dart`, `widgets/` (QR connect, add MCP server, tool invocation) |
| `lib/screens/search/unified_search_screen.dart` | "EME Search": full-screen modal searching people **and** servers with shared category pills and one combined results list |
| `lib/screens/profile/` | The user's own "EME profile" page: `profile_header_card.dart` (pencil next to name), `self_chat_composer.dart` (message box to own chat), then Files; `edit_profile_sheet.dart`, `server_card.dart` (+ `joinAndOpen`), `add_server_sheet.dart` |
| `lib/screens/files/files_section.dart` | Files section shown on the profile page (still hardcoded sample data) |
| `lib/screens/eme_world/widgets/` | `eme_profile_card.dart` (person card + `showDetails` sheet with greeting composer), `greeting_draft.dart` (what two users have in common → draft greeting) |
| `lib/screens/server/` | `server_detail_screen.dart` (tabbed server view), `server_chat_screen.dart`, `tabs/` (chat, products, goals, finance, blog, files, overview), `widgets/server_bottom_nav.dart` |
| `lib/screens/auth/` | `AuthGate`, `AuthScreen`. OTP widgets are in `lib/widgets/auth/` |
| `lib/widgets/` | Shared: `profile_app_bar_button.dart` (+ `emeProfileLabel`), `app_bar_overflow_menu.dart`, `settings_dialog.dart`, `pill_badge`, `delta_viewer` (Quill read-only), `chat/` (product card/sheet/modal), `notifications/` |
| `lib/services/deep_link_handler.dart` | Opens a DM from `emeworld://chat/<user>` or a push-notification tap, using `rootNavigatorKey` |
| `lib/theme/` | `AppColors` (constants), `AppTheme.lightTheme/darkTheme`. `themeModeProvider` is in `lib/providers/theme_provider.dart` |

## The three chat paths

| | Screen | Transport |
|---|---|---|
| User ↔ user (incl. self chat) | `screens/chats/chat_detail_screen.dart` | `ChatSocketService.connectUser` → `connect` → `messageStream` / `sendMessage`; history `fetchUserChatMessages`. Self chat = `connectUser(me, me)` |
| User ↔ EME Server | `screens/server/tabs/server_chat_tab.dart` (hosted by `server_detail_screen` / `server_chat_screen`), opened from the chat list or Search | `connectChat(serverId)` → `connect(baseUrl: server.serverMediaDBUrl)`; history `fetchServerChatMessages`; form submit via `connectChat(..., params:)`. Joined servers come from `userServersProvider` (`fetchUserServers`) |
| User ↔ MCP server | `screens/chats/mcp_chat_detail_screen.dart` | `mcpConversationsProvider` / `McpClientService` |

DM and server chat each have their **own** `_buildMessageContent` switch over `MessageRenderType`.
Keep them in step. See the `eme-app-chat-ui` skill.

## Conventions

- State: Riverpod 2 (`ConsumerWidget` / `ConsumerStatefulWidget`, `ref.watch` for providers,
  `.when(data:, loading:, error:)` for `AsyncValue`). Data always comes through SDK providers so
  tests can override `apiServiceProvider` / `authServiceProvider`.
- Theming: read `isDark` from `ref.watch(themeModeProvider) == ThemeMode.dark` or
  `Theme.of(context).brightness`. Use `AppColors.*` instead of raw hex. Fonts via `google_fonts`.
- Navigation: `Navigator.push(MaterialPageRoute(...))` for detail screens (`fullscreenDialog: true`
  for full-screen modals like Search), `ref.read(navigationProvider.notifier).selectTab(NavTab.chats)`
  to switch between Chats and Profile, `showModalBottomSheet` for sheets (the app uses many).
- Maestro hooks: every button/input/chip/tappable row you add or touch gets
  `Semantics(identifier: 'snake_case_id', ...)` (AGENTS.md). The id list is in `eme-app-ui`. Don't
  rename existing identifiers without updating tests and `.maestro/*.yaml`.
- No mock/fallback data in `lib/` (AGENTS.md). Show the real loading, error and empty states.
- Strings are currently hardcoded English. The `flutter-arb-localization-extractor` skill covers moving them to ARB files.

## Commands

```bash
flutter pub get
flutter run -d chrome                                   # dev backend at localhost:8080
flutter run -d chrome --dart-define=SITEROOT=https://eme.world
flutter analyze
flutter test          # test/form_select_widget_test.dart is a known pre-existing failure
dart format <files you changed>   # never `dart format lib`: it rewrites unrelated files
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

Related skills: `eme-app-ui` (UI preferences + patterns + test gotchas), `eme-app-chat-ui`,
`eme-sdk-overview`.
