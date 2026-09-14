import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/server_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pill_badge.dart';
import '../profile/widgets/category_filter_bar.dart';
import 'widgets/individual_card.dart';

class EmeWorldScreen extends ConsumerStatefulWidget {
  const EmeWorldScreen({super.key});

  @override
  ConsumerState<EmeWorldScreen> createState() => _EmeWorldScreenState();
}

class _EmeWorldScreenState extends ConsumerState<EmeWorldScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final individuals = serverState.filteredIndividuals;
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
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Global network connecting verified specialists, researchers, and independent service providers offering decentralized services.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Network Telemetry Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
                _buildMetricItem(
                  'Specialists',
                  '${serverState.individualCount}',
                  AppColors.primary,
                ),
                _buildDivider(isDark),
                _buildMetricItem('Verified', '100%', AppColors.greenAccent),
                _buildDivider(isDark),
                _buildMetricItem('Countries', '12', const Color(0xFF8B5CF6)),
                _buildDivider(isDark),
                _buildMetricItem('Services', '18+', const Color(0xFFF59E0B)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Search Input Bar
          TextField(
            controller: _searchController,
            onChanged: (val) {
              ref.read(serverProvider.notifier).setSearchQuery(val);
            },
            decoration: InputDecoration(
              hintText:
                  'Search specialists by name, skill, service, or location...',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(serverProvider.notifier).setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Category Chips Bar
          const CategoryFilterBar(),

          const SizedBox(height: 20),

          // Directory Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Specialists Directory',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '${individuals.length} specialists',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Individuals Grid
          if (individuals.isEmpty)
            _buildEmptyState(context, isDark)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                final crossAxisCount = isTablet ? 3 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: individuals.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: isTablet ? 0.72 : 0.58,
                  ),
                  itemBuilder: (context, index) {
                    final item = individuals[index];
                    return IndividualCard(specialist: item);
                  },
                );
              },
            ),

          const SizedBox(height: 24),

          // Featured Ecosystem Updates Section
          Text(
            'Featured Ecosystem Updates',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
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
            fontSize: 17,
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

  Widget _buildDivider(bool isDark) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.person_search_rounded,
            size: 48,
            color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No specialists found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search query or selected category.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              ref.read(serverProvider.notifier).setCategory('All');
              ref.read(serverProvider.notifier).setSearchQuery('');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset All Filters'),
          ),
        ],
      ),
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
