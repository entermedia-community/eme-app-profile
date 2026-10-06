import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import 'widgets/mcp_server_info_sheet.dart';
import 'widgets/mcp_tool_invocation_sheet.dart';

class McpChatDetailScreen extends ConsumerStatefulWidget {
  final McpConversationModel conversation;

  const McpChatDetailScreen({super.key, required this.conversation});

  static Route<void> route(McpConversationModel conversation) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          McpChatDetailScreen(conversation: conversation),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;
        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  @override
  ConsumerState<McpChatDetailScreen> createState() => _McpChatDetailScreenState();
}

class _McpChatDetailScreenState extends ConsumerState<McpChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSearchOpen = false;
  String _searchQuery = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() => _isSending = true);

    try {
      await ref.read(mcpConversationsProvider.notifier).sendMessage(
            serverId: widget.conversation.serverId,
            text: text,
          );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _openToolSheet(McpToolDefinition tool, McpServerModel server) {
    McpToolInvocationSheet.show(
      context,
      server: server,
      tool: tool,
      onExecute: (t, args) {
        _scrollToBottom();
      },
    );
  }

  void _showToolsMenu(McpServerModel initialServer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        var currentServer = initialServer;
        bool isReloading = false;
        String? reloadError;

        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final serverColor = currentServer.color;

            Future<void> reload() async {
              setModalState(() {
                isReloading = true;
                reloadError = null;
              });
              try {
                final tools = await ref
                    .read(mcpServersProvider.notifier)
                    .reloadTools(currentServer.id);
                final freshServers = ref.read(mcpServersProvider);
                final fresh = freshServers.firstWhere(
                  (s) => s.id == currentServer.id,
                  orElse: () => currentServer.copyWith(tools: tools),
                );
                setModalState(() {
                  currentServer = fresh;
                  isReloading = false;
                  if (tools.isEmpty) {
                    reloadError = 'Server returned 0 tools via tools/list';
                  }
                });
              } catch (e) {
                setModalState(() {
                  isReloading = false;
                  reloadError = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: serverColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Available Tools (${currentServer.tools.length})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: isReloading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh_rounded, size: 20),
                            tooltip: 'Reload Tools (tools/list)',
                            onPressed: isReloading ? null : reload,
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (currentServer.tools.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.handyman_outlined,
                              size: 40,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No tools advertised by server.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                              ),
                            ),
                            if (reloadError != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                reloadError!,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: isReloading ? null : reload,
                              icon: isReloading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 18),
                              label: Text(
                                isReloading
                                    ? 'Fetching tools/list...'
                                    : 'Try Reload (tools/list)',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: serverColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: currentServer.tools.map((t) {
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: serverColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.bolt_rounded, color: serverColor, size: 20),
                            ),
                            title: Text(t.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              t.description.isNotEmpty ? t.description : 'No description provided',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              Navigator.pop(ctx);
                              _openToolSheet(t, currentServer);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    // Watch live conversation & server state
    final conversations = ref.watch(mcpConversationsProvider);
    final activeConv = conversations.firstWhere(
      (c) => c.serverId == widget.conversation.serverId,
      orElse: () => widget.conversation,
    );
    final server = activeConv.server;
    final serverColor = server.color;

    final messages = activeConv.messages;
    final displayedMessages = _searchQuery.isEmpty
        ? messages
        : messages
            .where((m) => m.content.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: surfaceColor,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back to Chats',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: InkWell(
          onTap: () => McpServerInfoSheet.show(context, server),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor: serverColor.withValues(alpha: 0.2),
                      child: Text(
                        server.displayInitials,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: serverColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: server.status == McpServerStatus.connected
                              ? AppColors.greenAccent
                              : (server.status == McpServerStatus.connecting
                                  ? Colors.amber
                                  : Colors.red),
                          shape: BoxShape.circle,
                          border: Border.all(color: surfaceColor, width: 2),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              server.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: serverColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'MCP',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: serverColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        server.status == McpServerStatus.connected
                            ? '${server.tools.length} Tools • Active'
                            : (server.status == McpServerStatus.connecting
                                ? 'Connecting...'
                                : 'Disconnected'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: server.status == McpServerStatus.connected
                              ? AppColors.greenAccent
                              : (isDark ? AppColors.textDarkMuted : AppColors.textMuted),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchOpen ? Icons.search_off_rounded : Icons.search_rounded,
              color: _isSearchOpen ? serverColor : null,
              size: 22,
            ),
            tooltip: 'Search Conversation',
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
          IconButton(
            icon: const Icon(Icons.bolt_rounded, size: 24),
            tooltip: 'Available Tools',
            onPressed: () => _showToolsMenu(server),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 22),
            tooltip: 'Server Info & Actions',
            onPressed: () => McpServerInfoSheet.show(context, server),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // In-Chat Search Bar
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _isSearchOpen
                ? Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      border: Border(bottom: BorderSide(color: borderColor, width: 1)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search in MCP conversation...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
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
                  )
                : const SizedBox.shrink(),
          ),

          // Tools Quick Tray
          if (server.tools.isNotEmpty) ...[
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(bottom: BorderSide(color: borderColor, width: 0.8)),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: server.tools.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final tool = server.tools[index];
                  return ActionChip(
                    avatar: Icon(Icons.bolt_rounded, size: 14, color: serverColor),
                    label: Text(
                      tool.name,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                      ),
                    ),
                    backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: borderColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => _openToolSheet(tool, server),
                  );
                },
              ),
            ),
          ],

          // Messages List
          Expanded(
            child: displayedMessages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hub_rounded,
                          size: 48,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Type a prompt or tap a tool above to get started.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
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
                      final msg = displayedMessages[index];
                      return _buildMessageItem(msg, server, isDark);
                    },
                  ),
          ),

          // Sending loading bar
          if (_isSending)
            LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(serverColor),
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
              border: Border(top: BorderSide(color: borderColor, width: 1)),
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
                  icon: const Icon(Icons.bolt_rounded, size: 24),
                  color: serverColor,
                  tooltip: 'Execute Tool',
                  onPressed: () => _showToolsMenu(server),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Prompt MCP server or /tool <name>...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  onPressed: _isSending ? null : _sendMessage,
                  icon: const Icon(Icons.send_rounded, size: 19),
                  style: IconButton.styleFrom(
                    backgroundColor: serverColor,
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

  Widget _buildMessageItem(McpChatMessage message, McpServerModel server, bool isDark) {
    switch (message.role) {
      case McpMessageRole.system:
        return _buildSystemNotice(message, server, isDark);
      case McpMessageRole.toolCall:
        return _buildToolCallCard(message, server, isDark);
      case McpMessageRole.toolResult:
        return _buildToolResultCard(message, server, isDark);
      case McpMessageRole.assistant:
        return _buildAssistantBubble(message, server, isDark);
      case McpMessageRole.error:
        return _buildErrorBubble(message, isDark);
      case McpMessageRole.user:
        return _buildUserBubble(message, isDark);
    }
  }

  Widget _buildUserBubble(McpChatMessage message, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content,
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(McpChatMessage message, McpServerModel server, bool isDark) {
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
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
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemNotice(McpChatMessage message, McpServerModel server, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: server.color.withValues(alpha: isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: server.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: server.color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message.content,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCallCard(McpChatMessage message, McpServerModel server, bool isDark) {
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 32),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terminal_rounded, size: 16, color: server.color),
              const SizedBox(width: 6),
              Text(
                'TOOL INVOCATION: ',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: server.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  message.toolName ?? 'tool',
                  style: GoogleFonts.firaCode(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: server.color,
                  ),
                ),
              ),
            ],
          ),
          if (message.toolArguments != null && message.toolArguments!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.lightBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message.formattedArguments ?? '{}',
                style: GoogleFonts.firaCode(fontSize: 11.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolResultCard(McpChatMessage message, McpServerModel server, bool isDark) {
    final isSuccess = !message.isError;
    final formatted = message.formattedResult ?? message.content;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSuccess
              ? AppColors.greenAccent.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                    size: 16,
                    color: isSuccess ? AppColors.greenAccent : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    message.toolName != null ? 'Result: ${message.toolName}' : 'Tool Output',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSuccess
                          ? (isDark ? Colors.greenAccent : AppColors.greenButtonText)
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (message.latencyMs != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBg : AppColors.tagBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${message.latencyMs}ms',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    tooltip: 'Copy output',
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: formatted));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied result to clipboard'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              formatted,
              style: GoogleFonts.firaCode(
                fontSize: 12,
                color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBubble(McpChatMessage message, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.content,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
}
