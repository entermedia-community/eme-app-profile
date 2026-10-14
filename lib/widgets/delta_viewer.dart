import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class DeltaViewer extends StatefulWidget {
  final List<dynamic> deltaOps;
  const DeltaViewer({super.key, required this.deltaOps});
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
        onLaunchUrl: (String url) async {
          final uri = Uri.parse(url);
          print(uri);
        },
        showCursor: false,
        padding: EdgeInsets.all(16),
      ),
    );
  }
}
