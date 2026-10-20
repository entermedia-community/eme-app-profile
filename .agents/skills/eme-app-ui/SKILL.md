---
name: eme-app-ui
description: The product owner's UI preferences and the reusable UI building blocks of the EME Collective Intelligence app (eme_world) — app bar layout, navigation model (no bottom nav/drawer), "EME <first name>" naming, Search (combined people + servers), profile page, chat list filters, sizing/styling rules, Semantics ids, and widget-test gotchas. Use before any visual/UI change, new screen, button, filter, modal or layout tweak in eme-app-profile, so the result matches what the owner already asked for.
---

# Building UI in the EME app — preferences and patterns

Read `eme-app-overview` for the file map. This skill is about **how the owner wants UI to look
and behave**, learned from earlier requests. Follow these by default; ask only if a request
contradicts them.

## Owner's UI preferences

**Overall feel: minimal chrome, WhatsApp-like.**
- No bottom navigation bar and no side drawer. Don't add them back.
- **Chats is home.** The only other top-level page is the EME profile page (`NavTab.profile`),
  reached from the app bar profile button. It shows a back arrow to Chats.
- Prefer small icon affordances over big buttons: e.g. a **pencil icon next to the name** for
  editing, not an "Edit Profile" button. Remove redundant buttons when a newer control does the
  same job (the owner removed the green self-chat button once the message box existed).
- Let people act **inline**: a text area to send a message directly on a page is preferred over a
  button that navigates somewhere first.

**App bar (`lib/screens/main_shell_screen.dart`)** — keep this layout:
- Left: EME logo `SvgPicture.asset('assets/icon/logo.svg', height: 22)`, **no drop shadow**, no
  tab title text. (Back arrow appears before it on the profile page.)
- Right, in order: notification bell → `ProfileAppBarButton` ("EME Christopher" pill with round
  portrait → profile page) → `AppBarOverflowMenu` (three dots: Settings, Light/Dark theme with a
  check on the current one, Log out in red).
- Settings, theme and logout live **only** in the three-dot menu. Don't add standalone toggles.

**Naming**
- The signed-in user's own identity/chat is labelled **"EME <first name>"** (e.g. "EME Christopher").
  Always use `emeProfileLabel(user, profile)` from `lib/widgets/profile_app_bar_button.dart`,
  never a hard-coded name.
- "EME profile page" / "Profile page" = the user's own page (`ProfileScreen`).
- "Search" = `UnifiedSearchScreen`. Its entry button on Chats is labelled **"EME Search"** with the
  plain `Icons.search_rounded` icon.

**Chats page (`lib/screens/chats/chats_screen.dart`)**
- Top row: "Search conversations..." input + "EME Search" button. **The button height must match
  the input** (`IntrinsicHeight` + `CrossAxisAlignment.stretch`, button `minimumSize: Size.zero`,
  `tapTargetSize: shrinkWrap`).
- Filter chips are **People / Servers / All**, in that order, and 20% wider than their natural size
  (extra width added as horizontal padding, measured from the bold label so selection doesn't
  resize them). "Servers" covers both joined EME Servers and the user's MCP servers.
- Joined EME Servers appear in the chat list (`UnifiedChatItem.isServer`); tapping opens
  `ServerChatScreen`. There is no separate "Browse servers" entry point anymore.

**Search (`lib/screens/search/unified_search_screen.dart`)**
- **Full-screen modal** (`MaterialPageRoute(fullscreenDialog: true)`) with a **back arrow** on the
  left (not an X).
- **People and servers are searched together**: one query field, one row of category pills, an
  All / People / Servers segmented switch, and **one combined results list** (A–Z, each row tagged
  "Person" or "Server"). Don't split them back into tabs or separate sections.
- Category pills = backend server categories + EME profile categories (`kEmeProfileCategories`,
  e.g. "Mobility & Rides"), de-duplicated by name. A pill filters both kinds by category name.
- Tapping a person opens `EmeProfileCard(profile: p).showDetails(context)` (profile sheet with a
  greeting composer). Tapping a server calls `ServerCard(server: s).joinAndOpen(context, ref)`
  (joins if needed, then opens its chat, so it shows up in the chat list).
- The backend has no combined search yet: the screen calls the people search and the server search
  separately and merges. When a combined endpoint exists, rewire only this screen.

**Profile page (`lib/screens/profile/profile_screen.dart`)** — order top to bottom:
1. `ProfileHeaderCard` (avatar, name + pencil, handle, tags; no action buttons)
2. `SelfChatComposer` — "EME <first name>" text area + Send to the user's own chat
3. `FilesSection`

**Messaging another person**: their profile sheet has a text area pre-filled with a greeting built
from **what the two users have in common** (`greeting_draft.dart`: shared tags/services, same
location; placeholder values like "EME Member" or email tags never count).

## Working style the owner expects

- **UI first, backend later** is fine — but still **no mock data in `lib/`** (AGENTS.md). Wire the
  UI to whatever real endpoints exist, show real loading/empty/error states, and list the backend
  work still needed in your summary.
- If a request would leave a feature unreachable (e.g. removing the only path to servers), say so
  and offer options before doing it.
- Keep tests and `.maestro/basic.yaml` in step with every UI change, and mention in the summary
  anything that changed that the owner didn't explicitly ask for.
- Only `dart format` the files you touched — never `dart format lib` (it reformats unrelated files).

## Building blocks to reuse

| Need | Use |
|---|---|
| Colours | `AppColors.*` (`primary`, `greenAccent`, `redAccent`, `darkSurface`/`lightSurface`, `darkCardBorder`/`lightCardBorder`, `textPrimary`/`textSecondary`/`textMuted` + `textDark*`) |
| Dark mode | `Theme.of(context).brightness == Brightness.dark` |
| Fonts | headings `GoogleFonts.plusJakartaSans` (w700–w800), body `GoogleFonts.inter` |
| Card container | `BoxDecoration(color: surface, borderRadius: 16–24, border: cardBorder)` |
| Pills/tags | `PillBadge` (`lib/widgets/pill_badge.dart`) |
| Category pill row | horizontal `ListView.separated`, height 36, pill radius 18, selected = `primary` (dark) / `0xFF64748B` (light) |
| Full-screen modal page | `Navigator.push(MaterialPageRoute(fullscreenDialog: true, ...))` + back-arrow `leading` |
| Bottom sheet | `showModalBottomSheet(isScrollControlled: true, backgroundColor: Colors.transparent)`; pad bottom by `MediaQuery.viewInsets.bottom` when it has a text field |
| User's own chat | `selfChatModel(user, profile)` in `self_chat_composer.dart` + `ChatDetailScreen.route` |
| Open a DM with someone | `EmeProfileCard(profile: p).showDetails(context)` or `ChatDetailScreen.route(chatModel)` |
| Open/join a server | `ServerCard(server: s).joinAndOpen(context, ref)`; after join/leave `ref.invalidate(userServersProvider)` |
| Sending a chat message | after `ChatSocketService().connect(...)`, check `isConnected` and throw if false (`sendMessage` drops silently), then show a red SnackBar on failure |
| Settings dialog | `SettingsDialog.show(context)` |

## Semantics identifiers (AGENTS.md rule)

Wrap every button, input, chip and tappable row you add or touch in
`Semantics(identifier: 'snake_case_id', child: ...)`; list items append an index
(`search_result_$index`). Existing ids used by tests/Maestro — don't rename without updating them:
`app_bar_profile_button`, `app_bar_overflow_menu`, `app_bar_back_to_chats`, `app_bar_notifications`,
`chats_search_input`, `chats_open_search`, `chat_filter_users|mcp|all`, `search_back`,
`search_input`, `search_type_all|people|servers`, `search_category_bar`, `search_category_$i`,
`search_results`, `search_result_$i`, `add_custom_server`, `profile_edit_button`,
`profile_chat_input`, `profile_chat_send`, `profile_greeting_input`, `profile_greeting_send`,
`profile_details_close`, `server_chat_input`, `server_chat_send`.

## Widget-test gotchas (learned the hard way)

- Find by id: `find.bySemanticsIdentifier('id')`; for the inner `TextField` use
  `find.descendant(of: find.bySemanticsIdentifier('id'), matching: find.byType(TextField))`.
- `find.text('X').last` often hits a heading with the same text; prefer ids.
- A full-screen route hides the page underneath (offstage), so finders only see the top page.
- Horizontal lists build lazily: off-screen pills don't exist until you
  `tester.scrollUntilVisible(finder, 200, scrollable: <Scrollable inside the bar>)`.
- Long pages: items below the fold can't be tapped; filter the view or `ensureVisible` first.
- A `ListTile` inside a `Container` with a background colour asserts — use `Material(color:, shape:)`.
- Test data lives in `test/test_helpers.dart` (`MockApiService`, user "Christopher B",
  "The Administrator", servers "Lakeview Stays & House Rentals" (joined) and
  "Artisan Goods & Organic Market"). Server categories don't load from it, so category pills in
  tests come from `kEmeProfileCategories`.
- `test/form_select_widget_test.dart` was already failing before the UI rework; don't chase it as
  a regression from UI changes.

Related: `eme-app-overview`, `eme-app-chat-ui`, `eme-sdk-overview`.
