import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/servers_section.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => ref.read(serverProvider.notifier).refresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
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
      ),
    );
  }
}
