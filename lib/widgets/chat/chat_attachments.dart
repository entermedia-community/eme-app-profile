import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// The "+" button of a chat input. Today it picks attachments directly; later
/// it will open a popup (Attachments, Products, Services, ...) based on the
/// chat type — that switch belongs in [ChatAttachButton._onPressed].
class ChatAttachButton extends StatelessWidget {
  /// Unique per screen, used for the Semantics identifier.
  final String id;
  final ValueChanged<List<PlatformFile>> onPicked;
  final double iconSize;

  /// Chooses the files; replaced in tests.
  final Future<List<PlatformFile>> Function() pickFiles;

  const ChatAttachButton({
    super.key,
    required this.id,
    required this.onPicked,
    this.iconSize = 24,
    this.pickFiles = _pickAny,
  });

  static Future<List<PlatformFile>> _pickAny() async {
    return FilePicker.pickFiles();
  }

  Future<void> _onPressed(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final files = await pickFiles();
      if (files.isNotEmpty) onPicked(files);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redAccent,
          content: Text('Could not pick files: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      identifier: '${id}_attach_button',
      child: IconButton(
        icon: Icon(Icons.add_circle_outline_rounded, size: iconSize),
        color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
        tooltip: 'Attach',
        onPressed: () => _onPressed(context),
      ),
    );
  }
}

/// Removable chips for the attachments picked but not yet sent.
class ChatAttachmentTray extends StatelessWidget {
  final String id;
  final List<PlatformFile> files;
  final ValueChanged<PlatformFile> onRemove;

  const ChatAttachmentTray({
    super.key,
    required this.id,
    required this.files,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (var i = 0; i < files.length; i++)
              Semantics(
                identifier: '${id}_attachment_chip_$i',
                child: InputChip(
                  avatar: const Icon(Icons.attach_file_rounded, size: 16),
                  label: Text(files[i].name, overflow: TextOverflow.ellipsis),
                  onDeleted: () => onRemove(files[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
