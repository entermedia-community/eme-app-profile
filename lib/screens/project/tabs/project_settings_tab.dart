import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';

/// Project settings tab displaying project configuration, metadata, and controls.
class ProjectSettingsTab extends StatelessWidget {
  final ServerModel server;
  final LibraryCollectionModel? collection;

  const ProjectSettingsTab({super.key, required this.server, this.collection});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Overview Header Card
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: server.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.settings_outlined,
                        size: 20,
                        color: server.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Project Details',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            collection?.id != null && collection!.id.isNotEmpty
                                ? 'ID: ${collection!.id}'
                                : 'Server: ${server.id}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textDarkMuted
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (server.description.isNotEmpty) ...[
                  Text(
                    server.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder,
                ),
                const SizedBox(height: 10),
                _buildInfoRow(
                  label: 'Category',
                  value: collection?.collectionType ?? server.categoryLabel,
                  isDark: isDark,
                ),
                if (collection?.projectStatus != null &&
                    collection!.projectStatus!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    label: 'Status',
                    value: collection!.projectStatus!,
                    isDark: isDark,
                  ),
                ],
                if (collection?.privacyLevel != null &&
                    collection!.privacyLevel!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    label: 'Privacy',
                    value: collection!.privacyLevel!,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: 8),
                _buildInfoRow(
                  label: 'Participants',
                  value: '${server.memberCount} members',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Preferences & Notifications Card
          _buildCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications & Preferences',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSwitchRow(
                  title: 'Project Notifications',
                  subtitle:
                      'Receive updates on chat messages, goals, and milestones',
                  value: true,
                  identifier: 'project_settings_notifications_switch',
                  isDark: isDark,
                  onChanged: (val) {},
                ),
                Divider(
                  height: 1,
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder,
                ),
                _buildSwitchRow(
                  title: 'Mute Chat Sounds',
                  subtitle: 'Silence alerts during group conversations',
                  value: false,
                  identifier: 'project_settings_sound_switch',
                  isDark: isDark,
                  onChanged: (val) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contact & Links (if available)
          if (collection?.websiteLink != null ||
              collection?.contactEmail != null ||
              collection?.contactName != null) ...[
            _buildCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contact & Links',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textDarkPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (collection?.contactName != null &&
                      collection!.contactName!.isNotEmpty)
                    _buildInfoRow(
                      label: 'Contact',
                      value: collection!.contactName!,
                      isDark: isDark,
                    ),
                  if (collection?.contactEmail != null &&
                      collection!.contactEmail!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      label: 'Email',
                      value: collection!.contactEmail!,
                      isDark: isDark,
                    ),
                  ],
                  if (collection?.websiteLink != null &&
                      collection!.websiteLink!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      label: 'Website',
                      value: collection!.websiteLink!,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child, required bool isDark}) {
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required String subtitle,
    required bool value,
    required String identifier,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: isDark
                        ? AppColors.textDarkMuted
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            identifier: identifier,
            child: Switch(
              value: value,
              activeThumbColor: server.primaryColor,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
