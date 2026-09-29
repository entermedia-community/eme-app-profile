import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../providers/navigation_provider.dart';
import '../../theme/app_colors.dart';
import 'chat_detail_screen.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  String _searchQuery = '';

  Widget _buildAvatarFallback(ChatModel chat) {
    final initials =
        chat.avatarInitials ??
        (chat.userName.isNotEmpty
            ? chat.userName
                  .substring(0, chat.userName.length.clamp(1, 2))
                  .toUpperCase()
            : 'EM');
    return CircleAvatar(
      radius: 26,
      backgroundColor: chat.avatarColor.withValues(alpha: 0.15),
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: chat.avatarColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    final chatsAsync = ref.watch(apiChatsProvider);

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
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(apiChatsProvider);
              await ref.read(apiChatsProvider.future);
            },
            color: AppColors.primary,
            child: chatsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load chats',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(apiChatsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (chats) {
                final filtered = chats.where((c) {
                  return c.userName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      c.lastMessage.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                }).toList();

                if (filtered.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 60,
                          horizontal: 24,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _searchQuery.isEmpty
                                    ? Icons.chat_bubble_outline_rounded
                                    : Icons.search_off_rounded,
                                size: 48,
                                color: isDark
                                    ? AppColors.textDarkMuted
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No chat started'
                                    : 'No matching chats found',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'Start a chat from the EME World directory.'
                                    : 'Try searching with a different name or message.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: () {
                                    ref
                                        .read(navigationProvider.notifier)
                                        .selectTab(NavTab.emeWorld);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Go to EME World',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                            decoration:
                                                TextDecoration.underline,
                                            decorationColor: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                      leading:
                          chat.avatarUrl != null && chat.avatarUrl!.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                chat.avatarUrl!,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildAvatarFallback(chat),
                              ),
                            )
                          : _buildAvatarFallback(chat),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat.displayName,
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
                                chat.lastMessage.isEmpty
                                    ? "No message yet"
                                    : chat.lastMessage,
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
                      onTap: () async {
                        if (chat.channelId != null) {
                          Navigator.of(
                            context,
                          ).push(ChatDetailScreen.route(chat));
                          return;
                        }
                        final fromUser = AuthService.userId;
                        final toUser = chat.userName;

                        final channelId = await ChatSocketService().connectUser(
                          fromUser: fromUser!,
                          toUser: toUser,
                        );
                        final targetChat = chat.copyWith(channelId: channelId);

                        if (context.mounted) {
                          Navigator.of(
                            context,
                          ).push(ChatDetailScreen.route(targetChat));
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
