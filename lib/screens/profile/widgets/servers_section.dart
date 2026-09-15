import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/server_provider.dart';
import '../../../theme/app_colors.dart';
import '../../server/server_picker_screen.dart';
import 'server_card.dart';

class ServersSection extends ConsumerStatefulWidget {
  const ServersSection({super.key});

  @override
  ConsumerState<ServersSection> createState() => _ServersSectionState();
}

class _ServersSectionState extends ConsumerState<ServersSection> {
  final TextEditingController _searchController = TextEditingController();
  String _localSearch = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToPicker(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ServerPickerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final joinedServers = serverState.joinedServers.where((s) {
      if (_localSearch.isEmpty) return true;
      final q = _localSearch.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          (s.subtitle?.toLowerCase().contains(q) ?? false) ||
          s.description.toLowerCase().contains(q) ||
          s.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search within joined servers (if there are 2 or more)
        if (serverState.joinedServers.length > 2) ...[
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _localSearch = val),
            decoration: InputDecoration(
              hintText: 'Filter your joined servers...',
              hintStyle: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _localSearch = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Servers Grid / List or Empty State
        if (joinedServers.isEmpty)
          _buildEmptyState(context, isDark, serverState.joinedServers.isEmpty)
        else ...[
          LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 600;
              final crossAxisCount = isTablet ? 3 : 2;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: joinedServers.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  return ServerCard(server: joinedServers[index]);
                },
              );
            },
          ),

          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    bool noServersAtAll,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              noServersAtAll ? Icons.dns_outlined : Icons.search_off_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            noServersAtAll ? 'No joined servers yet' : 'No matching servers',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            noServersAtAll
                ? 'Join collective intelligence servers and service providers from the network to collaborate.'
                : 'Try clearing your search query to see all your joined servers.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () {
              if (noServersAtAll) {
                _navigateToPicker(context);
              } else {
                _searchController.clear();
                setState(() => _localSearch = '');
              }
            },
            icon: Icon(
              noServersAtAll
                  ? Icons.travel_explore_rounded
                  : Icons.refresh_rounded,
              size: 18,
            ),
            label: Text(
              noServersAtAll ? 'Pick a Server' : 'Clear Filter',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
