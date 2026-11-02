import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class OtpInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final bool autoFocus;
  final bool enabled;

  const OtpInputField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.autoFocus = true,
    this.enabled = true,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(
      widget.length,
      (index) => FocusNode(onKeyEvent: (_, event) => _onKey(index, event)),
    );

    if (widget.autoFocus && _focusNodes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.enabled) {
          _focusNodes[0].requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _currentCode {
    return _controllers.map((c) => c.text).join();
  }

  /// Fills every box from [text] if, once trimmed, it is exactly
  /// `widget.length` digits. Otherwise shows an error and changes nothing.
  void _handlePaste(String text) {
    final pasted = text.trim();
    if (!RegExp('^\\d{${widget.length}}\$').hasMatch(pasted)) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Pasted text must be a ${widget.length}-digit code'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      return;
    }

    for (int i = 0; i < widget.length; i++) {
      _controllers[i].text = pasted[i];
    }
    _focusNodes[widget.length - 1].unfocus();
    widget.onChanged?.call(_currentCode);
    setState(() {});
  }

  /// Detects a multi-character insertion into a single box and routes it to
  /// [_handlePaste] instead of letting it land in the box.
  TextInputFormatter _inputFormatter(int index) {
    return TextInputFormatter.withFunction((oldValue, newValue) {
      final isPaste =
          newValue.text.length > 1 &&
          (newValue.text.length - oldValue.text.length > 1 ||
              !oldValue.selection.isCollapsed);
      if (!isPaste) {
        // Typing over an already-filled box: take the new digit and advance,
        // even when it equals the old one (no onChanged would fire then).
        if (newValue.text.length == 2 && oldValue.text.length == 1) {
          final offset = newValue.selection.baseOffset.clamp(1, 2);
          final typed = newValue.text[offset - 1];
          if (!RegExp(r'\d').hasMatch(typed)) return oldValue;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _advanceFrom(index);
          });
          return TextEditingValue(
            text: typed,
            selection: const TextSelection.collapsed(offset: 1),
          );
        }
        return newValue;
      }

      final text = newValue.text;
      // Formatters run mid-edit; apply the paste after the frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _handlePaste(text);
      });
      return oldValue;
    });
  }

  /// Runs on the focus node itself, ahead of the TextField's own backspace
  /// handling (which swallows the key when the box is already empty).
  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_controllers[index].text.isNotEmpty) {
      // Delete this digit, then step back.
      _controllers[index].clear();
    } else if (index > 0) {
      _controllers[index - 1].clear();
    } else {
      return KeyEventResult.ignored;
    }
    if (index > 0) _focusNodes[index - 1].requestFocus();
    widget.onChanged?.call(_currentCode);
    setState(() {});
    return KeyEventResult.handled;
  }

  void _advanceFrom(int index) {
    if (index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) _advanceFrom(index);

    widget.onChanged?.call(_currentCode);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boxBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(widget.length, (index) {
            return SizedBox(
              width: 46,
              height: 56,
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textPrimary,
                ),
                inputFormatters: [
                  _inputFormatter(index),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: boxBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (val) => _onDigitChanged(index, val),
              ),
            );
          }),
        ),
      ],
    );
  }
}
