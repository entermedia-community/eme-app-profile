import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../screens/entity_asset/entity_asset_detail_screen.dart';
import '../../theme/app_colors.dart';

/// Entity assets of a project ([collectionId]), the profile of [userId] or,
/// with neither, the signed-in user.
class EntityAssetList extends ConsumerWidget {
  final String? collectionId;
  final String? userId;

  const EntityAssetList({super.key, this.collectionId, this.userId});

  static String _date(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month.toString().padLeft(2, '0')}-'
        '${l.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (collectionId: collectionId, userId: userId);
    final assets = ref.watch(entityAssetsProvider(key));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textDarkMuted : AppColors.textMuted;

    return assets.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Row(
        children: [
          Expanded(
            child: Text(
              'Could not load entity assets: $e',
              style: GoogleFonts.inter(fontSize: 13, color: muted),
            ),
          ),
          Semantics(
            identifier: 'entity_assets_retry',
            child: TextButton(
              onPressed: () => ref.invalidate(entityAssetsProvider(key)),
              child: const Text('Retry'),
            ),
          ),
        ],
      ),
      data: (list) {
        if (list.isEmpty) {
          return Text(
            'No entity assets yet.',
            style: GoogleFonts.inter(fontSize: 13, color: muted),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final a = list[i];
            final details = [
              if (a.sourceType != null) a.sourceType!,
              if (a.date != null) _date(a.date!),
            ].join(' • ');
            return Semantics(
              identifier: 'entity_asset_${a.id}',
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.of(
                  context,
                ).push(EntityAssetDetailScreen.route(a, key)),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkCardBorder
                          : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: _Thumb(asset: a),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.name.isEmpty ? a.id : a.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (details.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                details,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// A row's thumbnail. While the server is still converting the image it
/// polls that one asset's status and shows the thumbnail once it is ready.
class _Thumb extends ConsumerWidget {
  final EntityAssetModel asset;

  const _Thumb({required this.asset});

  static const _placeholder = Icon(Icons.perm_media_outlined);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var url = asset.imageUrl;
    final assetId = asset.imageAssetId;
    if (asset.thumbPending && assetId != null) {
      final status = ref.watch(assetPreviewProvider(assetId)).valueOrNull;
      if (status == null || status.isPending) {
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      if (!status.isReady) return _placeholder;
      url = status.url ?? url;
    }
    if (url == null) return _placeholder;
    return Image.network(
      url,
      key: ValueKey('${asset.id}-$url'),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder,
    );
  }
}
