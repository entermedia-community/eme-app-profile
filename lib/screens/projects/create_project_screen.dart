import 'dart:typed_data';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../project/project_screen.dart';

/// Form for creating a project, or with [project] for editing the details of
/// one the user owns (the logo is not editable yet). Only the name is
/// required. A created project opens on success.
class CreateProjectScreen extends ConsumerStatefulWidget {
  /// Chooses the logo; replaced in tests.
  final Future<PlatformFile?> Function() pickImage;

  /// The project to edit; null creates a new one.
  final LibraryCollectionModel? project;

  const CreateProjectScreen({
    super.key,
    this.pickImage = _pickAnyImage,
    this.project,
  });

  static Future<PlatformFile?> _pickAnyImage() =>
      FilePicker.pickFile(type: FileType.image);

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CreateProjectScreen()),
    );
  }

  /// Opens the edit form; completes with true when the details were saved.
  static Future<bool?> edit(BuildContext context, LibraryCollectionModel p) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateProjectScreen(project: p)),
    );
  }

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _slug = TextEditingController();
  final _tagInput = TextEditingController();
  final _tags = <String>[];
  PlatformFile? _logo;
  Uint8List? _logoBytes;

  /// The slug follows the name until the user types their own.
  bool _slugEdited = false;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.project != null;

  @override
  void initState() {
    super.initState();
    final project = widget.project;
    if (project == null) return;
    _name.text = project.name;
    _description.text = project.displayDescription;
    _slug.text = project.urlName ?? '';
    _slugEdited = true;
    _tags.addAll(project.tags);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _slug.dispose();
    _tagInput.dispose();
    super.dispose();
  }

  static String slugify(String text) => text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  void _onNameChanged(String value) {
    if (!_slugEdited) _slug.text = slugify(value);
  }

  void _addTags(String raw) {
    final added = raw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && !_tags.contains(t));
    if (added.isEmpty) return;
    setState(() => _tags.addAll(added));
    _tagInput.clear();
  }

  Future<void> _chooseLogo() async {
    try {
      final picked = await widget.pickImage();
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _logo = picked;
        _logoBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redAccent,
          content: Text('Could not open the picture: $e'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // A tag typed but not yet confirmed still counts.
    _addTags(_tagInput.text);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final existing = widget.project;
      if (existing != null) {
        await ref
            .read(apiServiceProvider)
            .updateProject(
              existing.id,
              name: _name.text.trim(),
              description: _description.text.trim(),
              urlName: _slug.text.trim(),
              tags: List.of(_tags),
            );
        ref.invalidate(userProjectsProvider);
        ref.invalidate(projectCollectionProvider);
        if (!mounted) return;
        Navigator.of(context).pop(true);
        return;
      }
      final logo = _logo;
      final project = await ref
          .read(apiServiceProvider)
          .createProject(
            name: _name.text.trim(),
            description: _description.text.trim(),
            urlName: _slug.text.trim(),
            tags: List.of(_tags),
            logo: logo == null
                ? null
                : MultipartFile.fromBytes(_logoBytes!, filename: logo.name),
          );
      ref.invalidate(userProjectsProvider);
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(ProjectScreen.routeForCollection(project));
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'CreateProjectScreen.submit failed',
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$e';
        });
      }
    }
  }

  Widget _logoPicker() {
    final bytes = _logoBytes;
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.primary.withValues(alpha: 0.12),
          backgroundImage: bytes == null ? null : MemoryImage(bytes),
          onBackgroundImageError: bytes == null ? null : (_, _) {},
          child: bytes == null
              ? const Icon(Icons.image_outlined, color: AppColors.primary)
              : null,
        ),
        const SizedBox(width: 12),
        Semantics(
          identifier: 'create_project_logo',
          child: OutlinedButton.icon(
            onPressed: _saving ? null : _chooseLogo,
            icon: const Icon(Icons.photo_camera_outlined, size: 18),
            label: Text(bytes == null ? 'Add logo (optional)' : 'Change logo'),
          ),
        ),
        if (bytes != null)
          Semantics(
            identifier: 'create_project_logo_remove',
            child: IconButton(
              tooltip: 'Remove logo',
              icon: const Icon(Icons.close_rounded),
              onPressed: _saving
                  ? null
                  : () => setState(() {
                      _logo = null;
                      _logoBytes = null;
                    }),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? 'Edit project' : 'New project',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (!_editing) ...[_logoPicker(), const SizedBox(height: 16)],
            Semantics(
              identifier: 'create_project_name',
              child: TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Project name'),
                onChanged: _onNameChanged,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Give the project a name'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              identifier: 'create_project_description',
              child: TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              identifier: 'create_project_slug',
              child: TextFormField(
                controller: _slug,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'URL slug (optional)',
                  prefixText: '/',
                ),
                onChanged: (_) => _slugEdited = true,
                validator: (v) {
                  final slug = v?.trim() ?? '';
                  if (slug.isEmpty) return null;
                  return RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(slug)
                      ? null
                      : 'Use letters, numbers, - and _ only';
                },
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              identifier: 'create_project_tags',
              child: TextField(
                controller: _tagInput,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Tags (optional)',
                  helperText: 'Separate with commas or press done',
                  suffixIcon: Semantics(
                    identifier: 'create_project_tag_add',
                    child: IconButton(
                      tooltip: 'Add tag',
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () => _addTags(_tagInput.text),
                    ),
                  ),
                ),
                onChanged: (v) {
                  if (v.contains(',')) _addTags(v);
                },
                onSubmitted: _addTags,
              ),
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final tag in _tags)
                    Semantics(
                      identifier: 'create_project_tag_$tag',
                      child: InputChip(
                        label: Text(tag),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                      ),
                    ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.redAccent,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Semantics(
              identifier: 'create_project_submit',
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_editing ? 'Save changes' : 'Create project'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
