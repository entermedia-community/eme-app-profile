import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_world/main.dart';
import 'package:eme_world/screens/profile/widgets/add_server_sheet.dart';
import 'package:eme_world/screens/server/server_picker_screen.dart';

void main() {
  testWidgets('AddServerSheet opens, takes name and url, and adds the server', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: EmeWorldApp()));
    await tester.pumpAndSettle();

    // Navigate to ServerPickerScreen via Pick a Server or AppBar action
    // Open Drawer to verify app is loaded, then push ServerPickerScreen directly
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ServerPickerScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap the Add Custom Server icon in AppBar
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await tester.pumpAndSettle();

    // Verify AddServerSheet is visible
    expect(find.byType(AddServerSheet), findsOneWidget);
    expect(find.text('Add Server'), findsWidgets);
    expect(find.text('Server Name *'), findsOneWidget);
    expect(find.text('Server URL *'), findsOneWidget);

    // Enter Server Name
    await tester.enterText(
      find.widgetWithText(TextField, 'e.g. EcoSphere Network'),
      'My Decentralized Node',
    );
    // Enter Server URL
    await tester.enterText(
      find.widgetWithText(TextField, 'https://node.example.com'),
      'https://mynode.eme.org',
    );
    await tester.pumpAndSettle();

    // Tap Add Server button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Add Server'));
    await tester.pumpAndSettle();

    // Verify modal dismissed and new server appears in grid
    expect(find.byType(AddServerSheet), findsNothing);
    expect(find.text('My Decentralized Node'), findsOneWidget);
  });
}
