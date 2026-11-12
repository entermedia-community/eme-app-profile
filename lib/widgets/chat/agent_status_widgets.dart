import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

/// Shown inside an agent's reply while the server is still building it:
/// a spinner with a label while the agent works ([MessageStatus.working]),
/// typing dots while reply text arrives ([MessageStatus.streaming]).
/// Renders nothing for a finished message or one without a status.
///
/// [id] must be unique on the screen (use the message id); it becomes the
/// Semantics identifier `agent_status_$id`, which a test can wait to vanish.
class AgentStatusIndicator extends StatelessWidget {
  final String id;
  final MessageStatus? status;

  const AgentStatusIndicator({super.key, required this.id, this.status});

  @override
  Widget build(BuildContext context) {
    final current = status;
    if (current == null || !current.isActive) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textDarkMuted : AppColors.textMuted;

    return Semantics(
      identifier: 'agent_status_$id',
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: current == MessageStatus.streaming
            ? TypingDots(color: muted)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: muted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Working…',
                    style: GoogleFonts.inter(fontSize: 12, color: muted),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Three dots that pulse one after the other.
class TypingDots extends StatefulWidget {
  final Color color;
  const TypingDots({super.key, required this.color});

  @override
  State<TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                child: Opacity(
                  opacity: _opacity(i),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Each dot is brightest a third of the cycle after the one before it.
  double _opacity(int dot) {
    final phase = (_controller.value - dot / 3) % 1.0;
    return phase < 1 / 3 ? 1.0 : 0.3;
  }
}
