import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/server_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_colors.dart';
import '../profile/widgets/add_server_sheet.dart';
import '../profile/widgets/server_card.dart';

class ServerPickerScreen extends ConsumerStatefulWidget {
  const ServerPickerScreen({super.key});

  @override
  ConsumerState<ServerPickerScreen> createState() => _ServerPickerScreenState();
}

class _ServerPickerScreenState extends ConsumerState<ServerPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedScope = 'all'; // 'all', 'available', 'joined'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddServerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddServerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Filter servers based on search, category, and scope
    final servers = serverState.servers.where((item) {
      // Scope filter
      if (_selectedScope == 'available' && item.isJoined) return false;
      if (_selectedScope == 'joined' && !item.isJoined) return false;

      // Category filter
      if (_selectedCategory != 'All' &&
          item.category.label != _selectedCategory &&
          !item.tags.contains(_selectedCategory)) {
        return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final titleMatch = item.title.toLowerCase().contains(q);
        final subtitleMatch = item.subtitle?.toLowerCase().contains(q) ?? false;
        final descMatch = item.description.toLowerCase().contains(q);
        final tagMatch = item.tags.any((t) => t.toLowerCase().contains(q));
        final srvMatch = item.servicesOffered.any(
          (s) => s.toLowerCase().contains(q),
        );
        final locMatch = item.location?.toLowerCase().contains(q) ?? false;
        if (!titleMatch &&
            !subtitleMatch &&
            !descMatch &&
            !tagMatch &&
            !srvMatch &&
            !locMatch) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pick a Server',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
            Text(
              'Discover & join collective intelligence nodes',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
            tooltip: 'Add Custom Server',
            color: AppColors.primary,
            onPressed: () => _openAddServerSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
              decoration: InputDecoration(
                hintText: 'Search servers by title, tags, or topic...',
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
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Category Horizontal List
            _buildCategorySelector(isDark),

            const SizedBox(height: 12),

            // Servers Grid
            if (servers.isEmpty)
              _buildEmptyState(isDark)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth > 600;
                  final crossAxisCount = isTablet ? 3 : 2;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: servers.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1,
                    ),
                    itemBuilder: (context, index) {
                      return ServerCard(server: servers[index]);
                    },
                  );
                },
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kServerCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = kServerCategories[index];
          final isSelected = cat == _selectedCategory;

          return InkWell(
            onTap: () {
              setState(() => _selectedCategory = cat);
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.primary : const Color(0xFF64748B))
                    : (isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark
                            ? AppColors.darkCardBorder
                            : AppColors.lightCardBorder),
                ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                              ? AppColors.textDarkSecondary
                              : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 44,
            color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            'No matching servers found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try clearing your search filters or add a new custom server.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _selectedCategory = 'All';
                    _selectedScope = 'all';
                  });
                },
                child: const Text('Reset Filters'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _openAddServerSheet(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Server'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
