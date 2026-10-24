import 'package:flutter/material.dart';
import '../../widgets/files/files_section.dart';
import '../event/create_event_screen.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/self_chat_composer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Profile Overview Card
          ProfileHeaderCard(),

          SizedBox(height: 16),

          // Section 2: Message your own EME chat
          SelfChatComposer(),

          SizedBox(height: 12),

          // Section 3: Create an event
          _CreateEventTile(),

          SizedBox(height: 20),

          // Section 4: Files
          FilesSection(),

          SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _CreateEventTile extends StatelessWidget {
  const _CreateEventTile();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'profile_create_event',
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.event_rounded, color: Color(0xFFEA580C)),
          title: const Text('Create an event'),
          subtitle: const Text('Invite people to something you are hosting'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => CreateEventScreen.open(context),
        ),
      ),
    );
  }
}
