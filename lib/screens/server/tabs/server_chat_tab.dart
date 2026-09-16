import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/product_message_model.dart';
import '../../../models/server_model.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/chat/product_message_card.dart';
import '../../../widgets/chat/send_product_sheet.dart';

class _ServerMessage {
  final String id;
  final String senderName;
  final String senderRole;
  final String avatarInitials;
  final String message;
  final String time;
  final bool isMe;
  final Color badgeColor;
  final ProductMessageModel? product;

  const _ServerMessage({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.avatarInitials,
    required this.message,
    required this.time,
    required this.isMe,
    required this.badgeColor,
    this.product,
  });
}

class ServerChatTab extends StatefulWidget {
  final ServerModel server;

  const ServerChatTab({super.key, required this.server});

  @override
  State<ServerChatTab> createState() => _ServerChatTabState();
}

class _ServerChatTabState extends State<ServerChatTab> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _channels = [
    '#general',
    '#announcements',
    '#marketplace',
    '#support-desk',
  ];
  int _selectedChannelIndex = 0;

  late List<_ServerMessage> _messages;

  @override
  void initState() {
    super.initState();
    _loadMessagesForServer();
  }

  void _loadMessagesForServer() {
    final catalog = ProductMessageModel.sampleCatalog;

    if (widget.server.category == ServerCategory.marketplaceAndGoods ||
        widget.server.id == 'srv_010') {
      _messages = [
        _ServerMessage(
          id: '1',
          senderName: 'Marketplace Bot',
          senderRole: 'VERIFIED NODE',
          avatarInitials: 'MB',
          message:
              'Welcome to ${widget.server.title}! Discover and purchase direct producer-harvested goods with smart contract escrow protection.',
          time: '8:30 AM',
          isMe: false,
          badgeColor: widget.server.primaryColor,
        ),
        _ServerMessage(
          id: '2',
          senderName: 'San Marcos Organic Co-op',
          senderRole: 'VERIFIED PRODUCER',
          avatarInitials: 'SM',
          message:
              'Fresh morning roast batch completed! We just listed 15 bags of our limited reserve single-origin Gesha coffee beans.',
          time: '9:15 AM',
          isMe: false,
          badgeColor: const Color(0xFFD97706),
          product: catalog[0], // Single Origin Coffee
        ),
        _ServerMessage(
          id: '3',
          senderName: 'K\'iche\' Weavers Guild',
          senderRole: 'ARTISAN COLLECTIVE',
          avatarInitials: 'KW',
          message:
              'New handwoven botanical dye wool poncho available in locker #4 or local delivery around the lake.',
          time: '10:05 AM',
          isMe: false,
          badgeColor: const Color(0xFF059669),
          product: catalog[1], // Handwoven Poncho
        ),
        const _ServerMessage(
          id: '4',
          senderName: 'You',
          senderRole: 'MEMBER',
          avatarInitials: 'ME',
          message: 'The Gesha roast looks incredible! Placing an order now.',
          time: 'Just now',
          isMe: true,
          badgeColor: AppColors.primary,
        ),
      ];
    } else if (widget.server.category == ServerCategory.mobilityAndRides ||
        widget.server.id == 'srv_009') {
      _messages = [
        _ServerMessage(
          id: '1',
          senderName: 'EcoTransit Dispatch',
          senderRole: 'DISPATCH NODE',
          avatarInitials: 'ET',
          message:
              'Active fleet operating 14 EV shuttles today across Lake Atitlan & Guatemala City routes.',
          time: '8:00 AM',
          isMe: false,
          badgeColor: widget.server.primaryColor,
        ),
        _ServerMessage(
          id: '2',
          senderName: 'Carlos Mendonza',
          senderRole: 'MOBILITY OPERATOR',
          avatarInitials: 'CM',
          message:
              'Departing Panajachel pier for Guatemala City Airport today at 2:30 PM. 3 seats remaining in the electric passenger van!',
          time: '10:20 AM',
          isMe: false,
          badgeColor: const Color(0xFF0284C7),
          product: catalog[2], // Rideshare Shuttle
        ),
        const _ServerMessage(
          id: '3',
          senderName: 'You',
          senderRole: 'MEMBER',
          avatarInitials: 'ME',
          message: 'Perfect timing, booking 1 seat for the 2:30 PM trip.',
          time: 'Just now',
          isMe: true,
          badgeColor: AppColors.primary,
        ),
      ];
    } else if (widget.server.category == ServerCategory.rentalAndGear ||
        widget.server.id == 'srv_008') {
      _messages = [
        _ServerMessage(
          id: '2',
          senderName: 'Elena & Mateo',
          senderRole: 'SUPERHOST',
          avatarInitials: 'EM',
          message:
              'Our solar eco-villa in Jaibalito is available for booking this upcoming week. High speed fiber and private kayak dock ready.',
          time: '9:30 AM',
          isMe: false,
          badgeColor: const Color(0xFF0D9488),
          product: catalog[3], // House Rental
        ),
        _ServerMessage(
          id: '3',
          senderName: 'Pan-Lake Media Collective',
          senderRole: 'EQUIPMENT DEPOT',
          avatarInitials: 'PM',
          message:
              'Sony FX6 cinema kit just returned, cleaned, and checked into Panajachel smart locker #18 ready for rent.',
          time: '10:40 AM',
          isMe: false,
          badgeColor: const Color(0xFF7C3AED),
          product: catalog[4], // Gear Rental
        ),
        const _ServerMessage(
          id: '4',
          senderName: 'You',
          senderRole: 'MEMBER',
          avatarInitials: 'ME',
          message: 'Great, checking availability for the cinema kit tomorrow!',
          time: 'Just now',
          isMe: true,
          badgeColor: AppColors.primary,
        ),
      ];
    } else {
      _messages = [
        _ServerMessage(
          id: '1',
          senderName: 'EME Core Bot',
          senderRole: 'SYSTEM BOT',
          avatarInitials: 'EB',
          message:
              'Welcome to the official ${widget.server.title} node workspace! All node updates, decentralized collaborative feeds, and ecosystem items stream here.',
          time: '9:00 AM',
          isMe: false,
          badgeColor: widget.server.primaryColor,
        ),
        _ServerMessage(
          id: '2',
          senderName: 'Alex Rivera',
          senderRole: 'NODE MAINTAINER',
          avatarInitials: 'AR',
          message:
              'Good morning everyone! We just synchronized the latest sprint deliverables. Check the Goals tab for our Q3 milestones!',
          time: '9:42 AM',
          isMe: false,
          badgeColor: const Color(0xFF059669),
        ),
        _ServerMessage(
          id: '3',
          senderName: 'Community Goods Node',
          senderRole: 'MARKETPLACE',
          avatarInitials: 'CG',
          message:
              'Special community offering shared from our sister marketplace node:',
          time: '10:15 AM',
          isMe: false,
          badgeColor: const Color(0xFFD97706),
          product: catalog[0],
        ),
        const _ServerMessage(
          id: '4',
          senderName: 'You',
          senderRole: 'MEMBER',
          avatarInitials: 'ME',
          message: 'Looking great! Excited to contribute to this node.',
          time: 'Just now',
          isMe: true,
          badgeColor: AppColors.primary,
        ),
      ];
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ServerMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderName: 'You',
          senderRole: 'MEMBER',
          avatarInitials: 'ME',
          message: text,
          time: 'Just now',
          isMe: true,
          badgeColor: AppColors.primary,
        ),
      );
      _textController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Channel Selector Bar
        _buildChannelSelector(isDark),

        // Pinned Topic Bar
        _buildPinnedTopicBanner(isDark),

        // Message Feed
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildChannelSelector(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? AppColors.darkCardBorder
                : AppColors.lightCardBorder,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _channels.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedChannelIndex;
          return ChoiceChip(
            label: Text(_channels[index]),
            selected: isSelected,
            onSelected: (val) {
              if (val) {
                setState(() => _selectedChannelIndex = index);
              }
            },
            labelStyle: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textSecondary),
            ),
            backgroundColor: isDark
                ? const Color(0xFF0F172A)
                : const Color(0xFFF1F5F9),
            selectedColor: widget.server.primaryColor,
            showCheckmark: false,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? AppColors.darkCardBorder : Colors.transparent),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          );
        },
      ),
    );
  }

  Widget _buildPinnedTopicBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.server.primaryColor.withValues(
          alpha: isDark ? 0.12 : 0.06,
        ),
        border: Border(
          bottom: BorderSide(
            color: widget.server.primaryColor.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.push_pin_rounded,
            size: 14,
            color: widget.server.primaryColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Active Node Topic: ${widget.server.category.label} ecosystem discussions & proposals',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(_ServerMessage msg, bool isDark) {
    if (msg.isMe) {
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
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: widget.server.primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          msg.message,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          msg.time,
                          style: GoogleFonts.inter(
                            fontSize: 9.5,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (msg.product != null) ...[
              ProductMessageCard(product: msg.product!, isMe: true),
            ],
          ],
        ),
      );
    }

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
              color: msg.badgeColor.withValues(alpha: isDark ? 0.3 : 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: msg.badgeColor.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                msg.avatarInitials,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: msg.badgeColor,
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
                      msg.senderName,
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
                        color: msg.badgeColor.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        msg.senderRole,
                        style: GoogleFonts.inter(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: msg.badgeColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      msg.time,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Text(
                    msg.message,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textDarkPrimary
                          : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                if (msg.product != null) ...[
                  ProductMessageCard(product: msg.product!, isMe: false),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendProduct(ProductMessageModel product) {
    setState(() {
      _messages.add(
        _ServerMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderName: 'You',
          senderRole: 'MEMBER',
          avatarInitials: 'ME',
          message:
              'Shared a ${product.typeLabel.toLowerCase()}: ${product.title}',
          time: 'Just now',
          isMe: true,
          badgeColor: AppColors.primary,
          product: product,
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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
                  hintText: 'Message ${_channels[_selectedChannelIndex]}...',
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
