import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PillBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final BorderSide? border;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Widget? icon;

  const PillBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.border,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.onTap,
    this.icon,
  });

  factory PillBadge.forCategory(
    String category, {
    bool isDark = false,
    VoidCallback? onTap,
    double fontSize = 11,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  }) {
    Color bg;
    Color fg;

    switch (category.toLowerCase()) {
      case 'social services':
        bg = isDark ? const Color(0xFF1E3A8A) : AppColors.badgeSocialBg;
        fg = isDark ? const Color(0xFF93C5FD) : AppColors.badgeSocialText;
        break;
      case 'eco tourism':
        bg = isDark ? const Color(0xFF064E3B) : AppColors.badgeEcoBg;
        fg = isDark ? const Color(0xFF86EFAC) : AppColors.badgeEcoText;
        break;
      case 'startup':
        bg = isDark ? const Color(0xFF581C87) : AppColors.badgeStartupBg;
        fg = isDark ? const Color(0xFFD8B4FE) : AppColors.badgeStartupText;
        break;
      case 'artificial intelligence':
        bg = isDark ? const Color(0xFF831843) : AppColors.badgeAIBg;
        fg = isDark ? const Color(0xFFF472B6) : AppColors.badgeAIText;
        break;
      case 'finance':
        bg = isDark ? const Color(0xFF78350F) : AppColors.badgeFinanceBg;
        fg = isDark ? const Color(0xFFFBBF24) : AppColors.badgeFinanceText;
        break;
      default:
        bg = isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9);
        fg = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    }

    return PillBadge(
      label: category,
      backgroundColor: bg,
      textColor: fg,
      fontSize: fontSize,
      padding: padding,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final defaultFg = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF475569);
    final effectiveBg = backgroundColor ?? defaultBg;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: effectiveBg,
          borderRadius: BorderRadius.circular(20),
          border: border != null
              ? Border.fromBorderSide(border!)
              : Border.all(
                  color: effectiveBg.withValues(alpha: 0.4),
                  width: 0.5,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? defaultFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
