import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile/widgets/self_chat_composer.dart';
import 'chat_detail_screen.dart';

/// "My EME" tab: the signed-in user's chat with themselves.
class MyEmeScreen extends ConsumerWidget {
  const MyEmeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final profile = ref.watch(profileProvider);
    if (user == null) {
      return const Center(child: Text('Sign in to chat with your EME.'));
    }
    return ChatDetailScreen(
      // Rebuild if the account changes.
      key: ValueKey(user.username),
      chat: selfChatModel(user, profile),
      embedded: true,
    );
  }
}
