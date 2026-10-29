import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';
import 'add_team_member_dialog.dart';
import 'edit_team_member_sheet.dart';

/// "Teams" from the project's 3-dot menu: every member of the project, and
/// (for editors) a button to add more.
class ProjectTeamSheet extends ConsumerWidget {
  /// Null when no collection is linked to this project.
  final ProjectCollectionKey? collectionKey;

  const ProjectTeamSheet({super.key, required this.collectionKey});

  static Future<void> show(
    BuildContext context, {
    required ProjectCollectionKey? collectionKey,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProjectTeamSheet(collectionKey: collectionKey),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textDarkMuted : AppColors.textMuted;
    final key = collectionKey;

    Widget body;
    if (key == null) {
      body = Text(
        'Team is not available: this project is not linked to a collection.',
        style: GoogleFonts.inter(fontSize: 13, color: muted),
      );
    } else {
      final connection = ref
          .watch(projectChatConnectionProvider(key.collectionId))
          .valueOrNull;
      final canEdit = connection?.canEditCollection ?? false;
      final canEditMembers = connection?.canViewSettings ?? false;
      body = ref
          .watch(projectCollectionProvider(key))
          .when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Row(
              children: [
                Expanded(child: Text('Could not load the team: $e')),
                Semantics(
                  identifier: 'project_team_retry',
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(projectCollectionProvider(key)),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
            data: (collection) {
              // Web hides the team from outsiders on commercial projects.
              if (collection.isCommercial && !canEdit) {
                return Text(
                  'The team of this project is private.',
                  style: GoogleFonts.inter(fontSize: 13, color: muted),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (collection.team.isEmpty)
                    Text(
                      'No team yet',
                      style: GoogleFonts.inter(fontSize: 13, color: muted),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: collection.team.length,
                        itemBuilder: (context, i) {
                          final m = collection.team[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              foregroundImage: m.portraitUrl != null
                                  ? NetworkImage(m.portraitUrl!)
                                  : null,
                              child: Text(
                                m.displayName.isNotEmpty
                                    ? m.displayName[0].toUpperCase()
                                    : '?',
                              ),
                            ),
                            title: Text(m.displayName),
                            subtitle: m.roleLabels.isEmpty
                                ? null
                                : Text(m.roleLabels.join(', ')),
                            trailing: canEditMembers && m.memberId != null
                                ? Semantics(
                                    identifier: 'project_team_edit_$i',
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                      ),
                                      tooltip: 'Edit Entry',
                                      onPressed: () => EditTeamMemberSheet.show(
                                        context,
                                        collectionKey: key,
                                        member: m,
                                      ),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
                  if (canEdit) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      identifier: 'project_team_add',
                      child: FilledButton.icon(
                        onPressed: () => AddTeamMemberDialog.show(
                          context,
                          collectionKey: key,
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: const Text('Add team member'),
                      ),
                    ),
                  ],
                ],
              );
            },
          );
    }

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
              'Team',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(child: body),
          ],
        ),
      ),
    );
  }
}
