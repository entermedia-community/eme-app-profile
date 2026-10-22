import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import '../pill_badge.dart';

/// Bottom sheet previewing a server before the user joins it, with Join and
/// Share buttons. Joining is done by [onJoin], run after the sheet closes.
class ServerPreviewCard extends ConsumerWidget {
  final ServerModel server;
  final VoidCallback onJoin;

  const ServerPreviewCard({
    super.key,
    required this.server,
    required this.onJoin,
  });

  static Future<void> show(
    BuildContext context, {
    required ServerModel server,
    required VoidCallback onJoin,
  }) {
    return _showPreviewSheet(
      context,
      (_) => ServerPreviewCard(server: server, onJoin: onJoin),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Re-read the server so the button follows the joined state.
    final current = ref.watch(
      serverProvider.select(
        (s) => s.servers.where((x) => x.id == server.id).firstOrNull,
      ),
    );
    final s = current ?? server;
    final joining = ref.watch(
      serverProvider.select((st) => st.isJoining(server.id)),
    );

    return _PreviewSheet(
      idPrefix: 'server_preview',
      title: s.name,
      subtitle: s.category.name,
      accent: s.primaryColor,
      avatarUrl: s.avatarUrl,
      initials: s.displayInitials,
      description: s.description.isNotEmpty ? s.description : s.subtitle ?? '',
      chipsTitle: 'Services Offered:',
      chips: s.servicesOffered,
      meta: [
        (Icons.people_alt_outlined, '${s.memberCount} members'),
        if (s.isJoined) (Icons.check_circle_outline_rounded, 'Joined'),
      ],
      isDark: isDark,
      primaryLabel: s.isJoined ? 'Open' : (joining ? 'Joining...' : 'Join'),
      primaryIcon: s.isJoined ? Icons.chat_rounded : Icons.login_rounded,
      onPrimary: joining
          ? null
          : () {
              Navigator.pop(context);
              onJoin();
            },
      shareText: [
        s.name,
        if (s.description.isNotEmpty) s.description,
        if (s.serverMediaDBUrl.isNotEmpty) s.serverMediaDBUrl,
      ].join('\n'),
    );
  }
}

/// Bottom sheet previewing a project, with Open and Share buttons.
class ProjectPreviewCard extends StatelessWidget {
  final LibraryCollectionModel project;
  final VoidCallback onOpen;

  const ProjectPreviewCard({
    super.key,
    required this.project,
    required this.onOpen,
  });

  static Future<void> show(
    BuildContext context, {
    required LibraryCollectionModel project,
    required VoidCallback onOpen,
  }) {
    return _showPreviewSheet(
      context,
      (_) => ProjectPreviewCard(project: project, onOpen: onOpen),
    );
  }

  static const _accent = Color(0xFF3B82F6);

  String get _initials {
    final words = project.name.trim().split(RegExp(r'\s+'));
    if (project.name.trim().isEmpty) return 'PR';
    if (words.length >= 2 && words[1].isNotEmpty) {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
    return project.name
        .trim()
        .substring(0, project.name.trim().length.clamp(1, 2))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final link = project.projectLink;

    return _PreviewSheet(
      idPrefix: 'project_preview',
      title: project.name.isNotEmpty ? project.name : 'Project',
      subtitle: project.isProposal ? 'Proposal' : 'Project',
      accent: _accent,
      avatarUrl: project.primaryImageUrl,
      initials: _initials,
      description: project.displayDescription,
      chipsTitle: null,
      chips: const [],
      meta: [
        if (project.team.isNotEmpty)
          (Icons.groups_outlined, '${project.team.length} on the team'),
        (Icons.favorite_border_rounded, '${project.followerCount} followers'),
      ],
      isDark: isDark,
      primaryLabel: 'Open',
      primaryIcon: Icons.folder_open_rounded,
      onPrimary: () {
        Navigator.pop(context);
        onOpen();
      },
      shareText: [
        project.name,
        if (project.displayDescription.isNotEmpty) project.displayDescription,
        if (link != null && link.isNotEmpty) link,
      ].join('\n'),
    );
  }
}

Future<void> _showPreviewSheet(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: builder,
  );
}

class _PreviewSheet extends StatelessWidget {
  final String idPrefix;
  final String title;
  final String subtitle;
  final Color accent;
  final String? avatarUrl;
  final String initials;
  final String description;
  final String? chipsTitle;
  final List<String> chips;
  final List<(IconData, String)> meta;
  final bool isDark;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback? onPrimary;
  final String shareText;

  const _PreviewSheet({
    required this.idPrefix,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.avatarUrl,
    required this.initials,
    required this.description,
    required this.chipsTitle,
    required this.chips,
    required this.meta,
    required this.isDark,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimary,
    required this.shareText,
  });

  Widget _avatar() {
    final fallback = CircleAvatar(
      radius: 24,
      backgroundColor: accent.withValues(alpha: isDark ? 0.25 : 0.12),
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
    final url = avatarUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }

  void _share(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.textDarkMuted : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _avatar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    identifier: '${idPrefix}_close',
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    for (final (icon, text) in meta)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 15, color: muted),
                          const SizedBox(width: 5),
                          Text(
                            text,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
              if (description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 14, height: 1.5),
                ),
              ],
              if (chipsTitle != null && chips.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  chipsTitle!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in chips)
                      PillBadge(
                        label: c,
                        backgroundColor: accent.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        textColor: accent,
                        fontSize: 11.5,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Semantics(
                    identifier: '${idPrefix}_primary',
                    child: ElevatedButton.icon(
                      onPressed: onPrimary,
                      icon: Icon(primaryIcon, size: 16),
                      label: Text(
                        primaryLabel,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                      style: _buttonStyle(AppColors.greenAccent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    identifier: '${idPrefix}_share',
                    child: ElevatedButton.icon(
                      onPressed: () => _share(context),
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: Text(
                        'Share',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                      style: _buttonStyle(AppColors.blueButtonBg),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _buttonStyle(Color bg) => ElevatedButton.styleFrom(
    backgroundColor: bg,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}
