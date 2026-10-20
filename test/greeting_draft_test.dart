import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/eme_world/widgets/greeting_draft.dart';

void main() {
  final me = EmUser(
    username: 'me',
    firstname: 'Christopher',
    properties: const {'location': 'Denver', 'tags': 'Hiking, AI'},
  );
  const myProfile = ProfileModel(
    id: 'me',
    name: 'Christopher B',
    role: '',
    bio: '',
    tags: ['Flutter', 'EME Member'],
  );

  EmeProfileModel other({
    List<String> tags = const [],
    List<String> services = const [],
    String? location,
  }) => EmeProfileModel(
    username: 'maya',
    name: 'Maya Lin',
    description: '',
    category: ProfileCategory.research,
    tags: tags,
    iconData: Icons.person,
    location: location,
    servicesOffered: services,
  );

  test('finds shared tags, services and location, ignoring placeholders', () {
    final shared = findShared(
      me: me,
      myProfile: myProfile,
      other: other(
        tags: ['flutter', 'EME Member', 'maya@x.org'],
        services: ['AI', 'Flutter'],
        location: 'denver',
      ),
    );
    expect(shared.interests, ['flutter', 'AI']);
    expect(shared.location, 'denver');
  });

  test('draft mentions what is in common', () {
    final o = other(tags: ['Hiking'], location: 'Denver');
    final draft = buildGreetingDraft(
      me: me,
      other: o,
      shared: findShared(me: me, myProfile: myProfile, other: o),
    );
    expect(
      draft,
      "Hi Maya, I'm Christopher. I noticed we're both into Hiking and "
      "we're both in Denver. Would you like to connect?",
    );
  });

  test('draft without anything in common is a plain introduction', () {
    final o = other(tags: ['Sailing']);
    final draft = buildGreetingDraft(
      me: me,
      other: o,
      shared: findShared(me: me, myProfile: myProfile, other: o),
    );
    expect(
      draft,
      "Hi Maya, I'm Christopher. I came across your EME profile and would "
      'love to connect.',
    );
  });
}
