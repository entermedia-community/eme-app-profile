import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/server_provider.dart';
import '../../../theme/app_colors.dart';
import 'category_filter_bar.dart';
import 'server_card.dart';

class ServersSection extends ConsumerStatefulWidget {
  const ServersSection({super.key});

  @override
  ConsumerState<ServersSection> createState() => _ServersSectionState();
}

class _ServersSectionState extends ConsumerState<ServersSection> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final filteredServers = serverState.filteredServers;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: "Collective Intelligence Servers"
        Text(
          'Collective Intelligence Servers',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),

        const SizedBox(height: 10),

        // Informational Subtitle paragraph from Mockup
        Text(
          'Ready to turn your audience, platform, or idea into a profitable service? '
          'Partner with us to access powerful tools, earn commission, and deliver real value—without worrying about the tech.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? AppColors.textDarkSecondary : const Color(0xFF64748B),
            height: 1.5,
          ),
        ),

        const SizedBox(height: 18),

        // Quick Search Bar
        TextField(
          controller: _searchController,
          onChanged: (val) {
            ref.read(serverProvider.notifier).setSearchQuery(val);
          },
          decoration: InputDecoration(
            hintText: 'Search servers by name, tag, or mission...',
            hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        const SizedBox(height: 16),

        // Category Filter Chips
        const CategoryFilterBar(),

        const SizedBox(height: 20),

        // Servers Grid / List
        if (filteredServers.isEmpty)
          _buildEmptyState(context, isDark)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              final crossAxisCount = isTablet ? 3 : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredServers.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: isTablet ? 0.72 : 0.58,
                ),
                itemBuilder: (context, index) {
                  return ServerCard(server: filteredServers[index]);
                },
              );
            },
          ),
      ],
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
            'No servers found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search query or selected category filter.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
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
            child: const Text('Reset Filters'),
          ),
        ],
      ),
    );
  }
}
