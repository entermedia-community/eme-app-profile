import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../providers/eme_profile_provider.dart';
import '../../../theme/app_colors.dart';

class EmeProfileCategoryFilterBar extends ConsumerWidget {
  const EmeProfileCategoryFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(emeProfileProvider);
    final selectedCategory = profileState.selectedCategory;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: kEmeProfileCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = kEmeProfileCategories[index];
          final isSelected = category == selectedCategory;

          return InkWell(
            onTap: () {
              ref.read(emeProfileProvider.notifier).setCategory(category);
            },
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: (isDark
                                  ? AppColors.primary
                                  : const Color(0xFF64748B))
                              .withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontSize: 12,
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
}
