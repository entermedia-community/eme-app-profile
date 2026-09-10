import 'package:flutter/material.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/servers_section.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          // Section 1: Profile Overview Card
          ProfileHeaderCard(),

          SizedBox(height: 28),

          // Section 2: Collective Intelligence Servers (Filters, Grid, Subtitle)
          ServersSection(),

          SizedBox(height: 80), // Extra bottom padding for FAB and bottom nav
        ],
      ),
    );
  }
}
