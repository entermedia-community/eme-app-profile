import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pill_badge.dart';

class EmeWorldScreen extends StatelessWidget {
  const EmeWorldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'EME Worldwide',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Decentralized collective intelligence and global collaboration network.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 16),

          // Network Metrics
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.darkCardBorder
                    : AppColors.lightCardBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricItem('Countries', '12', AppColors.primary),
                Container(
                  width: 1,
                  height: 36,
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder,
                ),
                _buildMetricItem('Users', '1420', AppColors.greenAccent),
                Container(
                  width: 1,
                  height: 36,
                  color: isDark
                      ? AppColors.darkCardBorder
                      : AppColors.lightCardBorder,
                ),
                _buildMetricItem('Documents', '18.5k', const Color(0xFF8B5CF6)),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Trending Discussions / News
          Text(
            'Featured Ecosystem Updates',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          _buildUpdateCard(
            context,
            isDark: isDark,
            title: 'Atitlan Lake Bio-credit verification goes live',
            category: 'Eco Tourism',
            date: '3 hours ago',
            reads: '420 reads',
            description:
                'Community nodes around Lake Atitlan have successfully validated the first batch of water-quality bio-credits on the decentralized registry.',
          ),

          const SizedBox(height: 12),

          _buildUpdateCard(
            context,
            isDark: isDark,
            title: 'Impact Bank rolls out mobile wallet integration',
            category: 'Finance',
            date: 'Yesterday',
            reads: '1.2k reads',
            description:
                'New biometric passport issuance module enabled for cross-border humanitarian missions with zero transaction fees.',
          ),

          const SizedBox(height: 12),

          _buildUpdateCard(
            context,
            isDark: isDark,
            title: 'Circular Panchayat of India announces Rural Hackathon',
            category: 'Social Services',
            date: 'Sep 8, 2026',
            reads: '980 reads',
            description:
                'Over \$50,000 in micro-grants available for local teams building decentralized agricultural telemetry and waste recycling loops.',
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateCard(
    BuildContext context, {
    required bool isDark,
    required String title,
    required String category,
    required String date,
    required String reads,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PillBadge.forCategory(category, isDark: isDark),
              Text(
                '$date • $reads',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
