import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:flutter/material.dart' hide FormField;
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

String tutorialConfidenceLabel(TutorialConfidence c) => switch (c) {
  TutorialConfidence.noidea => 'No idea',
  TutorialConfidence.notsure => 'Not sure',
  TutorialConfidence.mostlysure => 'Mostly sure',
  TutorialConfidence.confident => 'Confident',
};

BoxDecoration _cardDecoration(bool isDark, {Color? border}) => BoxDecoration(
  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
    color:
        border ??
        (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
  ),
);

/// A tutorial multiple choice question: pick an option, say how sure you are,
/// submit. Once [enabled] is false it is read-only and, when [reveal] is set,
/// marks the right option and the learner's wrong pick.
class TutorialQuestionCard extends StatefulWidget {
  final TutorialQuestion question;
  final bool enabled;
  final bool reveal;
  final String? selectedOption;
  final TutorialConfidence? confidence;
  final Color accent;
  final bool isDark;
  final void Function(String option, TutorialConfidence confidence) onSubmit;

  const TutorialQuestionCard({
    super.key,
    required this.question,
    required this.enabled,
    required this.accent,
    required this.isDark,
    required this.onSubmit,
    this.reveal = false,
    this.selectedOption,
    this.confidence,
  });

  @override
  State<TutorialQuestionCard> createState() => _TutorialQuestionCardState();
}

class _TutorialQuestionCardState extends State<TutorialQuestionCard> {
  String? _option;
  TutorialConfidence? _confidence;

  String? get _shownOption => widget.enabled ? _option : widget.selectedOption;
  TutorialConfidence? get _shownConfidence =>
      widget.enabled ? _confidence : widget.confidence;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final isDark = widget.isDark;
    final primary = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final muted = isDark ? AppColors.textDarkMuted : AppColors.textMuted;
    final canSubmit = widget.enabled && _option != null && _confidence != null;

    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(
        isDark,
        border: widget.accent.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'QUESTION',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: widget.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            q.question,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          for (final entry in q.options.entries)
            _optionRow(entry.key, entry.value, primary),
          if (widget.enabled || _shownConfidence != null) ...[
            const SizedBox(height: 8),
            Text(
              'HOW SURE ARE YOU?',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: muted,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in TutorialConfidence.values)
                  _confidenceChip(c, primary),
              ],
            ),
          ],
          if (widget.enabled) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                identifier: 'tutorial_submit_${q.id}',
                child: FilledButton(
                  onPressed: canSubmit
                      ? () => widget.onSubmit(_option!, _confidence!)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Submit'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionRow(String key, String text, Color primary) {
    final q = widget.question;
    final selected = _shownOption == key;
    Color color = widget.accent;
    IconData? icon;
    if (widget.reveal && !widget.enabled) {
      if (q.isCorrectOption(key)) {
        color = AppColors.greenAccent;
        icon = Icons.check_circle_rounded;
      } else if (selected) {
        color = AppColors.redAccent;
        icon = Icons.cancel_rounded;
      }
    }
    final highlighted = selected || icon != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        identifier: 'tutorial_option_${q.id}_$key',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.enabled ? () => setState(() => _option = key) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: highlighted ? color.withValues(alpha: 0.12) : null,
              border: Border.all(
                color: highlighted
                    ? color
                    : (widget.isDark
                          ? AppColors.textDarkMuted
                          : AppColors.lightCardBorder),
              ),
            ),
            child: Row(
              children: [
                Text(
                  TutorialQuestion.letterOf(key),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: highlighted ? color : primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: primary,
                      height: 1.3,
                    ),
                  ),
                ),
                if (icon != null) Icon(icon, size: 18, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _confidenceChip(TutorialConfidence c, Color primary) {
    final selected = _shownConfidence == c;
    return Semantics(
      identifier: 'tutorial_confidence_${widget.question.id}_${c.name}',
      child: ChoiceChip(
        label: Text(tutorialConfidenceLabel(c)),
        selected: selected,
        showCheckmark: false,
        visualDensity: VisualDensity.compact,
        selectedColor: widget.accent.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: primary,
        ),
        onSelected: widget.enabled
            ? (_) => setState(() => _confidence = c)
            : null,
      ),
    );
  }
}

/// The tutor's verdict on an answer.
class TutorialEvalCard extends StatelessWidget {
  final String text;
  final bool? isCorrect;
  final bool isDark;

  const TutorialEvalCard({
    super.key,
    required this.text,
    required this.isCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect == null
        ? AppColors.primary
        : (isCorrect! ? AppColors.greenAccent : AppColors.redAccent);
    final icon = isCorrect == null
        ? Icons.chat_bubble_outline_rounded
        : (isCorrect! ? Icons.check_circle_rounded : Icons.cancel_rounded);
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.35,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when the tutor reports the tutorial is finished.
class TutorialEndCard extends StatelessWidget {
  final String text;
  final Color accent;
  final bool isDark;

  const TutorialEndCard({
    super.key,
    required this.text,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(
        isDark,
        border: accent.withValues(alpha: 0.4),
      ),
      child: Row(
        children: [
          Icon(Icons.emoji_events_rounded, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text.isEmpty ? 'Tutorial finished' : text,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
