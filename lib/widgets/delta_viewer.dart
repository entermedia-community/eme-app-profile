import 'dart:convert';

import 'package:eme_world/theme/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class DeltaViewer extends StatefulWidget {
  final List<dynamic> deltaOps;
  final Function(String link, Map<String, dynamic> data) onLinkTap;
  const DeltaViewer({
    super.key,
    required this.deltaOps,
    required this.onLinkTap,
  });
  @override
  State<DeltaViewer> createState() => _DeltaViewerState();

  /// Custom attribute the server sets on the text op of its interim
  /// "Analyzing…" status message (AgentJobManager.handleStatusUpdate).
  static const processingAttribute = 'processing';

  /// The status text when [ops] is the server's interim processing message
  /// (text ops marked with the [processingAttribute] attribute), else null.
  /// The real answer later replaces this message under the same id.
  static String? processingText(List<dynamic> ops) {
    final buffer = StringBuffer();
    var marked = false;
    for (final op in ops) {
      if (op is! Map || op['insert'] is! String) return null;
      final attrs = op['attributes'];
      print("======");
      print(attrs);
      if (attrs is Map && attrs[processingAttribute] == true) {
        marked = true;
        buffer.write(op['insert']);
      }
    }
    if (!marked) return null;
    final result = buffer.toString().trim();
    return result.isEmpty ? null : result;
  }
}

class _DeltaViewerState extends State<DeltaViewer> {
  late final QuillController _controller;

  @override
  void initState() {
    super.initState();

    _controller = QuillController(
      document: Document.fromJson(widget.deltaOps),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
    );
  }

  /// The ops of a message that is still being built up change under the same
  /// widget, so the document is rebuilt from them when they differ.
  @override
  void didUpdateWidget(DeltaViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.deltaOps, widget.deltaOps)) return;
    if (jsonEncode(oldWidget.deltaOps) == jsonEncode(widget.deltaOps)) return;
    _controller.document = Document.fromJson(widget.deltaOps);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final processing = DeltaViewer.processingText(widget.deltaOps);
    if (processing != null) return _ProcessingMessage(text: processing);
    return QuillEditor.basic(
      controller: _controller,
      config: QuillEditorConfig(
        showCursor: false,
        customRecognizerBuilder: (attribute, leaf) {
          if (attribute.key == 'link') {
            final link = attribute.value as String;
            final attributes = leaf.style.attributes;
            Map<String, dynamic> data = {};
            for (var key in attributes.keys) {
              if (key.startsWith("data-")) {
                final val = attributes[key]?.value;
                if (val is String) {
                  data[key.substring(5)] = val;
                }
              }
            }

            return TapGestureRecognizer()
              ..onTap = () => widget.onLinkTap.call(link, data);
          }
          return null;
        },
        padding: EdgeInsets.all(16),
        // remove underline from link
        // customStyleBuilder: (attribute) {
        //   if (attribute.key == 'link') {
        //     return TextStyle(
        //       color: Colors.pink,
        //       decoration: TextDecoration.none,
        //     );
        //   }
        //   return TextStyle();
        // },
        customStyles: DefaultStyles(
          link: TextStyle(
            decoration: TextDecoration.none,
            color: AppColors.greenAccent,
          ),
          // paragraph: DefaultTextBlockStyle(
          //   TextStyle(fontSize: 14),
          //   HorizontalSpacing.zero,
          //   VerticalSpacing(4, 8),
          //   VerticalSpacing.zero,
          //   null,
          // ),
        ),
      ),
    );
  }
}

class _ProcessingMessage extends StatelessWidget {
  final String text;
  const _ProcessingMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text.endsWith('...') || text.endsWith('…') ? text : '$text…',
              style: TextStyle(fontSize: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
