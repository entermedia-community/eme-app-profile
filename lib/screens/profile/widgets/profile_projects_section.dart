import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';
import '../../project/project_screen.dart';

/// Projects the signed-in user owns or is on the team of, shown on the profile.
class ProfileProjectsSection extends ConsumerWidget {
  const ProfileProjectsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(userProjectsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textDarkMuted : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Projects',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        projects.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Row(
            children: [
              Expanded(
                child: Text(
                  'Could not load projects: $e',
                  style: GoogleFonts.inter(fontSize: 13, color: muted),
                ),
              ),
              Semantics(
                identifier: 'profile_projects_retry',
                child: TextButton(
                  onPressed: () => ref.invalidate(userProjectsProvider),
                  child: const Text('Retry'),
                ),
              ),
            ],
          ),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                'You are not part of any projects yet.',
                style: GoogleFonts.inter(fontSize: 13, color: muted),
              );
            }
            return Column(
              children: [
                for (final p in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Semantics(
                      identifier: 'profile_project_${p.id}',
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.15),
                            foregroundImage:
                                (p.logoUrl != null && p.logoUrl!.isNotEmpty)
                                ? NetworkImage(p.logoUrl!)
                                : null,
                            child: Text(
                              p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
                            ),
                          ),
                          title: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: (p.description ?? '').isEmpty
                              ? null
                              : Text(
                                  p.description!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(
                            context,
                          ).push(ProjectScreen.routeForCollection(p)),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
