import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import 'entity_asset_viewer_screen.dart';

/// An entity asset's name, thumbnail, tags and upload date. The thumbnail
/// opens the file. Pull down to reload it from [listKey]'s asset list.
class EntityAssetDetailScreen extends ConsumerWidget {
  final EntityAssetModel asset;
  final EntityAssetsKey listKey;

  const EntityAssetDetailScreen({
    super.key,
    required this.asset,
    required this.listKey,
  });

  static Route<void> route(EntityAssetModel asset, EntityAssetsKey listKey) =>
      MaterialPageRoute<void>(
        builder: (_) => EntityAssetDetailScreen(asset: asset, listKey: listKey),
      );

  static String _date(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref
        .watch(entityAssetsProvider(listKey))
        .valueOrNull
        ?.where((a) => a.id == this.asset.id)
        .firstOrNull;
    final asset = current ?? this.asset;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textDarkMuted : AppColors.textMuted;
    final upload = asset.uploadDate ?? asset.date;
    final canOpen = asset.mediaUrl != null;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'entity_asset_detail_back_button',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Entity Asset'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(entityAssetsProvider(listKey));
          try {
            await ref.read(entityAssetsProvider(listKey).future);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Could not refresh: $e')));
            }
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              asset.name.isEmpty ? asset.id : asset.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              identifier: 'entity_asset_thumbnail',
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: canOpen
                    ? () => Navigator.of(
                        context,
                      ).push(EntityAssetViewerScreen.route(asset))
                    : null,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      width: 200,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          asset.imageUrl == null
                              ? const ColoredBox(
                                  color: Colors.black12,
                                  child: Icon(
                                    Icons.perm_media_outlined,
                                    size: 56,
                                  ),
                                )
                              : Image.network(
                                  asset.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.perm_media_outlined),
                                ),
                          if (canOpen)
                            const Center(
                              child: Icon(
                                Icons.open_in_full_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _row('Uploaded', upload == null ? 'Unknown' : _date(upload), muted),
            if (asset.description.isNotEmpty)
              _row('Description', asset.description, muted),
            const SizedBox(height: 8),
            Text('Tags', style: GoogleFonts.inter(fontSize: 12, color: muted)),
            const SizedBox(height: 6),
            if (asset.tags.isEmpty)
              Text('No tags', style: GoogleFonts.inter(fontSize: 13))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final t in asset.tags) Chip(label: Text(t))],
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, Color muted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: muted)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 14)),
        ],
      ),
    );
  }
}
