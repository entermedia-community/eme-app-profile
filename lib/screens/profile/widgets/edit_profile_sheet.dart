import 'dart:typed_data';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_colors.dart';

/// Edits the signed-in user's account: first and last name and the portrait.
/// The fields start with what the server has for the user.
class EditProfileSheet extends ConsumerStatefulWidget {
  final EmUser user;

  /// Chooses the new portrait; replaced in tests.
  final Future<PlatformFile?> Function() pickImage;

  const EditProfileSheet({
    super.key,
    required this.user,
    this.pickImage = _pickAnyImage,
  });

  static Future<PlatformFile?> _pickAnyImage() =>
      FilePicker.pickFile(type: FileType.image);

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  PlatformFile? _portrait;
  Uint8List? _portraitPreview;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.user.firstname ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.user.lastname ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _choosePortrait() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await widget.pickImage();
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _portrait = picked;
        _portraitPreview = bytes;
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redAccent,
          content: Text('Could not open the picture: $e'),
        ),
      );
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final portrait = _portrait;
      await ref
          .read(authProvider.notifier)
          .updateAccount(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            portrait: portrait == null
                ? null
                : MultipartFile.fromBytes(
                    _portraitPreview!,
                    filename: portrait.name,
                  ),
          );
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redAccent,
          content: Text('Could not update profile: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
    ),
  );

  Widget _avatar() {
    final portraitUrl = widget.user.assetportrait;
    final ImageProvider? image = _portraitPreview != null
        ? MemoryImage(_portraitPreview!)
        : (portraitUrl != null && portraitUrl.isNotEmpty
              ? NetworkImage(portraitUrl)
              : null);
    return CircleAvatar(
      radius: 44,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      backgroundImage: image,
      onBackgroundImageError: image == null ? null : (_, _) {},
      child: image == null
          ? Text(
              widget.user.avatarInitials,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: 24 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profile',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Semantics(
                  identifier: 'edit_profile_close',
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Center(
              child: Column(
                children: [
                  _avatar(),
                  const SizedBox(height: 8),
                  Semantics(
                    identifier: 'edit_profile_change_picture',
                    child: TextButton.icon(
                      onPressed: _busy ? null : _choosePortrait,
                      icon: const Icon(Icons.photo_camera_outlined, size: 18),
                      label: const Text('Change picture'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            _label('First Name'),
            Semantics(
              identifier: 'edit_profile_first_name',
              child: TextField(
                controller: _firstNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'First name'),
              ),
            ),
            const SizedBox(height: 14),

            _label('Last Name'),
            Semantics(
              identifier: 'edit_profile_last_name',
              child: TextField(
                controller: _lastNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'Last name'),
              ),
            ),
            if (widget.user.email != null && widget.user.email!.isNotEmpty) ...[
              const SizedBox(height: 14),
              _label('Email'),
              TextFormField(
                initialValue: widget.user.email,
                enabled: false,
              ),
            ],
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: Semantics(
                identifier: 'edit_profile_save',
                child: ElevatedButton(
                  onPressed: _busy ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
