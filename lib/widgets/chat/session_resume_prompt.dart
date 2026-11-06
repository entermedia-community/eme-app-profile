import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

/// "3 days ago" style age of [since], for the resume prompt.
String sessionAgeLabel(DateTime since, {DateTime? now}) {
  final age = (now ?? DateTime.now()).difference(since);
  String unit(int n, String word) => '$n $word${n == 1 ? '' : 's'} ago';
  if (age.inDays >= 1) return unit(age.inDays, 'day');
  if (age.inHours >= 1) return unit(age.inHours, 'hour');
  return unit(age.inMinutes, 'minute');
}

/// Shown at the end of a chat that opened in a session left idle for a while:
/// continue it, or start a new session.
class SessionResumePrompt extends StatelessWidget {
  final DateTime lastActive;
  final Color accent;
  final bool isDark;
  final bool busy;
  final VoidCallback onContinue;
  final VoidCallback onNewSession;

  const SessionResumePrompt({
    super.key,
    required this.lastActive,
    required this.accent,
    required this.isDark,
    required this.onContinue,
    required this.onNewSession,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.only(bottom: 14, top: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This session was last active ${sessionAgeLabel(lastActive)}.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Continue it, or start a new session?',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Semantics(
                  identifier: 'session_resume_continue',
                  child: OutlinedButton(
                    onPressed: busy ? null : onContinue,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(color: accent),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  identifier: 'session_resume_new',
                  child: FilledButton(
                    onPressed: busy ? null : onNewSession,
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('New session'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
