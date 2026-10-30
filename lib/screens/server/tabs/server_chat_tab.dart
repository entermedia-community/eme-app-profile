import 'dart:async';
import 'package:eme_world/widgets/delta_viewer.dart';
import 'package:flutter/material.dart' hide FormField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/chat/product_message_card.dart';
import '../../../widgets/chat/send_product_sheet.dart';

class ServerChatTab extends ConsumerStatefulWidget {
  final ServerModel server;

  /// When set, chat in this project's team channel (the web project chat
  /// page's channel) instead of the EME Server's channel.
  final String? projectCollectionId;

  /// When set, chat in this event's channel.
  final String? eventId;

  /// When set, opens this earlier session (channel) of the chat instead of
  /// the current one. See Session History.
  final String? initialChannelId;

  const ServerChatTab({
    super.key,
    required this.server,
    this.projectCollectionId,
    this.eventId,
    this.initialChannelId,
  });

  @override
  ConsumerState<ServerChatTab> createState() => _ServerChatTabState();
}

class _ServerChatTabState extends ConsumerState<ServerChatTab> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<ChatMessage>? _socketSubscription;
  String _channelId = '';
  bool _isConnecting = false;
  String? _connectionError;

  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [];
    _initChatConnection();
  }

  Future<void> _initChatConnection() async {
    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    final sessionChannel = widget.initialChannelId;
    if (sessionChannel != null) {
      try {
        await _openChannel(sessionChannel);
      } catch (e, stack) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'Error opening chat session in ServerChatTab',
          customKeys: {'channelId': sessionChannel},
        );
        if (mounted) setState(() => _connectionError = '$e');
      } finally {
        if (mounted) setState(() => _isConnecting = false);
      }
      return;
    }

    final eventId = widget.eventId;
    if (eventId != null) {
      try {
        _channelId = await ref.read(eventChatChannelProvider(eventId).future);
        await _connectSocket(_channelId);
        await _loadChatHistory(_channelId);
      } catch (e, stack) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'Error connecting event chat in ServerChatTab',
          customKeys: {'eventId': eventId},
        );
        if (mounted) setState(() => _connectionError = '$e');
      } finally {
        if (mounted) setState(() => _isConnecting = false);
      }
      return;
    }

    final projectId = widget.projectCollectionId;
    if (projectId != null) {
      try {
        final connection = await ref.read(
          projectChatConnectionProvider(projectId).future,
        );
        _channelId = connection.channelId;
        await _connectSocket(_channelId);
        await _loadChatHistory(_channelId);
      } catch (e, stack) {
        AppErrorHandler.recordNonFatal(
          e,
          stack,
          reason: 'Error connecting project chat in ServerChatTab',
          customKeys: {'collectionId': projectId},
        );
        if (mounted) setState(() => _connectionError = '$e');
      } finally {
        if (mounted) setState(() => _isConnecting = false);
      }
      return;
    }

    try {
      final channelId = await ref
          .read(apiServiceProvider)
          .connectServerChat(widget.server.id);
      await _openChannel(channelId);
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Error connecting server chat in ServerChatTab',
        customKeys: {'serverId': widget.server.id},
      );
      if (mounted) setState(() => _connectionError = '$e');
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  // Project and event chats use the app's default server
  String? get _serverBaseUrl =>
      widget.projectCollectionId == null &&
          widget.eventId == null &&
          widget.server.serverMediaDBUrl.isNotEmpty
      ? widget.server.serverMediaDBUrl
      : null;

  /// Points the socket and history at [channelId], reconnecting only when the
  /// channel changed (the socket ignores connect() while already connected).
  Future<void> _openChannel(String channelId) async {
    if (channelId == _channelId && ChatSocketService().isConnected) return;
    if (_channelId.isNotEmpty) ChatSocketService().disconnect();
    _channelId = channelId;
    await _connectSocket(channelId, baseUrl: _serverBaseUrl);
    await _loadChatHistory(channelId, baseUrl: _serverBaseUrl);
  }

  Future<void> _loadChatHistory(String channelId, {String? baseUrl}) async {
    try {
      final history = await ref
          .read(apiServiceProvider)
          .fetchServerChatMessages(
            channelId,
            serverId: widget.server.id,
            baseUrl: baseUrl,
          );
      if (!mounted) return;
      if (history.isNotEmpty) {
        // Sort chronologically so latest messages appear at the bottom
        history.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        setState(() {
          _messages = history;
        });
        _scrollToBottom();
      }
    } catch (e, stack) {
      debugPrint('Error loading server chat history: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Error loading server chat history in ServerChatTab',
        customKeys: {'channelId': channelId, 'serverId': widget.server.id},
      );
    }
  }

  Future<void> _connectSocket(String channelId, {String? baseUrl}) async {
    final currentUserId = AuthService.userId;
    await ChatSocketService().connect(
      channel: channelId,
      userId: currentUserId,
      baseUrl: baseUrl,
    );
    _socketSubscription?.cancel();
    _socketSubscription = ChatSocketService().messageStream.listen((
      incomingMsg,
    ) {
      debugPrint('ServerChatTab incomingMsg: ${incomingMsg.toJson()}');
      if (incomingMsg.isKeepAlive) return;
      if (!mounted) return;

      if (incomingMsg.channel.isNotEmpty &&
          incomingMsg.channel != channelId &&
          incomingMsg.channel != widget.server.id) {
        return;
      }

      final added = _mergeIncoming(incomingMsg);
      setState(() {});
      if (added) _scrollToBottom();
    });
  }

  static const _localIdPrefix = 'local_';

  /// Applies a socket message to [_messages] and returns whether it was new.
  /// The server re-sends a message under the same id when it changes (agent
  /// status updates, messagereload), and echoes the ones this device already
  /// shows locally, so both replace the existing entry instead of adding one.
  bool _mergeIncoming(ChatMessage msg) {
    if (msg.isMessageRemoved) {
      _messages.removeWhere((m) => m.messageId == msg.messageId);
      return false;
    }
    var index = _messages.indexWhere((m) => m.messageId == msg.messageId);
    if (index < 0) {
      index = _messages.indexWhere(
        (m) =>
            m.messageId.startsWith(_localIdPrefix) &&
            m.userId == msg.userId &&
            m.message == msg.message,
      );
    }
    if (index < 0) {
      _messages.add(msg);
      return true;
    }
    // The echo may not carry the product card the local copy was built with
    _messages[index] = msg.product == null
        ? msg.copyWith(product: _messages[index].product)
        : msg;
    return false;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    ChatSocketService().disconnect();
    _textController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final targetChannel = _channelId;
    final currentUserId = AuthService.userId ?? 'user';

    setState(() {
      _textController.clear();
    });

    try {
      if (ChatSocketService().isConnected && targetChannel.isNotEmpty) {
        ChatSocketService().sendMessage(
          message: text,
          user: currentUserId,
          channel: targetChannel,
          command: 'messagereceived',
          extraData: {"entityid": widget.server.id},
        );
      }
    } catch (e, stack) {
      debugPrint('Failed to send message over socket: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason:
            'Failed to send message over ChatSocketService in ServerChatTab',
      );
    }
  }

  void _sendProduct(ProductMessageModel product) {
    final targetChannel = _channelId;
    final currentUserId = AuthService.userId ?? 'user';

    setState(() {
      _messages.add(
        ChatMessage(
          messageId: '$_localIdPrefix${DateTime.now().millisecondsSinceEpoch}',
          channel: targetChannel,
          userId: currentUserId,
          message:
              'Shared a ${product.typeLabel.toLowerCase()}: ${product.title}',
          messageType: 'product',
          product: product,
          agentContextValues: AgentContextValues(
            messageRenderType: MessageRenderType.product,
            product: product,
          ),
          createdAt: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();

    try {
      if (ChatSocketService().isConnected && targetChannel.isNotEmpty) {
        ChatSocketService().sendMessage(
          message:
              'Shared a ${product.typeLabel.toLowerCase()}: ${product.title}',
          user: currentUserId,
          channel: targetChannel,
          command: 'messagereceived',
          messageType: 'product',
          extraData: {'product': product.toJson()},
        );
      }
    } catch (e, stack) {
      debugPrint('Failed to send product over socket: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason:
            'Failed to send product over ChatSocketService in ServerChatTab',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Message Feed
        Expanded(
          child: _isConnecting && _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.server.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Connecting to channel...',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : _connectionError != null && _messages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textMuted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Could not open the chat.\n$_connectionError',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textSecondary,
                          ),
                        ),
                        Semantics(
                          identifier: 'server_chat_retry',
                          child: TextButton(
                            onPressed: () {
                              final eventId = widget.eventId;
                              if (eventId != null) {
                                ref.invalidate(
                                  eventChatChannelProvider(eventId),
                                );
                              }
                              final id = widget.projectCollectionId;
                              if (id != null) {
                                ref.invalidate(
                                  projectChatConnectionProvider(id),
                                );
                              }
                              _initChatConnection();
                            },
                            child: const Text('Retry'),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _messages.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.chat_bubble_outline_rounded,
                        size: 48,
                        color: isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No messages in ${widget.server.name} yet!',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return _buildMessageItem(msg, isDark);
                  },
                ),
        ),

        // Input Box
        _buildChatInput(isDark),
      ],
    );
  }

  Widget _buildMessageItem(ChatMessage msg, bool isDark) {
    final isMe = msg.isUser;
    final timeStr = _formatTime(msg.createdAt);

    if (msg.messageRenderType.isForm) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Center(child: _buildFormBubble(msg, timeStr, isDark)),
      );
    }

    if (isMe) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: _buildMessageContent(msg, isMe, timeStr, isDark),
                ),
              ],
            ),
            if (msg.messageRenderType.isProduct && msg.product != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: ProductMessageCard(product: msg.product!, isMe: true),
              ),
            ],
          ],
        ),
      );
    }

    final senderName = msg.userId.isNotEmpty ? msg.userId : 'Member';
    final senderInitials = senderName.length >= 2
        ? senderName.substring(0, 2).toUpperCase()
        : senderName.toUpperCase();
    final badgeRole = msg.isAI ? 'AI BOT' : 'MEMBER';
    final badgeColor = msg.isAI
        ? AppColors.primary
        : widget.server.primaryColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: isDark ? 0.3 : 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: badgeColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                senderInitials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: badgeColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      senderName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeRole,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _buildMessageContent(msg, isMe, timeStr, isDark),
                if (msg.messageRenderType.isProduct && msg.product != null) ...[
                  ProductMessageCard(product: msg.product!, isMe: false),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    ChatMessage message,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    debugPrint(
      'ServerChatTab rendering message type: ${message.messageRenderType}',
    );
    switch (message.messageRenderType) {
      case MessageRenderType.asset:
        return _buildAssetCard(message, isMe, timeStr, isDark);
      case MessageRenderType.welcome:
        return _buildWelcomeBubble(message, isMe, timeStr, isDark);
      case MessageRenderType.product:
      case MessageRenderType.text:
        return _buildStandardBubble(message.text, isMe, timeStr, isDark);
      case MessageRenderType.delta:
        return _buildDeltaBubble(message.deltaOps, isMe, timeStr, isDark);
      case MessageRenderType.form:
        return _buildFormBubble(message, timeStr, isDark);
    }
  }

  Widget _buildStandardBubble(
    String text,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe
            ? widget.server.primaryColor
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: isMe
            ? null
            : Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.lightCardBorder,
              ),
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isMe
                  ? Colors.white
                  : (isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: isMe
                      ? Colors.white70
                      : (isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textMuted),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all_rounded,
                  size: 12,
                  color: Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeltaBubble(
    List<dynamic> deltas,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary
            : (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
        border: isMe
            ? null
            : Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.lightCardBorder,
              ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          DeltaViewer(deltaOps: deltas, onLinkTap: _handleLinkTap),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeStr,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isMe
                      ? Colors.white.withValues(alpha: 0.75)
                      : (isDark
                            ? AppColors.textDarkMuted
                            : AppColors.textMuted),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all_rounded,
                  size: 13,
                  color: Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBubble(
    ChatMessage message,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: widget.server.primaryColor.withValues(
          alpha: isDark ? 0.15 : 0.08,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.server.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.waving_hand_rounded,
                size: 16,
                color: widget.server.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'WELCOME',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: widget.server.primaryColor,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message.text,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeStr,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormBubble(ChatMessage message, String timeStr, bool isDark) {
    return _ChatFormWidget(
      fields: message.formFields,
      timeStr: timeStr,
      isDark: isDark,
      primaryColor: widget.server.primaryColor,
      onSubmit: (values) => _handleFormSubmit(message, values),
    );
  }

  void _handleFormSubmit(ChatMessage message, Map<String, dynamic> values) {
    final targetChannel = _channelId;
    final currentUserId = AuthService.userId ?? 'user';

    final summary = values.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    final submitText = 'Submitted: $summary';

    setState(() {
      _messages.add(
        ChatMessage(
          messageId: '$_localIdPrefix${DateTime.now().millisecondsSinceEpoch}',
          channel: targetChannel,
          userId: currentUserId,
          message: submitText,
          replyToId: message.messageId,
          createdAt: DateTime.now(),
        ),
      );
    });

    _scrollToBottom();

    try {
      if (ChatSocketService().isConnected && targetChannel.isNotEmpty) {
        ChatSocketService().sendMessage(
          message: submitText,
          user: currentUserId,
          channel: targetChannel,
          command: 'messagereceived',
          replyToId: message.messageId,
          extraData: {
            'form': values,
            'entityid': widget.server.id,
            'replytoid': message.messageId,
          },
        );
      }
    } catch (e, stack) {
      debugPrint('Failed to send form response over socket: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason:
            'Failed to send form response over ChatSocketService in ServerChatTab',
      );
    }
  }

  Widget _buildAssetCard(
    ChatMessage message,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    final asset = message.asset;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.server.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.attachment_rounded,
              color: widget.server.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset?.mediaType ?? 'Asset',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                Text(
                  asset?.url ?? 'Media file',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.lightCardBorder,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.add_circle_outline_rounded,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
                size: 22,
              ),
              tooltip: 'Share Product or Service',
              onPressed: () {
                SendProductSheet.show(
                  context,
                  onProductSelected: (product) => _sendProduct(product),
                );
              },
            ),
            Expanded(
              child: Semantics(
                identifier: "server_chat_input",
                child: TextField(
                  controller: _textController,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText: 'Type your message...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textDarkMuted
                          : AppColors.textMuted,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkCardBorder
                            : AppColors.lightCardBorder,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.darkCardBorder
                            : AppColors.lightCardBorder,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide(
                        color: widget.server.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: widget.server.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Semantics(
                identifier: "server_chat_send",
                child: IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: _sendMessage,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLinkTap(String link, Map<String, dynamic> data) async {
    debugPrint(
      "Link: $link",
    ); //e.g.: /site/mediadb/views/modules/emeserver/editors/entitychat/chatterbox/changescenario.html
    debugPrint(
      "Data: $data",
    ); //e.g.; {targetdiv: changescenario, channel: AaFAj3-udKixTInEx17X, currentscenario: eme_server_search_media, functionname: eme_server_search_media_confirm, oemaxlevel: 1}
    // Event chat has no form callbacks yet.
    if (widget.eventId != null) return;
    try {
      final api = ref.read(apiServiceProvider);
      final projectId = widget.projectCollectionId;
      final channelId = projectId != null
          ? (await api.connectProjectChat(projectId, params: data)).channelId
          : await api.connectServerChat(widget.server.id, params: data);
      await _openChannel(channelId);
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Error handling chat link tap in ServerChatTab',
        customKeys: {'serverId': widget.server.id, 'link': link},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open: $e')));
    }
  }
}

class _ChatFormWidget extends StatefulWidget {
  final List<FormField> fields;
  final String timeStr;
  final bool isDark;
  final Color primaryColor;
  final void Function(Map<String, dynamic> values) onSubmit;

  const _ChatFormWidget({
    required this.fields,
    required this.timeStr,
    required this.isDark,
    required this.primaryColor,
    required this.onSubmit,
  });

  @override
  State<_ChatFormWidget> createState() => _ChatFormWidgetState();
}

class _ChatFormWidgetState extends State<_ChatFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _boolValues = {};
  final Map<String, dynamic> _selectValues = {};
  bool _isSubmitted = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _initFields();
  }

  void _initFields() {
    for (final field in widget.fields) {
      final type = field.type.name;
      final isSelect =
          field.type == FormFieldType.select ||
          type == 'select' ||
          type == 'dropdown' ||
          field.options.isNotEmpty;

      if (type == 'bool' || type == 'boolean' || type == 'checkbox') {
        final val = field.value;
        _boolValues[field.name] =
            (val == true || val == 'true' || val == 1 || val == '1');
      } else if (isSelect) {
        dynamic initialValue;
        if (field.value != null) {
          for (final opt in field.options) {
            if (opt.value == field.value ||
                opt.value?.toString() == field.value?.toString()) {
              initialValue = opt.value;
              break;
            }
          }
        }
        _selectValues[field.name] = initialValue;
      } else {
        _controllers[field.name] = TextEditingController(
          text: field.value?.toString() ?? '',
        );
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool get _isFormReadOnly {
    final fields = widget.fields;
    if (fields.isEmpty) return true;
    return fields.every((f) => f.readOnly == true);
  }

  Future<void> _pickDate(String fieldName, bool isReadOnly) async {
    if (isReadOnly) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: widget.isDark ? ThemeData.dark() : ThemeData.light(),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null && mounted) {
      final formatted =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      _controllers[fieldName]?.text = formatted;
    }
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting || _isSubmitted) return;
    if (!(_formKey.currentState?.validate() ?? true)) return;

    setState(() {
      _isSubmitting = true;
    });

    final Map<String, dynamic> result = {};
    for (final field in widget.fields) {
      final type = field.type.name;
      final isSelect =
          field.type == FormFieldType.select ||
          type == 'select' ||
          type == 'dropdown' ||
          field.options.isNotEmpty;

      if (type == 'bool' || type == 'boolean' || type == 'checkbox') {
        result[field.name] = _boolValues[field.name] ?? false;
      } else if (isSelect) {
        result[field.name] = _selectValues[field.name] ?? '';
      } else {
        result[field.name] = _controllers[field.name]?.text.trim() ?? '';
      }
    }

    widget.onSubmit(result);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
    }
  }

  InputDecoration _buildInputDecoration({
    required String labelText,
    String? hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: GoogleFonts.inter(
        fontSize: 12.5,
        color: widget.isDark ? AppColors.textDarkMuted : AppColors.textMuted,
      ),
      labelStyle: GoogleFonts.inter(
        fontSize: 12.5,
        color: widget.isDark ? AppColors.textDarkMuted : AppColors.textMuted,
      ),
      filled: true,
      fillColor: widget.isDark
          ? AppColors.darkCardBorder.withValues(alpha: 0.35)
          : AppColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: widget.isDark
              ? AppColors.darkCardBorder
              : AppColors.lightCardBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: widget.isDark
              ? AppColors.darkCardBorder
              : AppColors.lightCardBorder,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color:
              (widget.isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder)
                  .withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
      ),
    );
  }

  Widget _buildFieldWidget(FormField field) {
    final type = field.type.name;
    final name = field.name;
    final label = field.label.isNotEmpty ? field.label : field.name;
    final isFieldReadOnly =
        (field.readOnly == true) || _isFormReadOnly || _isSubmitted;
    final isSelect =
        field.type == FormFieldType.select ||
        type == 'select' ||
        type == 'dropdown' ||
        field.options.isNotEmpty;

    if (type == 'bool' || type == 'boolean' || type == 'checkbox') {
      final isChecked = _boolValues[name] ?? false;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isDark
              ? AppColors.darkCardBorder.withValues(alpha: 0.25)
              : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: widget.isDark
                ? AppColors.darkCardBorder
                : AppColors.lightCardBorder,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ),
            Checkbox(
              value: isChecked,
              activeColor: widget.primaryColor,
              onChanged: isFieldReadOnly
                  ? null
                  : (bool? val) {
                      setState(() {
                        _boolValues[name] = val ?? false;
                      });
                    },
            ),
          ],
        ),
      );
    }

    if (isSelect) {
      final seenValues = <dynamic>{};
      final uniqueOptions = <FormFieldOption>[];
      for (final opt in field.options) {
        if (!seenValues.contains(opt.value)) {
          seenValues.add(opt.value);
          uniqueOptions.add(opt);
        }
      }

      final currentValue = _selectValues[name];
      final validValue = seenValues.contains(currentValue)
          ? currentValue
          : null;

      return DropdownButtonFormField<dynamic>(
        initialValue: validValue,
        isExpanded: true,
        dropdownColor: widget.isDark ? AppColors.darkSurface : Colors.white,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: widget.isDark
              ? AppColors.textDarkPrimary
              : AppColors.textPrimary,
        ),
        icon: Icon(
          Icons.arrow_drop_down_rounded,
          color: widget.isDark ? AppColors.textDarkMuted : AppColors.textMuted,
        ),
        hint: Text(
          uniqueOptions.isEmpty ? 'No options available' : 'Select $label',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: widget.isDark
                ? AppColors.textDarkMuted
                : AppColors.textMuted,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        disabledHint: validValue != null
            ? null
            : Text(
                'None selected',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color:
                      (widget.isDark
                              ? AppColors.textDarkMuted
                              : AppColors.textMuted)
                          .withValues(alpha: 0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
        decoration: _buildInputDecoration(labelText: label),
        items: uniqueOptions.map((opt) {
          final optText = opt.label.isNotEmpty
              ? opt.label
              : opt.value?.toString() ?? '';
          return DropdownMenuItem<dynamic>(
            value: opt.value,
            child: Text(
              optText,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: widget.isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: isFieldReadOnly
            ? null
            : (val) {
                setState(() {
                  _selectValues[name] = val;
                });
              },
      );
    }

    if (type == 'date') {
      return TextFormField(
        controller: _controllers[name],
        readOnly: true,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: widget.isDark
              ? AppColors.textDarkPrimary
              : AppColors.textPrimary,
        ),
        onTap: () => _pickDate(name, isFieldReadOnly),
        decoration: _buildInputDecoration(
          labelText: label,
          hintText: 'YYYY-MM-DD',
          suffixIcon: IconButton(
            icon: Icon(
              Icons.calendar_today_rounded,
              size: 18,
              color: widget.primaryColor,
            ),
            onPressed: isFieldReadOnly
                ? null
                : () => _pickDate(name, isFieldReadOnly),
          ),
        ),
      );
    }

    final isMultiline =
        type == 'textarea' || type == 'multiline' || type == 'paragraph';
    final isNumber =
        type == 'number' ||
        type == 'int' ||
        type == 'integer' ||
        type == 'decimal' ||
        type == 'float' ||
        type == 'numeric';
    final isPhone = type == 'phone' || type == 'tel';
    final isEmail = type == 'email';
    final isPassword = type == 'password';

    TextInputType keyboardType = TextInputType.text;
    if (isMultiline) {
      keyboardType = TextInputType.multiline;
    } else if (isNumber) {
      keyboardType = const TextInputType.numberWithOptions(decimal: true);
    } else if (isPhone) {
      keyboardType = TextInputType.phone;
    } else if (isEmail) {
      keyboardType = TextInputType.emailAddress;
    }

    return TextFormField(
      controller: _controllers[name],
      readOnly: isFieldReadOnly,
      minLines: isMultiline ? 3 : 1,
      maxLines: isMultiline ? 5 : 1,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: widget.isDark
            ? AppColors.textDarkPrimary
            : AppColors.textPrimary,
      ),
      decoration: _buildInputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hidden fields keep their value in _controllers and are submitted, but never shown
    final fields = widget.fields
        .where((f) => f.type != FormFieldType.hidden)
        .toList();
    final cardBg = widget.isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark
              ? AppColors.darkCardBorder
              : AppColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.dynamic_form_rounded,
                    size: 18,
                    color: widget.primaryColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Form',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: widget.isDark
                          ? AppColors.textDarkPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _isSubmitted
                        ? Colors.green.withValues(alpha: 0.15)
                        : (_isFormReadOnly
                              ? (widget.isDark
                                    ? AppColors.darkCardBorder
                                    : AppColors.lightCardBorder)
                              : widget.primaryColor.withValues(alpha: 0.12)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _isSubmitted
                        ? 'SUBMITTED'
                        : (_isFormReadOnly ? 'VIEW ONLY' : 'FORM'),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _isSubmitted
                          ? Colors.green
                          : (_isFormReadOnly
                                ? (widget.isDark
                                      ? AppColors.textDarkMuted
                                      : AppColors.textMuted)
                                : widget.primaryColor),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Form Fields
            if (fields.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'No fields available.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: widget.isDark
                          ? AppColors.textDarkMuted
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              )
            else
              for (int i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _buildFieldWidget(fields[i]),
              ],

            // Submit Button or Submitted Badge
            if (!_isFormReadOnly && !_isSubmitted) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ] else if (_isSubmitted) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(
                    alpha: widget.isDark ? 0.2 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Submitted successfully',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Time footer
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                widget.timeStr,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: widget.isDark
                      ? AppColors.textDarkMuted
                      : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
