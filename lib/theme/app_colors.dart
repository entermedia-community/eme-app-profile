import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF2563EB); // Vibrant Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryBg = Color(0xFFEFF6FF);

  // Accent & Action colors (matching mockup)
  static const Color greenAccent = Color(0xFF22C55E); // FAB Green
  static const Color greenButtonBg = Color(0xFF86EFAC); // Light green for "Open Chat"
  static const Color greenButtonDarkBg = Color(0xFF166534);
  static const Color greenButtonText = Color(0xFF14532D);
  static const Color blueButtonBg = Color(0xFF3B82F6); // Blue for "Edit Profile"
  static const Color blueButtonText = Colors.white;

  // Backgrounds & Surfaces (Light)
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightCardBorder = Color(0xFFE2E8F0);
  static const Color lightCardShadow = Color(0x0D000000);

  // Backgrounds & Surfaces (Dark)
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCardBorder = Color(0xFF334155);
  static const Color darkCardShadow = Color(0x33000000);

  // Text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color textDarkPrimary = Color(0xFFF8FAFC);
  static const Color textDarkSecondary = Color(0xFF94A3B8);
  static const Color textDarkMuted = Color(0xFF64748B);

  // Category & Badge colors
  static const Color tagBg = Color(0xFFE2E8F0);
  static const Color tagText = Color(0xFF475569);
  
  static const Color badgeSocialBg = Color(0xFFDBEAFE);
  static const Color badgeSocialText = Color(0xFF1E40AF);

  static const Color badgeEcoBg = Color(0xFFDCFCE7);
  static const Color badgeEcoText = Color(0xFF166534);

  static const Color badgeStartupBg = Color(0xFFF3E8FF);
  static const Color badgeStartupText = Color(0xFF6B21A8);

  static const Color badgeAIBg = Color(0xFFFCE7F3);
  static const Color badgeAIText = Color(0xFF9D174D);

  static const Color badgeFinanceBg = Color(0xFFFEF3C7);
  static const Color badgeFinanceText = Color(0xFF92400E);
}
