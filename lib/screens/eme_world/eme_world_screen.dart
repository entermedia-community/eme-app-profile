import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/server_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/pill_badge.dart';
import '../profile/widgets/category_filter_bar.dart';
import '../profile/widgets/server_card.dart';
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
    final catalog = serverState.filteredCatalog;
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
            'Global marketplace connecting collective intelligence servers & verified specialists offering decentralized services.',
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
                  'Teams',
                  '${serverState.serverCount}',
                  AppColors.primary,
                ),
                _buildDivider(isDark),
                _buildMetricItem('Users', '60', AppColors.greenAccent),
                _buildDivider(isDark),
                _buildMetricItem('Countries', '12', const Color(0xFF8B5CF6)),
                _buildDivider(isDark),
                _buildMetricItem('Documents', '50K+', const Color(0xFFF59E0B)),
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
              hintText: 'Search teams, specialists, services, or locations...',
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

          // Type Segmented Filter (All, Servers, Specialists)
          _buildTypeFilterSelector(serverState, isDark),

          const SizedBox(height: 14),

          // Category Chips Bar
          const CategoryFilterBar(),

          const SizedBox(height: 20),

          // Featured Ecosystem Spotlight Carousel / Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Marketplace Directory',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textPrimary,
                ),
              ),
              Text(
                '${catalog.length} results',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Entity Catalog Grid
          if (catalog.isEmpty)
            _buildEmptyState(context, isDark)
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final isTablet = constraints.maxWidth > 600;
                final crossAxisCount = isTablet ? 3 : 2;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: catalog.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: isTablet ? 0.72 : 0.58,
                  ),
                  itemBuilder: (context, index) {
                    final item = catalog[index];
                    if (item.isIndividual) {
                      return IndividualCard(specialist: item);
                    }
                    return ServerCard(server: item);
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

  Widget _buildTypeFilterSelector(ServerState serverState, bool isDark) {
    final types = [
      {
        'id': 'All',
        'label': 'All Services',
        'icon': Icons.apps_rounded,
        'count': serverState.servers.length,
      },
      {
        'id': 'Servers',
        'label': 'Servers',
        'icon': Icons.dns_rounded,
        'count': serverState.serverCount,
      },
      {
        'id': 'Specialists',
        'label': 'Specialists',
        'icon': Icons.person_search_rounded,
        'count': serverState.individualCount,
      },
    ];

    return Row(
      children: types.map((t) {
        final isSelected = serverState.selectedType == t['id'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () {
                ref
                    .read(serverProvider.notifier)
                    .setTypeFilter(t['id'] as String);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.darkCardBorder
                              : AppColors.lightCardBorder),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 15,
                      color: isSelected
                          ? Colors.white
                          : (isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textSecondary),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '${t['label']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? AppColors.textDarkPrimary
                                    : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
            Icons.search_off_rounded,
            size: 48,
            color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No services or specialists found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search query, type filter, or selected category.',
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
              ref.read(serverProvider.notifier).setTypeFilter('All');
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
