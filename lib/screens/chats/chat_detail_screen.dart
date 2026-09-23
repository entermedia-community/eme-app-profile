import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chat/product_message_card.dart';
import '../../widgets/chat/send_product_sheet.dart';
import 'chat_info_screen.dart';
import 'widgets/qr_connect_modal.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatDetailScreen({
    super.key,
    required this.chat,
  });

  /// Custom route to animate the screen in with smooth sliding transition
  static Route<void> route(ChatModel chat) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) => ChatDetailScreen(chat: chat),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSearchOpen = false;
  String _searchQuery = '';
  late List<ChatMessage> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        messageId: '1',
        channel: widget.chat.id,
        userId: widget.chat.id,
        message: 'Hello! Welcome to the ${widget.chat.userName} channel.',
        messageType: 'welcome',
        agentContextValues: AgentContextValues(
          messageRenderType: MessageRenderType.welcome,
          componentContent: 'Hello! Welcome to the ${widget.chat.userName} channel.',
        ),
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ChatMessage(
        messageId: '2',
        channel: widget.chat.id,
        userId: widget.chat.id,
        message: widget.chat.lastMessage,
        messageType: 'message',
        agentContextValues: AgentContextValues(
          messageRenderType: MessageRenderType.text,
          componentContent: widget.chat.lastMessage,
        ),
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatMessage(
        messageId: '3',
        channel: widget.chat.id,
        userId: 'user',
        message: 'Great, thanks for the update! Reviewing the details now.',
        messageType: 'message',
        agentContextValues: AgentContextValues(
          messageRenderType: MessageRenderType.text,
          componentContent: 'Great, thanks for the update! Reviewing the details now.',
        ),
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 2) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          channel: widget.chat.id,
          userId: 'user',
          message: text,
          messageType: 'message',
          agentContextValues: AgentContextValues(
            messageRenderType: MessageRenderType.text,
            componentContent: text,
          ),
          createdAt: DateTime.now(),
        ),
      );
      _messageController.clear();
    });

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

  void _sendProduct(ProductMessageModel product) {
    setState(() {
      _messages.add(
        ChatMessage(
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
          channel: widget.chat.id,
          userId: 'user',
          message: 'Shared a ${product.typeLabel.toLowerCase()}: ${product.title}',
          messageType: 'product',
          product: product,
          agentContextValues: AgentContextValues(
            messageRenderType: MessageRenderType.product,
            product: product,
            componentContent: 'Shared a ${product.typeLabel.toLowerCase()}: ${product.title}',
          ),
          createdAt: DateTime.now(),
        ),
      );
    });

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    final displayedMessages = _searchQuery.isEmpty
        ? _messages
        : _messages
            .where((m) => m.text.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back to Chats',
          onPressed: () => Navigator.of(context).pop(),
        ),
        // Chat Nav Header: Avatar & Name
        title: InkWell(
          onTap: () {
            // Open info drawer screen on tapping header
            Navigator.of(context).push(ChatInfoScreen.route(widget.chat));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: widget.chat.avatarColor.withValues(alpha: 0.2),
                      child: Text(
                        widget.chat.avatarInitials ?? widget.chat.userName.substring(0, 2),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          color: widget.chat.avatarColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (widget.chat.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.greenAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: surfaceColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.chat.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        widget.chat.isOnline ? 'Active now' : widget.chat.userRole,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: widget.chat.isOnline
                              ? AppColors.greenAccent
                              : (isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                          fontWeight: widget.chat.isOnline ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Action icons: Search, QR code, Info
        actions: [
          // 1. Search Icon
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.search_off_rounded : Icons.search_rounded,
              color: _isSearchOpen ? AppColors.primary : null,
              size: 22,
            ),
            tooltip: _isSearchOpen ? 'Close Search' : 'Search in Conversation',
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          // 2. QR Code Icon
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded, size: 22),
            tooltip: 'Show QR Code',
            onPressed: () {
              QrConnectModal.show(context, widget.chat);
            },
          ),
          // 3. Info Icon (opens screen animated from the right like a drawer)
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            tooltip: 'Chat Details & Info',
            onPressed: () {
              Navigator.of(context).push(ChatInfoScreen.route(widget.chat));
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Animated In-Chat Search Bar
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            child: _isSearchOpen
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      border: Border(
                        bottom: BorderSide(color: borderColor, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Search in conversation...',
                              hintStyle: GoogleFonts.inter(
                                fontSize: 13,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                              ),
                              prefixIcon: const Icon(Icons.search_rounded, size: 20),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                          _searchController.clear();
                                        });
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Messages List
          Expanded(
            child: displayedMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages found for "$_searchQuery"',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: displayedMessages.length,
                    itemBuilder: (context, index) {
                      final message = displayedMessages[index];
                      return _buildMessageBubble(message, isDark);
                    },
                  ),
          ),

          // Chat Input Area
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).padding.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                top: BorderSide(color: borderColor, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
                  color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
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
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      fillColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send_rounded, size: 19),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                  tooltip: 'Send',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final isMe = message.isUser;
    final timeStr = _formatTime(message.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: widget.chat.avatarColor.withValues(alpha: 0.2),
                  child: Text(
                    widget.chat.avatarInitials ?? widget.chat.userName.substring(0, 2),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      color: widget.chat.avatarColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: _buildMessageContent(message, isMe, timeStr, isDark),
              ),
            ],
          ),
          if (message.messageRenderType.isProduct && message.product != null) ...[
            Padding(
              padding: EdgeInsets.only(left: isMe ? 0 : 36, top: 4),
              child: ProductMessageCard(
                product: message.product!,
                isMe: isMe,
              ),
            ),
          ],
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
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
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
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isMe
                  ? Colors.white
                  : (isDark ? AppColors.textDarkPrimary : AppColors.textPrimary),
            ),
          ),
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
                      : (isDark ? AppColors.textDarkMuted : AppColors.textMuted),
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
        color: widget.chat.avatarColor.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.chat.avatarColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.waving_hand_rounded, size: 16, color: widget.chat.avatarColor),
              const SizedBox(width: 6),
              Text(
                'WELCOME',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: widget.chat.avatarColor,
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
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
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
              const Icon(Icons.help_outline_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'QUESTION',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              if (question?.cognitiveLevel.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    question!.cognitiveLevel.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          entry.key.letter,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
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
                          color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
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
        border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF059669)),
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
            _buildProgressBar('Beginner', progress.beginnerProgress, Colors.blue, isDark),
            const SizedBox(height: 6),
            _buildProgressBar('Competent', progress.competentProgress, Colors.orange, isDark),
            const SizedBox(height: 6),
            _buildProgressBar('Expert', progress.expertProgress, const Color(0xFF059669), isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color, bool isDark) {
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
                color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
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
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.attachment_rounded, color: AppColors.primary, size: 20),
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
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                  ),
                ),
                Text(
                  asset?.url ?? 'Media file',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
