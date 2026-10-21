import 'package:flutter/material.dart';
import '../files/files_section.dart';
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

          SizedBox(height: 20),

          // Section 3: Files
          FilesSection(),

          SizedBox(height: 40),
        ],
      ),
    );
  }
}
