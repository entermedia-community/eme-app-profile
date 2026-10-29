import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../entity_assets/entity_asset_list.dart';

/// Digital legacy area of the EME profile page: the signed-in user's entity
/// assets.
class FilesSection extends ConsumerWidget {
  const FilesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.username;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Digital Legacy',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        EntityAssetList(userId: userId),
      ],
    );
  }
}
