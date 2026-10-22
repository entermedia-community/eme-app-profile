import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';

/// The web team member edit dialog
/// (`project/channel/subscribers/edit/edit.html`): Team Member on/off and
/// roles.
class EditTeamMemberSheet extends ConsumerStatefulWidget {
  final ProjectCollectionKey collectionKey;
  final ProjectTeamMember member;

  const EditTeamMemberSheet({
    super.key,
    required this.collectionKey,
    required this.member,
  });

  static Future<void> show(
    BuildContext context, {
    required ProjectCollectionKey collectionKey,
    required ProjectTeamMember member,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          EditTeamMemberSheet(collectionKey: collectionKey, member: member),
    );
  }

  @override
  ConsumerState<EditTeamMemberSheet> createState() =>
      _EditTeamMemberSheetState();
}

class _EditTeamMemberSheetState extends ConsumerState<EditTeamMemberSheet> {
  // Only members with ontheteam=true are listed, so it starts on.
  bool _onTheTeam = true;
  late final Set<String> _roleIds = widget.member.teamRoles.toSet();
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(apiServiceProvider)
          .updateProjectTeamMember(
            widget.collectionKey.collectionId,
            memberId: widget.member.memberId!,
            onTheTeam: _onTheTeam,
            roleIds: _roleIds.toList(),
          );
      ref.invalidate(projectCollectionProvider(widget.collectionKey));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redAccent,
          content: Text('Could not update team member: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rolesAsync = ref.watch(projectTeamRolesProvider);

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.member.displayName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              identifier: 'project_member_on_team_switch',
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Team Member'),
                value: _onTheTeam,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _onTheTeam = value),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Roles',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: rolesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Text('Could not load roles: $err'),
                data: (roles) => SingleChildScrollView(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final role in roles)
                        Semantics(
                          identifier: 'project_member_role_${role.id}',
                          child: FilterChip(
                            label: Text(role.name),
                            selected: _roleIds.contains(role.id),
                            onSelected: _busy
                                ? null
                                : (selected) => setState(() {
                                    selected
                                        ? _roleIds.add(role.id)
                                        : _roleIds.remove(role.id);
                                  }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Semantics(
              identifier: 'project_member_save',
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
