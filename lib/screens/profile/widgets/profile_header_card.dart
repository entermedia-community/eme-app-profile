import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../providers/navigation_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/auth/auth_modal_sheet.dart';
import '../../../widgets/pill_badge.dart';
import 'edit_profile_sheet.dart';

class ProfileHeaderCard extends ConsumerWidget {
  const ProfileHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = authState.user;

    final displayName = profile.name;
    final displayRole = profile.role;

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
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFCBD5E1),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    _getAvatarUrl(profile),
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildAvatarFallback(profile, currentUser),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Portfolio & Name & Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eyebrow "PORTFOLIO" & Auth status
                    Row(
                      children: [
                        Text(
                          profile.portfolioLabel.toUpperCase(),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: authState.isAuthenticated
                                  ? AppColors.greenAccent.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: authState.isAuthenticated
                                    ? AppColors.greenAccent.withValues(alpha: 0.4)
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
                                  authState.isAuthenticated ? 'Verified' : 'Sign In',
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

                    // User Name
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Role with accent bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayRole,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 32,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Bio text: "Cool guy"
          Text(
            profile.bio,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textDarkSecondary : const Color(0xFF475569),
            ),
          ),

          const SizedBox(height: 12),

          // Tags badges: Programmer, Dude, etc.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.tags.map((tag) {
              return PillBadge(
                label: tag,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                textColor: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569),
                fontSize: 12,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Action Buttons: "Open Chat" & "Edit Profile"
          Row(
            children: [
              // Open Chat button (Green accent as shown in mockup)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(navigationProvider.notifier).setTab(1);
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                    label: Text(
                      'Open Chat',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF15803D) : const Color(0xFF86EFAC),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF14532D),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Edit Profile button (Blue as shown in mockup)
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showEditProfileSheet(context, profile, ref);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      'Edit Profile',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ),
            ],
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
    final isWomen = profile.name.toLowerCase().contains('maya') ||
        profile.name.toLowerCase().contains('sofia') ||
        profile.name.toLowerCase().contains('elena') ||
        profile.name.toLowerCase().contains('woman');
    final gender = isWomen ? 'women' : 'men';
    return 'https://randomuser.me/api/portraits/$gender/$idx.jpg';
  }

  Widget _buildAvatarFallback(ProfileModel profile, [EmUser? user]) {
    if (user != null) {
      return Center(
        child: Text(
          user.avatarInitials,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      );
    }
    return Icon(
      Icons.person_rounded,
      size: 48,
      color: Colors.grey.shade400,
    );
  }

  void _showEditProfileSheet(BuildContext context, ProfileModel profile, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditProfileSheet(profile: profile),
    );
  }
}
