import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/delta_viewer.dart';
import '../../projects/create_project_screen.dart';
import 'add_team_member_sheet.dart';
import 'edit_team_member_sheet.dart';

/// The web project page's right sidebar (`project/layout/sidebar-right.html`)
/// as a bottom sheet, in the same order: Agents (team), Donate, Followers,
/// Testimonials and social links.
class ProjectInfoSheet extends ConsumerWidget {
  final ServerModel server;

  /// Null when no collection is linked to this project.
  final ProjectCollectionKey? collectionKey;

  const ProjectInfoSheet({
    super.key,
    required this.server,
    required this.collectionKey,
  });

  static Future<void> show(
    BuildContext context, {
    required ServerModel server,
    required ProjectCollectionKey? collectionKey,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ProjectInfoSheet(server: server, collectionKey: collectionKey),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final key = collectionKey;

    final Widget body;
    if (key == null) {
      body = _message(
        isDark,
        Icons.link_off_rounded,
        'Project details are not available: this project is not linked to a collection.',
      );
    } else {
      body = ref
          .watch(projectCollectionProvider(key))
          .when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Column(
              children: [
                _message(
                  isDark,
                  Icons.error_outline_rounded,
                  'Could not load project details.\n$err',
                ),
                Semantics(
                  identifier: 'project_info_retry',
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(projectCollectionProvider(key)),
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
            data: (collection) =>
                _buildSections(context, ref, collection, isDark),
          );
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              server.name,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }

  Widget _buildSections(
    BuildContext context,
    WidgetRef ref,
    LibraryCollectionModel collection,
    bool isDark,
  ) {
    final testimonials = collection.proposalTestimonials ?? '';
    final connection = ref
        .watch(projectChatConnectionProvider(collection.id))
        .valueOrNull;
    final canEdit = connection?.canEditCollection ?? false;
    final canEditMembers = connection?.canViewSettings ?? false;
    final donateUrl = collection.webUrl(_siteRoot, 'donate/index.html');
    final isOwner = collection.isOwnedBy(
      ref.watch(authProvider).user?.username,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only the owner may change the project's details.
        if (isOwner) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              identifier: 'project_edit_details',
              child: OutlinedButton.icon(
                onPressed: () => CreateProjectScreen.edit(context, collection),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit details'),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (collection.displayDescription.isNotEmpty) ...[
          _bodyText(collection.displayDescription, isDark),
          const SizedBox(height: 16),
        ],
        // Web hides the team from outsiders on commercial projects.
        if (!collection.isCommercial)
          _section(
            title: 'Agents',
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (collection.team.isEmpty)
                  _bodyText('No team yet', isDark)
                else
                  for (final (index, member) in collection.team.indexed)
                    _TeamMemberRow(
                      member: member,
                      isDark: isDark,
                      // Web shows the edit pencil with $canviewsettings.
                      onEdit: canEditMembers && member.memberId != null
                          ? () => EditTeamMemberSheet.show(
                              context,
                              collectionKey: collectionKey!,
                              member: member,
                            )
                          : null,
                      editIdentifier: 'project_edit_member_$index',
                    ),
                // Web shows these to editors only.
                if (canEdit) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Semantics(
                        identifier: 'project_add_agent',
                        child: OutlinedButton.icon(
                          onPressed: () => AddTeamMemberSheet.show(
                            context,
                            collectionKey: collectionKey!,
                            mode: AddTeamMemberMode.search,
                          ),
                          icon: const Icon(Icons.search_rounded, size: 16),
                          label: const Text('Add Existing User'),
                        ),
                      ),
                      Semantics(
                        identifier: 'project_new_user',
                        child: OutlinedButton.icon(
                          onPressed: () => AddTeamMemberSheet.show(
                            context,
                            collectionKey: collectionKey!,
                            mode: AddTeamMemberMode.newUser,
                          ),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('New User'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        if (collection.acceptsDonations)
          _section(
            title: 'Donate',
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bodyText(
                  collection.donateDescription ?? 'Be a Part of This Project',
                  isDark,
                ),
                if (donateUrl != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Semantics(
                      identifier: 'project_donate_button',
                      child: FilledButton.icon(
                        onPressed: () => _open(context, donateUrl),
                        icon: const Icon(Icons.credit_card_rounded, size: 16),
                        label: const Text('Donate'),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        _section(
          title: 'Followers',
          isDark: isDark,
          child: _FollowRow(
            collection: collection,
            collectionKey: collectionKey!,
            isDark: isDark,
          ),
        ),
        if (testimonials.isNotEmpty)
          _section(
            title: 'Testimonials',
            isDark: isDark,
            // Stored as HTML; rendered rich like the web sidebar.
            child: DeltaViewer(
              deltaOps: HtmlToDelta().convert(testimonials).toJson(),
              onLinkTap: (link, _) => _open(context, link),
            ),
          ),
        if (collection.hasSocialLinks || collection.contactEmail != null)
          _section(
            title: 'Links',
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (collection.contactEmail != null)
                  _linkRow(
                    context,
                    'project_link_email',
                    Icons.mail_outline_rounded,
                    collection.contactEmail!,
                    'mailto:${collection.contactEmail!}',
                    isDark,
                  ),
                if (collection.websiteLink != null)
                  _linkRow(
                    context,
                    'project_link_website',
                    Icons.link_rounded,
                    collection.websiteLink!,
                    collection.websiteLink!,
                    isDark,
                  ),
                if (collection.facebookLink != null)
                  _linkRow(
                    context,
                    'project_link_facebook',
                    Icons.facebook_rounded,
                    collection.facebookLink!,
                    collection.facebookLink!,
                    isDark,
                  ),
                if (collection.instagramLink != null)
                  _linkRow(
                    context,
                    'project_link_instagram',
                    Icons.camera_alt_outlined,
                    collection.instagramLink!,
                    collection.instagramLink!,
                    isDark,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  static String get _siteRoot => OpenI.instance?.settings.siteroot ?? '';

  static Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final opened =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redAccent,
          content: Text('Could not open $url'),
        ),
      );
    }
  }

  Widget _section({
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _bodyText(String text, bool isDark) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        height: 1.45,
        color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
      ),
    );
  }

  Widget _linkRow(
    BuildContext context,
    String identifier,
    IconData icon,
    String label,
    String url,
    bool isDark,
  ) {
    return Semantics(
      identifier: identifier,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _open(context, url),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _message(bool isDark, IconData icon, String text) {
    final color = isDark ? AppColors.textDarkMuted : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: color),
          ),
        ],
      ),
    );
  }
}

class _TeamMemberRow extends StatelessWidget {
  final ProjectTeamMember member;
  final bool isDark;
  final VoidCallback? onEdit;
  final String editIdentifier;

  const _TeamMemberRow({
    required this.member,
    required this.isDark,
    required this.onEdit,
    required this.editIdentifier,
  });

  @override
  Widget build(BuildContext context) {
    final portrait = member.portraitUrl;
    final name = member.displayName;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            foregroundImage: portrait != null ? NetworkImage(portrait) : null,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
          if (member.roleLabels.isNotEmpty)
            Text(
              member.roleLabels.join(', '),
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
              ),
            ),
          if (onEdit != null)
            Semantics(
              identifier: editIdentifier,
              child: IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                tooltip: 'Edit Entry',
                visualDensity: VisualDensity.compact,
                onPressed: onEdit,
              ),
            ),
        ],
      ),
    );
  }
}

/// Follower count and Follow/Following toggle (web `channel/likeoptions.html`).
class _FollowRow extends ConsumerStatefulWidget {
  final LibraryCollectionModel collection;
  final ProjectCollectionKey collectionKey;
  final bool isDark;

  const _FollowRow({
    required this.collection,
    required this.collectionKey,
    required this.isDark,
  });

  @override
  ConsumerState<_FollowRow> createState() => _FollowRowState();
}

class _FollowRowState extends ConsumerState<_FollowRow> {
  bool _busy = false;

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(apiServiceProvider)
          .toggleProjectFollow(widget.collection.id);
      ref.invalidate(projectCollectionProvider(widget.collectionKey));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.redAccent,
            content: Text('Could not update follow: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.collection.followerCount;
    final following = widget.collection.followedByUser ?? false;
    return Row(
      children: [
        Expanded(
          child: Text(
            '$count ${count == 1 ? 'Follower' : 'Followers'}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.isDark
                  ? AppColors.textDarkPrimary
                  : AppColors.textPrimary,
            ),
          ),
        ),
        Semantics(
          identifier: 'project_follow_button',
          child: following
              ? OutlinedButton.icon(
                  onPressed: _busy ? null : _toggle,
                  icon: const Icon(Icons.thumb_up_rounded, size: 16),
                  label: const Text('Following'),
                )
              : FilledButton.icon(
                  onPressed: _busy ? null : _toggle,
                  icon: const Icon(Icons.thumb_up_outlined, size: 16),
                  label: const Text('Follow'),
                ),
        ),
      ],
    );
  }
}
