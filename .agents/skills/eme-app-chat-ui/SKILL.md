---
name: eme-app-chat-ui
description: How the chat screens of the EME Collective Intelligence app work and how to change them — message bubbles per MessageRenderType (text, welcome, delta, form, asset, product), the chat input, sending messages/products/forms, and the socket lifecycle in ChatDetailScreen (user DMs) and ServerChatTab (EME Server chat). Use for any change to chat UI, message rendering, composer behaviour, or when adding a new message type to the app.
---

# Chat UI in the EME app

Two screens render `ChatMessage`s and **duplicate** most of the logic, so a change usually has to
be made in both:

| | User ↔ user DM | User ↔ EME Server |
|---|---|---|
| File | `lib/screens/chats/chat_detail_screen.dart` | `lib/screens/server/tabs/server_chat_tab.dart` |
| Connect | `ChatSocketService().connectUser(...)` → `connect(channel:)` | `_initChatConnection`: `connectChat(server.id)` → `_connectSocket(channel, baseUrl: server.serverMediaDBUrl)` → `_loadChatHistory` |
| Item builder | `_buildMessageBubble` | `_buildMessageItem` (forms render full-width, outside a bubble) |
| Type switch | `_buildMessageContent` | `_buildMessageContent` |
| Bubbles | `_buildStandardBubble`, `_buildDeltaBubble`, `_buildFormBubble`, `_buildWelcomeBubble`, `_buildAssetCard` | same names + an interactive form widget (`_buildFieldWidget`, read-only/submitted states) |
| Send | `_sendMessage()` | `_sendMessage()`; form submit near line ~936 via `connectChat(server.id, params: data)` |
| Input | `TextField` with `onSubmitted` | `_buildChatInput` with Semantics ids `server_chat_input`, `server_chat_send` |

MCP chats (`mcp_chat_detail_screen.dart`) use `McpChatMessage`, not `ChatMessage`, and are separate.

## The chat list (`lib/screens/chats/chats_screen.dart`)

- Rows come from `unifiedChatsProvider` (SDK): `UnifiedChatItem.isUser` (DM), `.isMcp` (user-added
  MCP server) and `.isServer` (joined EME Server, `item.emeServer`). Handle all three when you add
  per-row behaviour (avatar fallback, tap, long-press).
- Filter chips are People (`isUser`) / Servers (`isMcp || isServer`) / All — owner's order and
  labels; enum is still `ChatFilter { all, users, mcp }`.
- Tapping a server row opens `ServerChatScreen.route(item.emeServer!)`.
- Top row: conversation search + "EME Search" button (opens `UnifiedSearchScreen`). Keep the button
  the same height as the input. See `eme-app-ui` for the owner's layout preferences.

## Sending without opening a chat first

Two inline composers send a message, then open the chat:
- `lib/screens/profile/widgets/self_chat_composer.dart` — to the user's own chat (`connectUser(me, me)`).
- `_GreetingComposer` in `lib/screens/eme_world/widgets/eme_profile_card.dart` — to another person,
  pre-filled from `greeting_draft.dart`.

Both connect, check `ChatSocketService().isConnected` and throw if false (because `sendMessage`
drops messages silently), then show a red SnackBar on failure. Copy that pattern.

Shared widgets: `lib/widgets/delta_viewer.dart` (read-only Quill delta, handles links),
`lib/widgets/chat/product_message_card.dart`, `send_product_sheet.dart`, `product_detail_modal.dart`.

## Message types → widgets

`message.messageRenderType` is computed in the SDK (see `eme-sdk-chat-messages`):

- `text` / `product` → standard bubble (`message.text`). A product also renders
  `ProductMessageCard` under it when `message.product != null`.
- `welcome` → centred welcome bubble
- `delta` → `DeltaViewer(message.deltaOps)`
- `form` → `message.formFields` (`FormFieldType`: text, number, boolean, select, radio, checkbox).
  Switch on `field.type` (the enum), not on strings.
- `asset` → `_buildAssetCard` using `message.asset` (thumbnail, url, mediaType)

`message.isUser` decides alignment and colour. `message.createdAt` is formatted to `timeStr` by the caller.

## Adding a new message type

1. SDK: add the enum value and parsing (`eme-sdk-chat-messages` skill).
2. Run `flutter analyze` here. It reports both non-exhaustive switches.
3. Add `_buildXxxBubble` to **both** screens. If it's more than ~40 lines, make one shared widget in
   `lib/widgets/chat/xxx_message_card.dart` and call it from both screens. Don't copy it twice.
4. Add a widget test (see `test/product_message_test.dart`, `test/form_select_widget_test.dart`).

## Socket lifecycle rules

- `ChatSocketService()` is a singleton shared by every chat screen. Always:
  - filter incoming messages by `channel` (and ignore `isKeepAlive` / `isMessageRemoved`),
  - keep the `StreamSubscription` and `cancel()` it in `dispose()`,
  - check `mounted` before `setState`,
  - call `_scrollToBottom()` after appending.
- Send optimistic local messages only if the existing screen already does so, and keep that
  behaviour consistent between the two screens.
- `sendMessage` silently drops messages when the socket is down. If you touch sending, surface a
  visible error to the user instead of pretending it was sent.
- `ServerChatTab._initChatConnection` falls back to `server.id` as the channel when `connectChat`
  fails. That's existing behaviour, so don't add new fallbacks like it (AGENTS.md). If it's in the
  way, raise it with the user.

## Verify

```bash
flutter analyze
flutter test test/chat_detail_test.dart test/mcp_chat_widget_test.dart test/form_select_widget_test.dart test/product_message_test.dart test/server_navigation_test.dart
maestro test .maestro/basic.yaml   # end-to-end server chat send, needs device + backend
```
