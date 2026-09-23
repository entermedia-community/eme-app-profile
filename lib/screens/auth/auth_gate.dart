import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import '../main_shell_screen.dart';
import 'auth_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. If authenticated, render Main App Shell
    if (authState.isAuthenticated) {
      return const MainShellScreen();
    }

    // 2. If checking existing session on app startup (and not interacting with OTP/register), show Splash Loading
    if (authState.status == AuthStatus.authenticating &&
        authState.email == null &&
        authState.user == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icon/logo.svg',
                width: 140,
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                'EME World',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. User is not authenticated -> enforce Sign-in flow
    return const AuthScreen();
  }
}
