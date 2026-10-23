import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/profile_app_bar_button.dart';
import '../../chats/chat_detail_screen.dart';

/// The signed-in user's chat with themselves, e.g. "EME Christopher".
ChatModel selfChatModel(
  EmUser user,
  ProfileModel profile, {
  String? channelId,
}) {
  return ChatModel(
    channelId: channelId,
    username: user.username,
    displayName: emeProfileLabel(user, profile),
    lastMessage: '',
    time: '',
    avatarColor: AppColors.primary,
    avatarInitials: user.avatarInitials,
    avatarUrl: user.assetportrait,
  );
}

/// Text area on the EME profile page that sends a message to the user's own
/// chat, then opens that chat.
class SelfChatComposer extends ConsumerStatefulWidget {
  const SelfChatComposer({super.key});

  @override
  ConsumerState<SelfChatComposer> createState() => _SelfChatComposerState();
}

class _SelfChatComposerState extends ConsumerState<SelfChatComposer> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send(EmUser user, ProfileModel profile) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);

    try {
      final channelId = await ChatSocketService().connectUser(
        fromUser: user.username,
        toUser: user.username,
      );
      await ChatSocketService().connect(channel: channelId);
      // sendMessage drops messages silently when the socket is down, so
      // fail visibly instead.
      if (!ChatSocketService().isConnected) {
        throw StateError('Chat socket is not connected');
      }
      ChatSocketService().sendMessage(
        message: text,
        user: user.username,
        channel: channelId,
      );
      _controller.clear();
      if (mounted) {
        Navigator.of(context).push(
          ChatDetailScreen.route(
            selfChatModel(user, profile, channelId: channelId),
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Error sending self chat message: $e');
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'Error sending message in SelfChatComposer',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message not sent: could not connect to chat'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final profile = ref.watch(profileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canSend =
        user != null && !_sending && _controller.text.trim().isNotEmpty;

    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated;
    final headingName = (user?.firstname?.trim().isNotEmpty ?? false)
        ? user!.firstname!.trim()
        : (profile.name.trim().isNotEmpty
              ? profile.name.trim().split(' ').first
              : 'EME');
    final heading = isAuthenticated
        ? 'Chat with your EME'
        : 'Message EME $headingName';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            identifier: 'profile_chat_input',
            child: TextField(
              controller: _controller,
              enabled: user != null,
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Write a message...',
                hintStyle: GoogleFonts.inter(fontSize: 13.5),
              ),
              style: GoogleFonts.inter(fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: Semantics(
              identifier: 'profile_chat_send',
              child: ElevatedButton.icon(
                onPressed: canSend ? () => _send(user, profile) : null,
                icon: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  'Send',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.greenAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
