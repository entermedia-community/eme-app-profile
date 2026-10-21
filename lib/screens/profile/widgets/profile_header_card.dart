import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/auth/auth_modal_sheet.dart';
import 'edit_profile_sheet.dart';

class ProfileHeaderCard extends ConsumerWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = authState.user;

    final displayName = currentUser != null
        ? (currentUser.fullName.isNotEmpty
              ? currentUser.fullName
              : (currentUser.screenname ?? currentUser.username))
        : profile.name;

    final displayHandle = currentUser != null
        ? '@${currentUser.username}'
        : null;
    final displayInitials =
        currentUser?.avatarInitials ??
        (profile.name.isNotEmpty ? profile.name.substring(0, 1) : 'C');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Portfolio info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Avatar
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEFF6FF),
                  border: Border.all(
                    color: authState.isAuthenticated
                        ? AppColors.primary.withValues(alpha: 0.6)
                        : (isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFFCBD5E1)),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: isDark ? 0.2 : 0.1,
                      ),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: currentUser == null && profile.avatarUrl != null
                      ? Image.network(
                          _getAvatarUrl(profile),
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildAvatarFallback(
                                profile,
                                currentUser,
                                displayInitials,
                              ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          },
                        )
                      : (currentUser?.assetportrait != null &&
                                currentUser!.assetportrait!.isNotEmpty
                            ? Image.network(
                                currentUser.assetportrait!,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildAvatarFallback(
                                      profile,
                                      currentUser,
                                      displayInitials,
                                    ),
                              )
                            : _buildAvatarFallback(
                                profile,
                                currentUser,
                                displayInitials,
                              )),
                ),
              ),

              const SizedBox(width: 20),

              // Portfolio & Name & Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eyebrow & Auth status
                    Row(
                      children: [
                        Text(
                          currentUser != null
                              ? 'ACCOUNT PROFILE'
                              : profile.portfolioLabel.toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => AuthModalSheet.show(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: authState.isAuthenticated
                                  ? AppColors.greenAccent.withValues(
                                      alpha: 0.15,
                                    )
                                  : AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: authState.isAuthenticated
                                    ? AppColors.greenAccent.withValues(
                                        alpha: 0.4,
                                      )
                                    : AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  authState.isAuthenticated
                                      ? Icons.verified_user_rounded
                                      : Icons.login_rounded,
                                  size: 13,
                                  color: authState.isAuthenticated
                                      ? AppColors.greenAccent
                                      : AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  authState.isAuthenticated
                                      ? 'Verified'
                                      : 'Sign In',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: authState.isAuthenticated
                                        ? AppColors.greenAccent
                                        : AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // User Name with edit pencil
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Semantics(
                          identifier: 'profile_edit_button',
                          child: IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit Profile',
                            color: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                            onPressed: () =>
                                _showEditProfileSheet(context, profile, ref),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Role with accent bar & handle
                    if (displayHandle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          displayHandle,
                          style: GoogleFonts.firaCode(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Bio text
          Text(
            profile.bio,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  String _getAvatarUrl(ProfileModel profile) {
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      return profile.avatarUrl!;
    }
    final hash = profile.id.hashCode.abs() + profile.name.hashCode.abs();
    final idx = (hash % 70) + 1;
    final isWomen =
        profile.name.toLowerCase().contains('maya') ||
        profile.name.toLowerCase().contains('sofia') ||
        profile.name.toLowerCase().contains('elena') ||
        profile.name.toLowerCase().contains('woman');
    final gender = isWomen ? 'women' : 'men';
    return 'https://randomuser.me/api/portraits/$gender/$idx.jpg';
  }

  Widget _buildAvatarFallback(
    ProfileModel profile, [
    EmUser? user,
    String? initials,
  ]) {
    final text =
        initials ??
        (user?.avatarInitials ??
            (profile.name.isNotEmpty ? profile.name.substring(0, 1) : 'C'));
    return Center(
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _showEditProfileSheet(
    BuildContext context,
    ProfileModel profile,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileSheet(profile: profile),
    );
  }
}
