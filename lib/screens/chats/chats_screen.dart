import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import '../../widgets/search/unified_search_screen.dart';
import '../project/project_screen.dart';
import '../event/event_screen.dart';
import '../server/server_detail_screen.dart';
import 'chat_detail_screen.dart';

// TODO(mcp): hidden for now.
// import 'mcp_chat_detail_screen.dart';
// import 'widgets/add_mcp_server_sheet.dart';
// import 'widgets/mcp_server_info_sheet.dart';

enum ChatFilter {
  all,
  users,
  projects,
  servers,
  events;

  // TODO(mcp): hidden for now.
  // mcp;

  String get label {
    switch (this) {
      case ChatFilter.all:
        return 'All';
      case ChatFilter.users:
        return 'People';
      case ChatFilter.projects:
        return 'Projects';
      case ChatFilter.servers:
        return 'Servers';
      case ChatFilter.events:
        return 'Events';
      // TODO(mcp): case ChatFilter.mcp: return 'MCP';
    }
  }

  /// The Search result type matching this filter.
  SearchResultType get searchType {
    switch (this) {
      case ChatFilter.users:
        return SearchResultType.people;
      case ChatFilter.projects:
        return SearchResultType.projects;
      case ChatFilter.servers:
        return SearchResultType.servers;
      case ChatFilter.events:
        return SearchResultType.events;
      case ChatFilter.all:
        return SearchResultType.all;
    }
  }
}

/// The chat list, limited to one kind of conversation (a main-shell tab).
class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key, required this.filter});

  final ChatFilter filter;

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  ChatFilter get _activeFilter => widget.filter;

  Widget _buildAvatarFallback(UnifiedChatItem item) {
    // TODO(mcp): hidden for now.
    // if (item.isMcp) {
    //   return Container(
    //     width: 52,
    //     height: 52,
    //     decoration: BoxDecoration(
    //       color: item.avatarColor.withValues(alpha: 0.15),
    //       shape: BoxShape.circle,
    //       border: Border.all(
    //         color: item.avatarColor.withValues(alpha: 0.35),
    //         width: 1.5,
    //       ),
    //     ),
    //     child: Center(
    //       child: Icon(Icons.hub_rounded, color: item.avatarColor, size: 24),
    //     ),
    //   );
    // }

    if (item.isProject || item.isEvent) {
      final logo = item.avatarUrl;
      return CircleAvatar(
        radius: 26,
        backgroundColor: item.avatarColor.withValues(alpha: 0.15),
        foregroundImage: logo != null && logo.isNotEmpty
            ? NetworkImage(logo)
            : null,
        child: Text(
          item.avatarInitials,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: item.avatarColor,
          ),
        ),
      );
    }

    if (item.isServer) {
      return CircleAvatar(
        radius: 26,
        backgroundColor: item.avatarColor.withValues(alpha: 0.15),
        child: Text(
          item.avatarInitials,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: item.avatarColor,
          ),
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

  // TODO(mcp): hidden for now.
  // void _showMcpServerActions(BuildContext context, McpServerModel server) {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     builder: (ctx) {
  //       final isDark = Theme.of(context).brightness == Brightness.dark;
  //       return Container(
  //         decoration: BoxDecoration(
  //           color: isDark ? AppColors.darkSurface : Colors.white,
  //           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
  //         ),
  //         padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Padding(
  //               padding: const EdgeInsets.symmetric(horizontal: 8),
  //               child: Row(
  //                 children: [
  //                   CircleAvatar(
  //                     radius: 16,
  //                     backgroundColor: server.color.withValues(alpha: 0.2),
  //                     child: Text(
  //                       server.displayInitials,
  //                       style: GoogleFonts.plusJakartaSans(
  //                         fontWeight: FontWeight.w800,
  //                         fontSize: 10,
  //                         color: server.color,
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(width: 10),
  //                   Expanded(
  //                     child: Text(
  //                       server.name,
  //                       style: GoogleFonts.plusJakartaSans(
  //                         fontWeight: FontWeight.w700,
  //                         fontSize: 15,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             const SizedBox(height: 12),
  //             ListTile(
  //               leading: const Icon(
  //                 Icons.refresh_rounded,
  //                 color: AppColors.primary,
  //               ),
  //               title: const Text('Reconnect & Refresh Tools'),
  //               onTap: () {
  //                 Navigator.pop(ctx);
  //                 ref
  //                     .read(mcpServersProvider.notifier)
  //                     .reconnectServer(server.id);
  //               },
  //             ),
  //             ListTile(
  //               leading: const Icon(Icons.edit_rounded, color: Colors.blue),
  //               title: const Text('Edit Server Configuration'),
  //               onTap: () {
  //                 Navigator.pop(ctx);
  //                 AddMcpServerSheet.show(context, server: server);
  //               },
  //             ),
  //             ListTile(
  //               leading: const Icon(
  //                 Icons.info_outline_rounded,
  //                 color: Colors.purple,
  //               ),
  //               title: const Text('View Capabilities & Tools'),
  //               onTap: () {
  //                 Navigator.pop(ctx);
  //                 McpServerInfoSheet.show(context, server);
  //               },
  //             ),
  //             ListTile(
  //               leading: const Icon(
  //                 Icons.delete_outline_rounded,
  //                 color: Colors.red,
  //               ),
  //               title: const Text(
  //                 'Delete Server',
  //                 style: TextStyle(color: Colors.red),
  //               ),
  //               onTap: () {
  //                 Navigator.pop(ctx);
  //                 ref.read(mcpServersProvider.notifier).deleteServer(server.id);
  //               },
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    final chatsAsync = ref.watch(unifiedChatsProvider);
    return Column(
      children: [
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
                final filtered = allItems.where((item) {
                  // TODO(events): events are hidden for now.
                  if (item.isEvent) return false;
                  if (_activeFilter == ChatFilter.users) {
                    return item.isUser;
                  }
                  if (_activeFilter == ChatFilter.projects) {
                    return item.isProject;
                  }
                  if (_activeFilter == ChatFilter.servers) {
                    return item.isServer;
                  }
                  if (_activeFilter == ChatFilter.events) {
                    return item.isEvent;
                  }
                  // TODO(mcp): MCP conversations are hidden for now.
                  if (item.isMcp) return false;
                  return true;
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
                                _activeFilter == ChatFilter.projects
                                    ? Icons.folder_special_outlined
                                    : _activeFilter == ChatFilter.events
                                    ? Icons.event_outlined
                                    : (_activeFilter == ChatFilter.servers
                                          ? Icons.dns_outlined
                                          : Icons.chat_bubble_outline_rounded),
                                size: 48,
                                color: isDark
                                    ? AppColors.textDarkMuted
                                    : AppColors.textMuted,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _activeFilter == ChatFilter.projects
                                    ? 'No projects yet'
                                    : _activeFilter == ChatFilter.events
                                    ? 'No events yet'
                                    : (_activeFilter == ChatFilter.servers
                                          ? 'No servers yet'
                                          : 'No conversations yet'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _activeFilter == ChatFilter.projects
                                    ? 'Find or join projects in EME Search.'
                                    : _activeFilter == ChatFilter.events
                                    ? 'Mark yourself Interested or Going on an event in EME Search, or create one from your profile.'
                                    : _activeFilter == ChatFilter.servers
                                    ? 'Find and join EME Servers in Search.'
                                    : _activeFilter == ChatFilter.users
                                    ? 'Start a chat with someone in EME Search.'
                                    : 'Start a chat from Search.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // TODO(mcp): Add Remote MCP Server hidden for now.
                              // if (_activeFilter == ChatFilter.mcp)
                              //   ElevatedButton.icon(
                              //     onPressed: () =>
                              //         AddMcpServerSheet.show(context),
                              //     icon: const Icon(
                              //       Icons.add_rounded,
                              //       size: 18,
                              //     ),
                              //     label: const Text('Add Remote MCP Server'),
                              //     style: ElevatedButton.styleFrom(
                              //       backgroundColor: const Color(0xFF6366F1),
                              //       foregroundColor: Colors.white,
                              //       padding: const EdgeInsets.symmetric(
                              //         horizontal: 16,
                              //         vertical: 10,
                              //       ),
                              //     ),
                              //   )
                              // else
                              ElevatedButton.icon(
                                onPressed: () => UnifiedSearchScreen.show(
                                  context,
                                  initialType: _activeFilter.searchType,
                                ),
                                icon: const Icon(
                                  Icons.search_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  _activeFilter == ChatFilter.all
                                      ? 'Search EME'
                                      : 'Search for ${_activeFilter.label}',
                                ),
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
                      // TODO(mcp): long-press actions hidden for now.
                      // onLongPress: item.isMcp
                      //     ? () =>
                      //           _showMcpServerActions(context, item.mcpServer!)
                      //     : null,
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
                          // TODO(mcp): hidden for now.
                          // if (item.isMcp)
                          //   Positioned(
                          //     right: 0,
                          //     bottom: 0,
                          //     child: Container(
                          //       width: 14,
                          //       height: 14,
                          //       decoration: BoxDecoration(
                          //         color: item.isOnline
                          //             ? AppColors.greenAccent
                          //             : (item.mcpServer?.status ==
                          //                       McpServerStatus.connecting
                          //                   ? Colors.amber
                          //                   : Colors.red),
                          //         shape: BoxShape.circle,
                          //         border: Border.all(
                          //           color: isDark
                          //               ? AppColors.darkSurface
                          //               : Colors.white,
                          //           width: 2.5,
                          //         ),
                          //       ),
                          //     ),
                          //   ),
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
                                if (item.isProject) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF3B82F6,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      'PROJECT',
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                ],
                                if (item.isEvent) ...[
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
                                      'EVENT',
                                      style: GoogleFonts.inter(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: item.avatarColor,
                                      ),
                                    ),
                                  ),
                                ],
                                // TODO(mcp): hidden for now.
                                // if (item.isMcp) ...[
                                //   const SizedBox(width: 6),
                                //   Container(
                                //     padding: const EdgeInsets.symmetric(
                                //       horizontal: 6,
                                //       vertical: 1.5,
                                //     ),
                                //     decoration: BoxDecoration(
                                //       color: item.avatarColor.withValues(
                                //         alpha: 0.15,
                                //       ),
                                //       borderRadius: BorderRadius.circular(5),
                                //     ),
                                //     child: Text(
                                //       'MCP',
                                //       style: GoogleFonts.inter(
                                //         fontSize: 9.5,
                                //         fontWeight: FontWeight.w800,
                                //         color: item.avatarColor,
                                //       ),
                                //     ),
                                //   ),
                                // ],
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
                            // TODO(mcp): hidden for now.
                            // if (item.isMcp &&
                            //     item.mcpServer!.tools.isNotEmpty) ...[
                            //   Container(
                            //     margin: const EdgeInsets.only(right: 6),
                            //     padding: const EdgeInsets.symmetric(
                            //       horizontal: 5,
                            //       vertical: 1,
                            //     ),
                            //     decoration: BoxDecoration(
                            //       color: isDark
                            //           ? AppColors.darkBg
                            //           : AppColors.tagBg,
                            //       borderRadius: BorderRadius.circular(4),
                            //     ),
                            //     child: Text(
                            //       '⚡ ${item.mcpServer!.tools.length}',
                            //       style: GoogleFonts.inter(
                            //         fontSize: 10,
                            //         fontWeight: FontWeight.w600,
                            //         color: isDark
                            //             ? AppColors.textDarkMuted
                            //             : AppColors.textMuted,
                            //       ),
                            //     ),
                            //   ),
                            // ],
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
                        if (item.isProject) {
                          final collection = item.projectCollection;
                          Navigator.of(context).push(
                            collection != null
                                ? ProjectScreen.routeForCollection(collection)
                                : ProjectScreen.route(server: item.emeServer!),
                          );
                          return;
                        }
                        if (item.isEvent) {
                          Navigator.of(
                            context,
                          ).push(EventScreen.route(item.event!));
                          return;
                        }
                        if (item.isServer) {
                          Navigator.of(
                            context,
                          ).push(ServerDetailScreen.route(item.emeServer!));
                          return;
                        }
                        // TODO(mcp): hidden for now.
                        // if (item.isMcp) {
                        //   Navigator.of(context).push(
                        //     McpChatDetailScreen.route(item.mcpConversation!),
                        //   );
                        //   return;
                        // }

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
}
