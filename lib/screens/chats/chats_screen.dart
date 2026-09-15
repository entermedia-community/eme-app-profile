import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/chat_model.dart';
import '../../theme/app_colors.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  final List<ChatModel> _chats = const [
    ChatModel(
      id: 'chat_1',
      userName: 'Atitlan Core Team',
      userRole: 'Community Server',
      lastMessage: 'Next micro-grant sprint starts this Friday at 10 AM UTC.',
      time: '12:45 PM',
      unreadCount: 2,
      avatarColor: Color(0xFF059669),
      isOnline: true,
      avatarInitials: 'AC',
    ),
    ChatModel(
      id: 'chat_2',
      userName: 'Elena Rostova',
      userRole: 'Impact Bank Lead',
      lastMessage: 'Passport validation pipeline is ready for deployment.',
      time: '11:20 AM',
      unreadCount: 1,
      avatarColor: Color(0xFF0284C7),
      isOnline: true,
      avatarInitials: 'ER',
    ),
    ChatModel(
      id: 'chat_3',
      userName: 'Punaryoji Vikas',
      userRole: 'Rural Bioeconomy',
      lastMessage: 'Check out the new telemetry metrics from Panchayat node.',
      time: 'Yesterday',
      unreadCount: 0,
      avatarColor: Color(0xFF64748B),
      isOnline: false,
      avatarInitials: 'PV',
    ),
    ChatModel(
      id: 'chat_4',
      userName: 'David Miller',
      userRole: 'Fullstack Dev',
      lastMessage: 'Merged the Riverpod state refactoring branch.',
      time: 'Sep 9',
      unreadCount: 0,
      avatarColor: Color(0xFF8B5CF6),
      isOnline: false,
      avatarInitials: 'DM',
    ),
    ChatModel(
      id: 'chat_5',
      userName: 'Sarah Chen',
      userRole: 'AI Researcher',
      lastMessage:
          'Inference latency reduced by 40% with the new quantization.',
      time: 'Sep 8',
      unreadCount: 0,
      avatarColor: Color(0xFFEC4899),
      isOnline: true,
      avatarInitials: 'SC',
    ),
  ];

  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    final filtered = _chats.where((c) {
      return c.userName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        // Top Header & Search
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: const InputDecoration(
              hintText: 'Search conversations...',
              prefixIcon: Icon(Icons.search_rounded),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        Divider(height: 1, color: borderColor),

        // Chat List
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: filtered.length,
            separatorBuilder: (context, index) =>
                Divider(indent: 76, height: 1, color: borderColor),
            itemBuilder: (context, index) {
              final chat = filtered[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: CircleAvatar(
                  radius: 26,
                  backgroundColor: chat.avatarColor.withValues(alpha: 0.15),
                  child: Text(
                    chat.avatarInitials ?? chat.userName.substring(0, 2),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: chat.avatarColor,
                    ),
                  ),
                ),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        chat.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: chat.unreadCount > 0
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      chat.time,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: chat.unreadCount > 0
                            ? AppColors.primary
                            : (isDark
                                  ? AppColors.textDarkMuted
                                  : AppColors.textMuted),
                        fontWeight: chat.unreadCount > 0
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textSecondary,
                            fontWeight: chat.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${chat.unreadCount}',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                onTap: () {
                  Navigator.of(context).push(ChatDetailScreen.route(chat));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
