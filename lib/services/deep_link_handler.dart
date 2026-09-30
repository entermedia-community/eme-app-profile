import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../main.dart';
import '../screens/chats/chat_detail_screen.dart';

class DeepLinkHandler {
  static final DeepLinkHandler instance = DeepLinkHandler._internal();

  DeepLinkHandler._internal();

  bool _isHandling = false;

  /// Handle a parsed deep link payload
  Future<void> handleDeepLink(
    DeepLinkPayload payload, {
    BuildContext? context,
  }) async {
    final targetUsername = payload.username;
    if (targetUsername == null || targetUsername.trim().isEmpty) {
      return;
    }

    final currentUser = AuthService.userId;
    if (currentUser == null || currentUser.trim().isEmpty) {
      debugPrint(
        '[DeepLinkHandler] User not authenticated yet; keeping pending deeplink for @$targetUsername',
      );
      return;
    }

    if (_isHandling) return;
    _isHandling = true;

    try {
      final navContext = context ?? rootNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        ScaffoldMessenger.of(navContext).hideCurrentSnackBar();
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text('Opening chat with @$targetUsername...'),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Connect user to resolve channel ID
      String? channelId = payload.channelId;
      if (channelId == null || channelId.isEmpty) {
        channelId = await ChatSocketService().connectUser(
          fromUser: currentUser,
          toUser: targetUsername,
        );
      }

      final chat = ChatModel(
        channelId: channelId,
        username: targetUsername,
        displayName: targetUsername,
        lastMessage: '',
        time: '',
        avatarColor: const Color(0xFF0284C7),
      );

      DeepLinkService.instance.clearPendingDeepLink();

      final navState = rootNavigatorKey.currentState;
      if (navState != null) {
        navState.push(ChatDetailScreen.route(chat));
      }
    } catch (e, stack) {
      debugPrint('[DeepLinkHandler] Error opening chat from deeplink: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'DeepLinkHandler.handleDeepLink failed for @$targetUsername',
      );
    } finally {
      _isHandling = false;
    }
  }

  /// Process any deferred deep link once user is logged in
  void checkPendingDeepLink([BuildContext? context]) {
    final pending = DeepLinkService.instance.pendingDeepLink;
    if (pending != null && pending.username != null) {
      handleDeepLink(pending, context: context);
    }
  }
}
