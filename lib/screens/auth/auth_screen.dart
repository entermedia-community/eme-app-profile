import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth/auth_modal_sheet.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AuthScreen());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo / Branding Header
                  // flutter_svg ignores SVG filters, so the logo's drop
                  // shadow is drawn here from a blurred, darkened copy.
                  Center(
                    child: Stack(
                      children: [
                        Transform.translate(
                          offset: const Offset(2, 3),
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                            child: SvgPicture.asset(
                              'assets/icon/logo.svg',
                              width: 240,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.4),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        SvgPicture.asset('assets/icon/logo.svg', width: 240),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Collective Intelligence Economy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Auth Card Container
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkCardBorder
                            : AppColors.lightCardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.06,
                          ),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const AuthModalSheet(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
