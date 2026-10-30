import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../server/tabs/server_chat_tab.dart';

/// Side drawer with the past sessions (channels) of one chat, most recently
/// refreshed first, and a button to start a new one.
/// Give exactly one of [toUser], [serverId] or [collectionId].
class SessionHistoryScreen extends ConsumerStatefulWidget {
  const SessionHistoryScreen({
    super.key,
    this.toUser,
    this.serverId,
    this.collectionId,
    this.baseUrl,
    this.currentChannelId,
    required this.onOpen,
  });

  final String? toUser;
  final String? serverId;
  final String? collectionId;
  final String? baseUrl;

  /// The session being viewed now, marked in the list.
  final String? currentChannelId;

  /// Called, after the drawer closed, with the session to open (a tapped one
  /// or a newly started one).
  final void Function(ChatSession session) onOpen;

  /// Slides the drawer in from the right.
  static Future<void> show(
    BuildContext context, {
    String? toUser,
    String? serverId,
    String? collectionId,
    String? baseUrl,
    String? currentChannelId,
    required void Function(ChatSession session) onOpen,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close Session History',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (_, _, _) => Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: (MediaQuery.sizeOf(context).width * 0.85).clamp(0, 380),
          child: SessionHistoryScreen(
            toUser: toUser,
            serverId: serverId,
            collectionId: collectionId,
            baseUrl: baseUrl,
            currentChannelId: currentChannelId,
            onOpen: onOpen,
          ),
        ),
      ),
      transitionBuilder: (_, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }

  @override
  ConsumerState<SessionHistoryScreen> createState() =>
      _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends ConsumerState<SessionHistoryScreen> {
  late Future<List<ChatSession>> _sessions = _load();
  bool _starting = false;

  Future<List<ChatSession>> _load() => ref
      .read(apiServiceProvider)
      .fetchChatSessions(
        toUser: widget.toUser,
        serverId: widget.serverId,
        collectionId: widget.collectionId,
        baseUrl: widget.baseUrl,
      );

  void _open(ChatSession session) {
    Navigator.of(context).pop();
    widget.onOpen(session);
  }

  Future<void> _startNew() async {
    setState(() => _starting = true);
    try {
      final session = await ref
          .read(apiServiceProvider)
          .createChatSession(
            toUser: widget.toUser,
            serverId: widget.serverId,
            collectionId: widget.collectionId,
            baseUrl: widget.baseUrl,
          );
      if (mounted) _open(session);
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Failed to start a new chat session',
      );
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not start a new session: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;

    return Drawer(
      shape: const RoundedRectangleBorder(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            'Session History',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
          actions: [
            Semantics(
              identifier: 'session_history_close',
              child: IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Semantics(
                identifier: 'session_history_new',
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _starting ? null : _startNew,
                    icon: _starting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New session'),
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: borderColor),
            Expanded(child: _buildList(isDark, borderColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(bool isDark, Color borderColor) {
    return FutureBuilder<List<ChatSession>>(
      future: _sessions,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (snapshot.hasError) {
          return Center(
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
                    'Failed to load session history',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    identifier: 'session_history_retry',
                    child: ElevatedButton(
                      onPressed: () => setState(() => _sessions = _load()),
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final sessions = snapshot.data!;
        if (sessions.isEmpty) {
          return Center(
            child: Text(
              'No earlier sessions yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
          );
        }
        return Semantics(
          identifier: 'session_history_list',
          child: ListView.separated(
            itemCount: sessions.length,
            separatorBuilder: (_, _) => Divider(height: 1, color: borderColor),
            itemBuilder: (context, index) {
              final session = sessions[index];
              final isCurrent = session.channelId == widget.currentChannelId;
              return Semantics(
                identifier: 'session_history_item_${session.channelId}',
                child: ListTile(
                  leading: Icon(
                    isCurrent
                        ? Icons.chat_bubble_rounded
                        : Icons.chat_bubble_outline_rounded,
                    color: isCurrent ? AppColors.primary : null,
                  ),
                  title: Text(
                    _formatDate(session.refreshDate) +
                        (isCurrent ? ' · current' : ''),
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: session.lastMessage.isEmpty
                      ? null
                      : Text(
                          session.lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                  onTap: () => _open(session),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Session';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} · $hour:$minute $period';
  }
}

/// An earlier session of a server or project chat, opened read-write from
/// Session History.
class SessionChatScreen extends StatelessWidget {
  const SessionChatScreen({
    super.key,
    required this.server,
    required this.session,
    this.projectCollectionId,
  });

  final ServerModel server;
  final ChatSession session;
  final String? projectCollectionId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          server.name,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      body: ServerChatTab(
        key: ValueKey('session_${session.channelId}'),
        server: server,
        projectCollectionId: projectCollectionId,
        initialChannelId: session.channelId,
      ),
    );
  }
}
