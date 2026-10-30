import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import 'entity_asset_upload_dialog.dart';

/// Picks a file and uploads it as a new entity asset of a project
/// ([collectionId]) or, without one, of the signed-in user's profile.
/// Refreshes the matching [EntityAssetList] when done.
class EntityAssetUploadButton extends ConsumerStatefulWidget {
  final String? collectionId;
  final String? userId;

  /// Chooses the file to upload; replaced in tests.
  final Future<PlatformFile?> Function() pickFile;

  const EntityAssetUploadButton({
    super.key,
    this.collectionId,
    this.userId,
    this.pickFile = _pickAnyFile,
  });

  static Future<PlatformFile?> _pickAnyFile() => FilePicker.pickFile();

  @override
  ConsumerState<EntityAssetUploadButton> createState() =>
      _EntityAssetUploadButtonState();
}

class _EntityAssetUploadButtonState
    extends ConsumerState<EntityAssetUploadButton> {
  bool _busy = false;

  Future<void> _upload() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final picked = await widget.pickFile();
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      final details = await EntityAssetUploadDialog.show(
        context,
        fileName: picked.name,
        bytes: bytes,
      );
      if (details == null) return;

      final path = picked.path;
      final file = path != null
          ? await MultipartFile.fromFile(path, filename: picked.name)
          : MultipartFile.fromBytes(bytes, filename: picked.name);
      await ref
          .read(apiServiceProvider)
          .uploadEntityAsset(
            file,
            collectionId: widget.collectionId,
            name: details.name,
            description: details.description,
            tags: details.tags,
          );
      ref.invalidate(
        entityAssetsProvider((
          collectionId: widget.collectionId,
          userId: widget.userId,
        )),
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Uploaded ${picked.name}')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redAccent,
          content: Text('Could not upload: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'entity_asset_upload_button',
      child: _busy
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.greenAccent,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.greenAccent.withValues(alpha: 0.1),
              ),
              tooltip: 'Upload file',
              onPressed: _upload,
            ),
    );
  }
}
