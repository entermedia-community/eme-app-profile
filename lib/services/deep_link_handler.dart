import 'dart:async';
import 'package:flutter/material.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

class DeepLinkHandler {
  static final DeepLinkHandler instance = DeepLinkHandler._internal();

  DeepLinkHandler._internal();

  bool _isHandling = false;

  /// How the server for a tapped server notification is loaded. Replaced in tests.
  IApiService Function() apiServiceFactory = ApiService.new;

  /// Handle a parsed deep link payload
  Future<void> handleDeepLink(
    DeepLinkPayload payload, {
    BuildContext? context,
  }) async {
    final serverId = payload.serverId;
    if (payload.type == DeepLinkType.server &&
        serverId != null &&
        serverId.trim().isNotEmpty) {
      return _openServerChat(serverId.trim());
    }

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

      final navContext2 = rootNavigatorKey.currentContext;
      if (navContext2 != null && navContext2.mounted) {
        navContext2.push(
          AppRoutes.chatPath(targetUsername),
          extra: ChatRouteExtra(chat),
        );
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

  /// Opens the chat of EME Server [serverId], e.g. from a tapped notification.
  Future<void> _openServerChat(String serverId) async {
    final currentUser = AuthService.userId;
    if (currentUser == null || currentUser.trim().isEmpty) {
      debugPrint(
        '[DeepLinkHandler] User not authenticated yet; cannot open server $serverId',
      );
      return;
    }
    if (_isHandling) return;
    _isHandling = true;
    try {
      final server = await apiServiceFactory().fetchServerById(serverId);
      if (server == null) {
        debugPrint('[DeepLinkHandler] Server $serverId not found');
        return;
      }
      DeepLinkService.instance.clearPendingDeepLink();
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        navContext.push(AppRoutes.serverPath(server.id), extra: server);
      }
    } catch (e, stack) {
      debugPrint('[DeepLinkHandler] Error opening server $serverId: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'DeepLinkHandler._openServerChat failed for $serverId',
      );
    } finally {
      _isHandling = false;
    }
  }

  /// Process any deferred deep link once user is logged in
  void checkPendingDeepLink([BuildContext? context]) {
    final pending = DeepLinkService.instance.pendingDeepLink;
    if (pending != null &&
        (pending.username != null || pending.serverId != null)) {
      handleDeepLink(pending, context: context);
    }
  }
}
