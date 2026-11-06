import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

/// Lets the learner pick a topic, then one of its tutorials. Both lists come
/// from the EME Server at [baseUrl]; a failure is shown, never papered over.
/// Returns the chosen tutorial, or null when dismissed.
Future<TutorialSummary?> showTutorialPicker(
  BuildContext context, {
  required IApiService api,
  required Color accent,
  String? baseUrl,
}) {
  return showModalBottomSheet<TutorialSummary>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        TutorialPickerSheet(api: api, accent: accent, baseUrl: baseUrl),
  );
}

class TutorialPickerSheet extends StatefulWidget {
  final IApiService api;
  final Color accent;
  final String? baseUrl;

  const TutorialPickerSheet({
    super.key,
    required this.api,
    required this.accent,
    this.baseUrl,
  });

  @override
  State<TutorialPickerSheet> createState() => _TutorialPickerSheetState();
}

class _TutorialPickerSheetState extends State<TutorialPickerSheet> {
  TutorialTopic? _topic;
  late Future<List<Object>> _items;

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<List<Object>> _load() {
    final topic = _topic;
    return topic == null
        ? widget.api.fetchTutorialTopics(baseUrl: widget.baseUrl)
        : widget.api.fetchTutorials(topic.id, baseUrl: widget.baseUrl);
  }

  void _open(TutorialTopic? topic) {
    setState(() {
      _topic = topic;
      _items = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final muted = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textSecondary;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 20, 8),
              child: Row(
                children: [
                  if (_topic != null)
                    Semantics(
                      identifier: 'tutorial_picker_back',
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => _open(null),
                      ),
                    )
                  else
                    const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _topic?.title ?? 'Tutorials',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<List<Object>>(
                future: _items,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return _message(
                      'Could not load ${_topic == null ? 'topics' : 'tutorials'}.\n${snapshot.error}',
                      muted,
                      retry: () => setState(() => _items = _load()),
                    );
                  }
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return _message(
                      _topic == null
                          ? 'This server has no tutorials.'
                          : 'This topic has no tutorials.',
                      muted,
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, i) =>
                        _tile(items[i], primary, muted),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String text, Color color, {VoidCallback? retry}) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: color),
        ),
        if (retry != null)
          Semantics(
            identifier: 'tutorial_picker_retry',
            child: TextButton(onPressed: retry, child: const Text('Retry')),
          ),
      ],
    ),
  );

  Widget _tile(Object item, Color primary, Color muted) {
    if (item is TutorialTopic) {
      return Semantics(
        identifier: 'tutorial_topic_${item.id}',
        child: ListTile(
          leading: Icon(Icons.folder_outlined, color: widget.accent),
          title: Text(item.title, style: GoogleFonts.inter(color: primary)),
          subtitle: item.description.isEmpty
              ? null
              : Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: muted),
                ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _open(item),
        ),
      );
    }
    final tutorial = item as TutorialSummary;
    return Semantics(
      identifier: 'tutorial_item_${tutorial.id}',
      child: ListTile(
        leading: Icon(Icons.school_outlined, color: widget.accent),
        title: Text(tutorial.title, style: GoogleFonts.inter(color: primary)),
        subtitle: tutorial.totalSections == 0
            ? null
            : Text(
                '${tutorial.completedSections}/${tutorial.totalSections} sections',
                style: GoogleFonts.inter(fontSize: 12, color: muted),
              ),
        trailing: const Icon(Icons.play_arrow_rounded),
        onTap: () => Navigator.of(context).pop(tutorial),
      ),
    );
  }
}
