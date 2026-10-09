import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/chat/product_message_card.dart';
import '../../../widgets/chat/send_product_sheet.dart';

class ServerChatTab extends ConsumerStatefulWidget {
  final ServerModel server;

  const ServerChatTab({super.key, required this.server});

  @override
  ConsumerState<ServerChatTab> createState() => _ServerChatTabState();
}

class _ServerChatTabState extends ConsumerState<ServerChatTab> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<ChatMessage>? _socketSubscription;
  late final String _channelId;
  bool _isConnecting = false;

  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [];
    _initChatConnection();
  }

  Future<void> _initChatConnection() async {
    setState(() => _isConnecting = true);

    try {
      final serverId = widget.server.id;
      final customBaseUrl = widget.server.serverMediaDBUrl.isNotEmpty
          ? widget.server.serverMediaDBUrl
          : null;

      // Make connect request to ../services/chat/connect.json
      _channelId = await ChatSocketService().connectChat(serverId);

      await _connectSocket(_channelId, baseUrl: customBaseUrl);
      await _loadChatHistory(_channelId, baseUrl: customBaseUrl);
    } catch (e, stack) {
      debugPrint('Error establishing server chat socket: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Error establishing server chat socket in ServerChatTab',
        customKeys: {'serverId': widget.server.id},
      );
      final fallbackChannel = widget.server.id;
      if (fallbackChannel.isNotEmpty) {
        final customBaseUrl = widget.server.serverMediaDBUrl.isNotEmpty
            ? widget.server.serverMediaDBUrl
            : null;
        await _connectSocket(fallbackChannel, baseUrl: customBaseUrl);
        await _loadChatHistory(fallbackChannel, baseUrl: customBaseUrl);
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
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
      if (incomingMsg.isKeepAlive || incomingMsg.isMessageRemoved) return;
      if (!mounted) return;

      if (incomingMsg.channel.isNotEmpty &&
          incomingMsg.channel != channelId &&
          incomingMsg.channel != widget.server.id) {
        return;
      }

      setState(() {
        _messages.add(incomingMsg);
      });
      _scrollToBottom();
    });
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
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          channel: targetChannel,
          userId: currentUserId,
          message:
              'Shared a ${product.typeLabel.toLowerCase()}: ${product.title}',
          messageType: 'product',
          product: product,
          agentContextValues: AgentContextValues(
            messageRenderType: MessageRenderType.product,
            product: product,
            componentContent:
                'Shared a ${product.typeLabel.toLowerCase()}: ${product.title}',
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
    switch (message.messageRenderType) {
      case MessageRenderType.question:
        return _buildQuestionCard(message, isMe, timeStr, isDark);
      case MessageRenderType.progressupdate:
        return _buildProgressUpdateCard(message, isMe, timeStr, isDark);
      case MessageRenderType.asset:
        return _buildAssetCard(message, isMe, timeStr, isDark);
      case MessageRenderType.welcome:
        return _buildWelcomeBubble(message, isMe, timeStr, isDark);
      case MessageRenderType.product:
      case MessageRenderType.text:
      case MessageRenderType.answer:
      case MessageRenderType.answereval:
      case MessageRenderType.usercomment:
      case MessageRenderType.agentcomment:
      case MessageRenderType.end:
        return _buildStandardBubble(message.text, isMe, timeStr, isDark);
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

  Widget _buildQuestionCard(
    ChatMessage message,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    final question = message.question;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.server.primaryColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: widget.server.primaryColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: widget.server.primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                'QUESTION',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: widget.server.primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (question?.cognitiveLevel.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.server.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    question!.cognitiveLevel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: widget.server.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question?.question ?? message.text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          if (question != null && question.options.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...question.options.entries.map((entry) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: widget.server.primaryColor.withValues(
                          alpha: 0.15,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          entry.key.letter,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: widget.server.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textDarkPrimary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressUpdateCard(
    ChatMessage message,
    bool isMe,
    String timeStr,
    bool isDark,
  ) {
    final progress = message.progressUpdate;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF059669).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                size: 16,
                color: Color(0xFF059669),
              ),
              const SizedBox(width: 6),
              Text(
                'PROGRESS UPDATE',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF059669),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 10),
            _buildProgressBar(
              'Beginner',
              progress.beginnerProgress,
              Colors.blue,
              isDark,
            ),
            const SizedBox(height: 6),
            _buildProgressBar(
              'Competent',
              progress.competentProgress,
              Colors.orange,
              isDark,
            ),
            const SizedBox(height: 6),
            _buildProgressBar(
              'Expert',
              progress.expertProgress,
              const Color(0xFF059669),
              isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(
    String label,
    double value,
    Color color,
    bool isDark,
  ) {
    final clamped = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
            Text(
              '${(clamped * 100).toInt()}%',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clamped,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
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
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: widget.server.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
