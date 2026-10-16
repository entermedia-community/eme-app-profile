import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class DeltaViewer extends StatefulWidget {
  final List<dynamic> deltaOps;
  final Function(String link, Map<String, dynamic> data)? onLinkTap;
  const DeltaViewer({super.key, required this.deltaOps, this.onLinkTap});
  @override
  State<DeltaViewer> createState() => _DeltaViewerState();
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              ..onTap = () => widget.onLinkTap?.call(link, data);
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
          link: TextStyle(decoration: TextDecoration.none),
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
