import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import 'event_screen.dart';

/// Form for creating a public event. The creator becomes the host and opens
/// the new event on success.
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CreateEventScreen()));
  }

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime? initial) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial ?? now),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final start = _start;
    if (start == null) {
      setState(() => _error = 'Pick a start date and time.');
      return;
    }
    final end = _end;
    if (end != null && end.isBefore(start)) {
      setState(() => _error = 'The end is before the start.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final event = await ref
          .read(apiServiceProvider)
          .createEvent(
            name: _name.text.trim(),
            startDate: start,
            endDate: end,
            description: _description.text.trim(),
            location: _location.text.trim(),
          );
      ref.invalidate(userEventsProvider);
      if (!mounted) return;
      final navigator = Navigator.of(context);
      navigator.pushReplacement(EventScreen.route(event));
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'CreateEventScreen.submit failed',
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$e';
        });
      }
    }
  }

  Widget _dateField({
    required String id,
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Semantics(
      identifier: id,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.schedule_rounded),
        title: Text(label),
        subtitle: Text(value == null ? 'Not set' : formatEventDate(value)),
        trailing: onClear != null && value != null
            ? Semantics(
                identifier: '${id}_clear',
                child: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Clear',
                  onPressed: onClear,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create event',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Semantics(
              identifier: 'create_event_name',
              child: TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Event name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Give the event a name'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            _dateField(
              id: 'create_event_start',
              label: 'Starts',
              value: _start,
              onTap: () async {
                final picked = await _pickDateTime(_start);
                if (picked != null) setState(() => _start = picked);
              },
            ),
            _dateField(
              id: 'create_event_end',
              label: 'Ends (optional)',
              value: _end,
              onTap: () async {
                final picked = await _pickDateTime(_end ?? _start);
                if (picked != null) setState(() => _end = picked);
              },
              onClear: () => setState(() => _end = null),
            ),
            Semantics(
              identifier: 'create_event_location',
              child: TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Location (optional)',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              identifier: 'create_event_description',
              child: TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.redAccent,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Semantics(
              identifier: 'create_event_submit',
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
