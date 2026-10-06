import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import 'chat_detail_screen.dart';
import 'mcp_chat_detail_screen.dart';
import 'widgets/add_mcp_server_sheet.dart';
import 'widgets/mcp_server_info_sheet.dart';

enum ChatFilter { all, users, mcp }

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  String _searchQuery = '';
  ChatFilter _activeFilter = ChatFilter.all;

  Widget _buildAvatarFallback(UnifiedChatItem item) {
    if (item.isMcp) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: item.avatarColor.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: item.avatarColor.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(Icons.hub_rounded, color: item.avatarColor, size: 24),
        ),
      );
    }

    final chat = item.userChat!;
    final initials =
        chat.avatarInitials ??
        (chat.username.isNotEmpty
            ? chat.username
                  .substring(0, chat.username.length.clamp(1, 2))
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

  void _showMcpServerActions(BuildContext context, McpServerModel server) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: server.color.withValues(alpha: 0.2),
                      child: Text(
                        server.displayInitials,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          color: server.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        server.name,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Reconnect & Refresh Tools'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(mcpServersProvider.notifier)
                      .reconnectServer(server.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                title: const Text('Edit Server Configuration'),
                onTap: () {
                  Navigator.pop(ctx);
                  AddMcpServerSheet.show(context, server: server);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.info_outline_rounded,
                  color: Colors.purple,
                ),
                title: const Text('View Capabilities & Tools'),
                onTap: () {
                  Navigator.pop(ctx);
                  McpServerInfoSheet.show(context, server);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                title: const Text(
                  'Delete Server',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(mcpServersProvider.notifier).deleteServer(server.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    final chatsAsync = ref.watch(unifiedChatsProvider);
    final mcpServers = ref.watch(mcpServersProvider);

    return Column(
      children: [
        // Top Search Bar & Add MCP Action
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: GoogleFonts.inter(fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Add Remote MCP Server',
                child: ElevatedButton.icon(
                  onPressed: () => AddMcpServerSheet.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('MCP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Filter Tabs Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All',
                filter: ChatFilter.all,
                count: null,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Direct Chats',
                filter: ChatFilter.users,
                count: null,
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'MCP Servers',
                filter: ChatFilter.mcp,
                count: mcpServers.length,
                isDark: isDark,
                accentColor: const Color(0xFF6366F1),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),
        Divider(height: 1, color: borderColor),

        // Chat & MCP List
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
              data: (allItems) {
                // 1. Filter by category
                var filtered = allItems.where((item) {
                  if (_activeFilter == ChatFilter.users) return item.isUser;
                  if (_activeFilter == ChatFilter.mcp) return item.isMcp;
                  return true;
                }).toList();

                // 2. Filter by search query
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((item) {
                    final query = _searchQuery.toLowerCase();
                    return item.displayName.toLowerCase().contains(query) ||
                        item.lastMessage.toLowerCase().contains(query) ||
                        item.subtitle.toLowerCase().contains(query);
                  }).toList();
                }

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
                                _activeFilter == ChatFilter.mcp
                                    ? Icons.hub_outlined
                                    : (_searchQuery.isEmpty
                                          ? Icons.chat_bubble_outline_rounded
                                          : Icons.search_off_rounded),
                                size: 48,
                                color: isDark
                                    ? AppColors.textDarkMuted
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _activeFilter == ChatFilter.mcp
                                    ? 'No MCP Servers Configured'
                                    : (_searchQuery.isEmpty
                                          ? 'No conversations yet'
                                          : 'No matching chats found'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _activeFilter == ChatFilter.mcp
                                    ? 'Add a remote Model Context Protocol server to execute tools and prompts.'
                                    : (_searchQuery.isEmpty
                                          ? 'Start a chat from EME World or add a remote MCP Server.'
                                          : 'Try searching with a different name or message.'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_activeFilter == ChatFilter.mcp ||
                                  _searchQuery.isEmpty) ...[
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      AddMcpServerSheet.show(context),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Add Remote MCP Server'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
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
                    final item = filtered[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      onLongPress: item.isMcp
                          ? () =>
                                _showMcpServerActions(context, item.mcpServer!)
                          : null,
                      leading: Stack(
                        children: [
                          item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    item.avatarUrl!,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildAvatarFallback(item),
                                  ),
                                )
                              : _buildAvatarFallback(item),
                          if (item.isMcp)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: item.isOnline
                                      ? AppColors.greenAccent
                                      : (item.mcpServer?.status ==
                                                McpServerStatus.connecting
                                            ? Colors.amber
                                            : Colors.red),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.darkSurface
                                        : Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    item.displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: item.unreadCount > 0
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                if (item.isMcp) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.avatarColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      'MCP',
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: item.avatarColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.time,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: item.unreadCount > 0
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.textDarkMuted
                                        : AppColors.textMuted),
                              fontWeight: item.unreadCount > 0
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
                            if (item.isMcp &&
                                item.mcpServer!.tools.isNotEmpty) ...[
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkBg
                                      : AppColors.tagBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '⚡ ${item.mcpServer!.tools.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textDarkMuted
                                        : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                item.lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textSecondary,
                                  fontWeight: item.unreadCount > 0
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                            if (item.unreadCount > 0)
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
                                  '${item.unreadCount}',
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
                        if (item.isMcp) {
                          Navigator.of(context).push(
                            McpChatDetailScreen.route(item.mcpConversation!),
                          );
                          return;
                        }

                        final chat = item.userChat!;
                        if (chat.channelId != null) {
                          Navigator.of(
                            context,
                          ).push(ChatDetailScreen.route(chat));
                          return;
                        }

                        final fromUser = AuthService.userId;
                        final toUser = chat.username;

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

  Widget _buildFilterChip({
    required String label,
    required ChatFilter filter,
    required int? count,
    required bool isDark,
    Color? accentColor,
  }) {
    final isSelected = _activeFilter == filter;
    final color = accentColor ?? AppColors.primary;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (count != null) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isDark ? Colors.white12 : Colors.black12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _activeFilter = filter),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
      ),
      selectedColor: color,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? color
              : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
        ),
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
