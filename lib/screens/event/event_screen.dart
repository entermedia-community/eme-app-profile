import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import '../../widgets/module_bottom_nav.dart';
import '../server/tabs/server_chat_tab.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Sat, Nov 2 · 9:00 AM" in the device's time zone.
String formatEventDate(DateTime date) {
  final local = date.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour < 12 ? 'AM' : 'PM';
  return '${_weekdays[local.weekday - 1]}, ${_months[local.month - 1]} '
      '${local.day} · $hour12:$minute $period';
}

/// An event, modeled after a Facebook event: a details tab (default) with
/// Interested / Going, and a chat tab to discuss it.
class EventScreen extends ConsumerStatefulWidget {
  final EventModel event;

  const EventScreen({super.key, required this.event});

  static Route<void> route(EventModel event) {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          EventScreen(event: event),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 280),
    );
  }

  @override
  ConsumerState<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<EventScreen> {
  static const _accent = Color(0xFFEA580C);
  static const _tabs = [
    ModuleNavItem(
      key: 'details',
      title: 'Details',
      icon: Icons.event_outlined,
      activeIcon: Icons.event_rounded,
    ),
    ModuleNavItem(
      key: 'chat',
      title: 'Chat',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
    ),
  ];

  late EventModel _event;
  String _tab = 'details';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _refresh();
  }

  /// Loads the event again for fresh counts; the list it came from can be old.
  Future<void> _refresh() async {
    try {
      final fresh = await ref.read(eventProvider(_event.id).future);
      if (mounted) setState(() => _event = fresh);
    } catch (e) {
      debugPrint('[EventScreen] refresh failed: $e');
    }
  }

  Future<void> _setRsvp(EventRsvp tapped) async {
    if (_saving) return;
    // Tapping the active response takes it back.
    final next = _event.myRsvp == tapped ? EventRsvp.none : tapped;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(apiServiceProvider)
          .setEventRsvp(_event.id, next);
      if (!mounted) return;
      setState(() {
        _event = _event.copyWith(
          goingCount: result.goingCount,
          interestedCount: result.interestedCount,
          myRsvp: result.myRsvp,
        );
      });
      ref.invalidate(userEventsProvider);
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'EventScreen.setRsvp failed',
        customKeys: {'eventId': _event.id},
      );
      if (mounted) setState(() => _error = 'Could not save your response: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// The chat tab reuses the server chat UI, which wants a server.
  ServerModel get _chatServer => ServerModel(
    id: _event.id,
    name: _event.name,
    description: _event.description,
    category: const ServerCategoryModel(id: 'event', name: 'Event'),
    primaryColor: _accent,
    avatarUrl: _event.imageUrl,
    serverMediaDBUrl: '',
    memberCount: _event.goingCount,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'event_back_button',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        titleSpacing: 0,
        title: Text(
          _event.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _tab == 'chat'
            ? ServerChatTab(
                key: ValueKey('event_chat_${_event.id}'),
                server: _chatServer,
                eventId: _event.id,
              )
            : _buildDetails(isDark),
      ),
      bottomNavigationBar: ModuleBottomNav(
        items: _tabs,
        activeKey: _tab,
        color: _accent,
        idPrefix: 'event_nav',
        onSelect: (key) => setState(() => _tab = key),
      ),
    );
  }

  Widget _buildDetails(bool isDark) {
    final secondary = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textSecondary;
    final primary = isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final start = _event.startDate;
    final end = _event.endDate;

    return ListView(
      key: const ValueKey('event_details'),
      children: [
        _buildCover(isDark),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (start != null)
                Text(
                  formatEventDate(start).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _accent,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                _event.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_event.goingCount} going · '
                '${_event.interestedCount} interested',
                style: GoogleFonts.inter(fontSize: 13, color: secondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildRsvpButton(
                      id: 'event_rsvp_interested',
                      label: 'Interested',
                      icon: Icons.star_outline_rounded,
                      activeIcon: Icons.star_rounded,
                      selected: _event.myRsvp == EventRsvp.interested,
                      onTap: () => _setRsvp(EventRsvp.interested),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildRsvpButton(
                      id: 'event_rsvp_going',
                      label: 'Going',
                      icon: Icons.check_circle_outline_rounded,
                      activeIcon: Icons.check_circle_rounded,
                      selected: _event.myRsvp == EventRsvp.going,
                      onTap: () => _setRsvp(EventRsvp.going),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.redAccent,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (start != null)
                _buildInfoRow(
                  Icons.schedule_rounded,
                  end == null
                      ? formatEventDate(start)
                      : '${formatEventDate(start)} – ${formatEventDate(end)}',
                  secondary,
                  primary,
                ),
              if (_event.location.isNotEmpty)
                _buildInfoRow(
                  Icons.place_outlined,
                  _event.location,
                  secondary,
                  primary,
                ),
              if (_event.hostName != null)
                _buildInfoRow(
                  Icons.person_outline_rounded,
                  'Hosted by ${_event.hostName}',
                  secondary,
                  primary,
                ),
              if (_event.description.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'About',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _event.description,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCover(bool isDark) {
    final url = _event.imageUrl;
    final placeholder = Container(
      height: 180,
      color: _accent.withValues(alpha: isDark ? 0.25 : 0.14),
      alignment: Alignment.center,
      child: const Icon(Icons.event_rounded, size: 56, color: _accent),
    );
    if (url == null || url.isEmpty) return placeholder;
    return Image.network(
      url,
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String text,
    Color iconColor,
    Color textColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 14, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRsvpButton({
    required String id,
    required String label,
    required IconData icon,
    required IconData activeIcon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(selected ? activeIcon : icon, size: 18),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
    return Semantics(
      identifier: id,
      child: selected
          ? FilledButton(
              onPressed: _saving ? null : onTap,
              style: FilledButton.styleFrom(backgroundColor: _accent),
              child: child,
            )
          : OutlinedButton(onPressed: _saving ? null : onTap, child: child),
    );
  }
}
