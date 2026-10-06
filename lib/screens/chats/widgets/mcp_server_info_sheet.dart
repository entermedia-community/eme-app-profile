import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';
import 'add_mcp_server_sheet.dart';

class McpServerInfoSheet extends ConsumerWidget {
  final McpServerModel server;

  const McpServerInfoSheet({super.key, required this.server});

  static Future<void> show(BuildContext context, McpServerModel server) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => McpServerInfoSheet(server: server),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;
    final serverColor = server.color;

    // Keep server data fresh
    final servers = ref.watch(mcpServersProvider);
    final freshServer = servers.firstWhere(
      (s) => s.id == server.id,
      orElse: () => server,
    );

    return Material(
      color: surfaceColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: serverColor.withValues(alpha: 0.18),
                  child: Text(
                    freshServer.displayInitials,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: serverColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              freshServer.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: serverColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'MCP',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: serverColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        freshServer.url,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: borderColor),

          // Body
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Status Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: freshServer.status == McpServerStatus.connected
                              ? AppColors.greenAccent
                              : (freshServer.status == McpServerStatus.connecting
                                  ? Colors.amber
                                  : Colors.red),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${freshServer.status.name.toUpperCase()}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Protocol: MCP 2024-11-05 • Transport: ${freshServer.transportType.displayName}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Reconnect / Refresh',
                        onPressed: () async {
                          await ref
                              .read(mcpServersProvider.notifier)
                              .reconnectServer(freshServer.id);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                if (freshServer.description.isNotEmpty) ...[
                  Text(
                    'ABOUT SERVER',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    freshServer.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tools List
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ADVERTISED TOOLS (${freshServer.tools.length})',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (freshServer.tools.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    alignment: Alignment.center,
                    child: Text(
                      'No tools currently discovered from this server.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                      ),
                    ),
                  )
                else
                  ...freshServer.tools.map((tool) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBg : AppColors.lightBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.bolt_rounded, size: 16, color: serverColor),
                              const SizedBox(width: 6),
                              Text(
                                tool.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          if (tool.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              tool.description,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 16),

                // Server Management Actions
                Text(
                  'SERVER ACTIONS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.edit_rounded, color: serverColor),
                  title: const Text('Edit Server Configuration'),
                  subtitle: const Text('Change name, URL, headers, or color'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).pop();
                    AddMcpServerSheet.show(context, server: freshServer);
                  },
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.cleaning_services_rounded, color: Colors.orange),
                  title: const Text('Clear Chat History'),
                  subtitle: const Text('Wipes messages for this conversation'),
                  onTap: () async {
                    await ref
                        .read(mcpConversationsProvider.notifier)
                        .clearConversation(freshServer.id);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat history cleared.')),
                      );
                    }
                  },
                ),

                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text('Delete MCP Server', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Removes this server and all history'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Delete Server?'),
                        content: Text('Are you sure you want to delete "${freshServer.name}"?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && context.mounted) {
                      await ref
                          .read(mcpServersProvider.notifier)
                          .deleteServer(freshServer.id);
                      if (context.mounted) {
                        Navigator.of(context).pop(); // close sheet
                        Navigator.of(context).pop(); // pop chat screen if open
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
