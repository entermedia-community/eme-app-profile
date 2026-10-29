// TODO(events): events are hidden in the app for now; re-enable with them.
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:eme_app_sdk/eme_app_sdk.dart';
// import 'package:eme_world/screens/event/create_event_screen.dart';
// import 'package:eme_world/screens/event/event_screen.dart';
// import 'package:eme_world/screens/profile/profile_screen.dart';
// import 'package:eme_world/screens/server/tabs/server_chat_tab.dart';
// import 'package:eme_world/screens/server/tabs/server_overview_tab.dart';
// import 'test_helpers.dart';
//
// void main() {
//   Future<MockApiService> pumpEvent(WidgetTester tester) async {
//     final api = MockApiService();
//     await tester.pumpWidget(
//       ProviderScope(
//         overrides: [apiServiceProvider.overrideWithValue(api)],
//         child: MaterialApp(home: EventScreen(event: api.events.first)),
//       ),
//     );
//     await tester.pumpAndSettle();
//     return api;
//   }
//
//   testWidgets('opens on Details with the event info', (tester) async {
//     await pumpEvent(tester);
//
//     expect(find.byType(ServerChatTab), findsNothing);
//     expect(find.text('About'), findsOneWidget);
//     expect(find.text('Bring gloves and water.'), findsOneWidget);
//     expect(find.text('Pier 3'), findsOneWidget);
//     expect(find.text('4 going · 2 interested'), findsOneWidget);
//     expect(find.bySemanticsIdentifier('event_rsvp_going'), findsOneWidget);
//     expect(find.bySemanticsIdentifier('event_nav_chat'), findsOneWidget);
//   });
//
//   testWidgets('Going and Interested set, switch and clear the response', (
//     tester,
//   ) async {
//     final api = await pumpEvent(tester);
//
//     await tester.tap(find.bySemanticsIdentifier('event_rsvp_going'));
//     await tester.pumpAndSettle();
//     expect(find.text('5 going · 2 interested'), findsOneWidget);
//
//     await tester.tap(find.bySemanticsIdentifier('event_rsvp_interested'));
//     await tester.pumpAndSettle();
//     expect(find.text('4 going · 3 interested'), findsOneWidget);
//
//     // Tapping the active response takes it back.
//     await tester.tap(find.bySemanticsIdentifier('event_rsvp_interested'));
//     await tester.pumpAndSettle();
//     expect(find.text('4 going · 2 interested'), findsOneWidget);
//
//     expect(api.rsvps, ['evt_1:going', 'evt_1:interested', 'evt_1:none']);
//   });
//
//   testWidgets('Chat tab opens the event channel', (tester) async {
//     await pumpEvent(tester);
//
//     await tester.tap(find.bySemanticsIdentifier('event_nav_chat'));
//     await tester.pumpAndSettle();
//
//     final chat = tester.widget<ServerChatTab>(find.byType(ServerChatTab));
//     expect(chat.eventId, 'evt_1');
//     expect(find.textContaining('Could not'), findsNothing);
//   });
//
//   testWidgets('Create event needs a name and a start, then opens the event', (
//     tester,
//   ) async {
//     final api = MockApiService();
//     await tester.pumpWidget(
//       ProviderScope(
//         overrides: [apiServiceProvider.overrideWithValue(api)],
//         child: const MaterialApp(home: CreateEventScreen()),
//       ),
//     );
//
//     await tester.tap(find.bySemanticsIdentifier('create_event_submit'));
//     await tester.pumpAndSettle();
//     expect(find.text('Give the event a name'), findsOneWidget);
//
//     await tester.enterText(
//       find.descendant(
//         of: find.bySemanticsIdentifier('create_event_name'),
//         matching: find.byType(TextFormField),
//       ),
//       'Potluck',
//     );
//     await tester.tap(find.bySemanticsIdentifier('create_event_submit'));
//     await tester.pumpAndSettle();
//     expect(find.text('Pick a start date and time.'), findsOneWidget);
//
//     // Pick the start: accept the default date and time in the pickers.
//     await tester.tap(find.bySemanticsIdentifier('create_event_start'));
//     await tester.pumpAndSettle();
//     await tester.tap(find.text('OK'));
//     await tester.pumpAndSettle();
//     await tester.tap(find.text('OK'));
//     await tester.pumpAndSettle();
//
//     await tester.tap(find.bySemanticsIdentifier('create_event_submit'));
//     await tester.pumpAndSettle();
//
//     expect(api.events.last.name, 'Potluck');
//     expect(find.byType(EventScreen), findsOneWidget);
//   });
//
//   group('Create event entry points', () {
//     ServerModel server({required bool owner}) => ServerModel(
//       id: 's1',
//       name: 'Lakeview',
//       description: 'A server',
//       category: const ServerCategoryModel(id: 'c', name: 'Tools'),
//       isJoined: true,
//       isOwner: owner,
//     );
//
//     Future<void> pumpOverview(WidgetTester tester, ServerModel s) async {
//       tester.view.physicalSize = const Size(800, 3000);
//       tester.view.devicePixelRatio = 1;
//       addTearDown(tester.view.reset);
//       await tester.pumpWidget(
//         ProviderScope(
//           overrides: [apiServiceProvider.overrideWithValue(MockApiService())],
//           child: MaterialApp(
//             home: Scaffold(
//               body: ServerOverviewTab(server: s, onNavigateToModule: (_) {}),
//             ),
//           ),
//         ),
//       );
//       await tester.pumpAndSettle();
//     }
//
//     testWidgets('server owners see Create Event on the overview', (
//       tester,
//     ) async {
//       await pumpOverview(tester, server(owner: true));
//       expect(find.bySemanticsIdentifier('server_create_event'), findsOneWidget);
//
//       await tester.tap(find.bySemanticsIdentifier('server_create_event'));
//       await tester.pumpAndSettle();
//       expect(find.byType(CreateEventScreen), findsOneWidget);
//     });
//
//     testWidgets('other members do not', (tester) async {
//       await pumpOverview(tester, server(owner: false));
//       expect(find.bySemanticsIdentifier('server_create_event'), findsNothing);
//     });
//
//     testWidgets('the profile has a Create an event entry', (tester) async {
//       tester.view.physicalSize = const Size(800, 3000);
//       tester.view.devicePixelRatio = 1;
//       addTearDown(tester.view.reset);
//       await tester.pumpWidget(
//         ProviderScope(
//           overrides: [apiServiceProvider.overrideWithValue(MockApiService())],
//           child: const MaterialApp(home: Scaffold(body: ProfileScreen())),
//         ),
//       );
//       await tester.pumpAndSettle();
//
//       await tester.tap(find.bySemanticsIdentifier('profile_create_event'));
//       await tester.pumpAndSettle();
//       expect(find.byType(CreateEventScreen), findsOneWidget);
//     });
//   });
// }

void main() {}
