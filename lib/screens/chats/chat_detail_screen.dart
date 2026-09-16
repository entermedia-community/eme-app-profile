import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_model.dart';
import '../../models/product_message_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chat/product_message_card.dart';
import '../../widgets/chat/send_product_sheet.dart';
import 'chat_info_screen.dart';
import 'widgets/qr_connect_modal.dart';

class _MessageItem {
  final String id;
  final String text;
  final String time;
  final bool isMe;
  final ProductMessageModel? product;

  const _MessageItem({
    required this.id,
    required this.text,
    required this.time,
    required this.isMe,
    this.product,
  });
}

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
  late List<_MessageItem> _messages;

  @override
  void initState() {
    super.initState();
    _messages = [
      _MessageItem(
        id: '1',
        text: 'Hello! Welcome to the ${widget.chat.userName} channel.',
        time: '10:00 AM',
        isMe: false,
      ),
      _MessageItem(
        id: '2',
        text: widget.chat.lastMessage,
        time: widget.chat.time,
        isMe: false,
      ),
      const _MessageItem(
        id: '3',
        text: 'Great, thanks for the update! Reviewing the details now.',
        time: 'Just now',
        isMe: true,
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

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _MessageItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
          time: 'Just now',
          isMe: true,
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
        _MessageItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Shared a ${product.typeLabel.toLowerCase()}: ${product.title}',
          time: 'Just now',
          isMe: true,
          product: product,
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

  Widget _buildMessageBubble(_MessageItem message, bool isDark) {
    final isMe = message.isMe;

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
                child: Container(
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
                        message.text,
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
                            message.time,
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
                ),
              ),
            ],
          ),
          if (message.product != null) ...[
            Padding(
              padding: EdgeInsets.only(left: isMe ? 0 : 36),
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
}
