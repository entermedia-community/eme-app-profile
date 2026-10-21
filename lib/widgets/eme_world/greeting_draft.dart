import 'package:eme_app_sdk/eme_app_sdk.dart';

/// What the signed-in user and another EME profile have in common.
class SharedWithProfile {
  /// Their tags/services that match one of the signed-in user's tags.
  final List<String> interests;

  /// Set when both have the same location.
  final String? location;

  const SharedWithProfile({this.interests = const [], this.location});

  bool get isEmpty => interests.isEmpty && location == null;
}

// Values the SDK fills in when a user has no tags; they aren't real interests.
const _placeholderTags = {'eme member'};

bool _isRealTag(String tag) {
  final t = tag.trim().toLowerCase();
  return t.isNotEmpty && !_placeholderTags.contains(t) && !t.contains('@');
}

List<String> _stringList(dynamic raw) {
  if (raw is List) return raw.map((e) => e.toString()).toList();
  if (raw is String && raw.trim().isNotEmpty) return raw.split(',');
  return const [];
}

String? _userLocation(EmUser? user) {
  final p = user?.properties ?? const <String, dynamic>{};
  final loc = (p['location'] ?? p['city'] ?? p['country'])?.toString().trim();
  return loc == null || loc.isEmpty ? null : loc;
}

/// Compares the signed-in user's own tags and location with [other]'s.
SharedWithProfile findShared({
  required EmUser? me,
  required ProfileModel myProfile,
  required EmeProfileModel other,
}) {
  final myTags = {
    ...myProfile.tags,
    ..._stringList(me?.properties['tags']),
  }.where(_isRealTag).map((t) => t.trim().toLowerCase()).toSet();

  final interests = <String>[];
  final seen = <String>{};
  for (final t in [...other.tags, ...other.servicesOffered]) {
    final key = t.trim().toLowerCase();
    if (_isRealTag(t) && myTags.contains(key) && seen.add(key)) {
      interests.add(t.trim());
    }
  }

  final myLoc = _userLocation(me);
  final theirLoc = other.location?.trim();
  final sameLocation =
      myLoc != null &&
      theirLoc != null &&
      myLoc.toLowerCase() == theirLoc.toLowerCase();

  return SharedWithProfile(
    interests: interests,
    location: sameLocation ? theirLoc : null,
  );
}

String _firstWord(String s) {
  final t = s.trim();
  return t.isEmpty ? t : t.split(RegExp(r'\s+')).first;
}

String _joinList(List<String> items) {
  if (items.length <= 1) return items.join();
  return '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';
}

/// Editable greeting for a first message to [other], mentioning [shared].
String buildGreetingDraft({
  required EmUser? me,
  required EmeProfileModel other,
  required SharedWithProfile shared,
}) {
  final theirName = _firstWord(other.name);
  final myName = _firstWord(
    (me?.firstname?.trim().isNotEmpty ?? false)
        ? me!.firstname!
        : (me?.displayName ?? ''),
  );

  final hello = theirName.isEmpty ? 'Hi' : 'Hi $theirName';
  final intro = myName.isEmpty ? '$hello!' : "$hello, I'm $myName.";

  if (shared.isEmpty) {
    return '$intro I came across your EME profile and would love to connect.';
  }

  final parts = <String>[
    if (shared.interests.isNotEmpty)
      "we're both into ${_joinList(shared.interests.take(3).toList())}",
    if (shared.location != null) "we're both in ${shared.location}",
  ];
  return '$intro I noticed ${parts.join(' and ')}. Would you like to connect?';
}
