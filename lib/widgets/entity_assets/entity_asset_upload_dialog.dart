import 'dart:typed_data';
import 'package:flutter/material.dart';

/// What the user entered for a file about to be uploaded.
class EntityAssetUploadDetails {
  final String name;
  final String? description;
  final List<String> tags;

  const EntityAssetUploadDetails({
    required this.name,
    this.description,
    this.tags = const [],
  });
}

/// Asks for the details of the picked file: a preview (the image itself, else
/// a file icon), the entity [name] (required, starts as the file name without
/// its extension), an optional description and tags.
/// Pops an [EntityAssetUploadDetails], or null when cancelled.
class EntityAssetUploadDialog extends StatefulWidget {
  final String fileName;

  /// The file's bytes, used to preview images.
  final Uint8List? bytes;

  const EntityAssetUploadDialog({
    super.key,
    required this.fileName,
    this.bytes,
  });

  static Future<EntityAssetUploadDetails?> show(
    BuildContext context, {
    required String fileName,
    Uint8List? bytes,
  }) => showDialog<EntityAssetUploadDetails>(
    context: context,
    builder: (_) => EntityAssetUploadDialog(fileName: fileName, bytes: bytes),
  );

  static const _imageExtensions = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};

  /// [fileName] without its extension.
  static String nameFromFile(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }

  @override
  State<EntityAssetUploadDialog> createState() =>
      _EntityAssetUploadDialogState();
}

class _EntityAssetUploadDialogState extends State<EntityAssetUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: EntityAssetUploadDialog.nameFromFile(widget.fileName),
  );
  final _description = TextEditingController();
  final _tagInput = TextEditingController();
  final _tags = <String>[];

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  String get _extension {
    final dot = widget.fileName.lastIndexOf('.');
    return dot < 0 ? '' : widget.fileName.substring(dot + 1).toLowerCase();
  }

  void _addTags(String text) {
    final added = text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && !_tags.contains(t));
    if (added.isEmpty) {
      _tagInput.clear();
      return;
    }
    setState(() {
      _tags.addAll(added);
      _tagInput.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _addTags(_tagInput.text);
    final description = _description.text.trim();
    Navigator.of(context).pop(
      EntityAssetUploadDetails(
        name: _name.text.trim(),
        description: description.isEmpty ? null : description,
        tags: List.of(_tags),
      ),
    );
  }

  Widget _preview() {
    final bytes = widget.bytes;
    final isImage = EntityAssetUploadDialog._imageExtensions.contains(
      _extension,
    );
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 140,
          child: isImage && bytes != null
              ? Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _fileIcon(),
                )
              : _fileIcon(),
        ),
      ),
    );
  }

  Widget _fileIcon() {
    final icon = switch (_extension) {
      'pdf' => Icons.picture_as_pdf_outlined,
      'mp4' || 'mov' || 'avi' || 'mkv' || 'webm' => Icons.movie_outlined,
      'mp3' || 'wav' || 'm4a' || 'aac' => Icons.audiotrack_outlined,
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' => Icons.image_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
    return SizedBox(
      width: 140,
      child: Icon(icon, size: 64, color: Theme.of(context).hintColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Upload file'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _preview(),
              const SizedBox(height: 4),
              Text(
                widget.fileName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Semantics(
                identifier: 'entity_asset_upload_name',
                child: TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Name *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                identifier: 'entity_asset_upload_description',
                child: TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                identifier: 'entity_asset_upload_tags',
                child: TextField(
                  controller: _tagInput,
                  decoration: const InputDecoration(
                    labelText: 'Tags (optional)',
                    hintText: 'Type a tag, press enter or comma',
                  ),
                  onSubmitted: _addTags,
                  onChanged: (v) {
                    if (v.contains(',')) _addTags(v);
                  },
                ),
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in _tags)
                      Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                        onDeleted: () => setState(() => _tags.remove(tag)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        Semantics(
          identifier: 'entity_asset_upload_cancel',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        Semantics(
          identifier: 'entity_asset_upload_confirm',
          child: FilledButton(onPressed: _submit, child: const Text('Upload')),
        ),
      ],
    );
  }
}
