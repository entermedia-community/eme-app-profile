import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_colors.dart';

/// "EME" followed by the user's first name, e.g. "EME Christopher".
String emeProfileLabel(EmUser? user, ProfileModel profile) {
  final first = user?.firstname?.trim();
  if (first != null && first.isNotEmpty) return 'EME $first';
  final name = (user?.displayName ?? profile.name).trim();
  return name.isEmpty ? 'EME' : 'EME ${name.split(' ').first}';
}

/// App bar pill showing "EME" plus the user's first name, with a round portrait.
/// Tapping it switches to the EME profile tab.
class ProfileAppBarButton extends ConsumerWidget {
  const ProfileAppBarButton({super.key});

  static const double _avatarSize = 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider);
    final currentUser = ref.watch(authProvider).user;

    final initials =
        currentUser?.avatarInitials ??
        (profile.name.isNotEmpty ? profile.name.substring(0, 1) : 'E');
    final portraitUrl = currentUser != null
        ? currentUser.assetportrait
        : profile.avatarUrl;

    return Semantics(
      identifier: 'app_bar_profile_button',
      button: true,
      label: 'Open EME profile',
      child: Material(
        color: AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              ref.read(navigationProvider.notifier).selectTab(NavTab.profile),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAvatar(portraitUrl, initials, isDark),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    emeProfileLabel(currentUser, profile),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textDarkPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String? url, String initials, bool isDark) {
    final fallback = Center(
      child: Text(
        initials,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );

    return Container(
      width: _avatarSize,
      height: _avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                width: _avatarSize,
                height: _avatarSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => fallback,
              )
            : fallback,
      ),
    );
  }
}
