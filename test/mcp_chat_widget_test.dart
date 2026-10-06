import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eme_world/screens/chats/mcp_chat_detail_screen.dart';
import 'package:eme_world/screens/chats/widgets/add_mcp_server_sheet.dart';
import 'package:eme_world/screens/chats/widgets/mcp_server_info_sheet.dart';
import 'package:eme_world/screens/chats/widgets/mcp_tool_invocation_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'MCP Client chats, filtering, Add Server sheet, and MCP Chat detail test',
    (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 1. Navigate to Chats tab
      await tester.tap(find.text('Chats').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('Search conversations...'), findsOneWidget);
      expect(find.text('+ MCP'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Direct Chats'), findsOneWidget);
      expect(find.text('MCP Servers'), findsOneWidget);

      // 2. Test Filtering by MCP Servers
      await tester.tap(find.text('MCP Servers'));
      await tester.pumpAndSettle();

      expect(find.text('EnterMedia EME World MCP'), findsWidgets);
      expect(find.text('The Administrator'), findsNothing);

      // 3. Test Filter back to All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.text('The Administrator'), findsWidgets);

      // 4. Test Opening "+ MCP" Add Server Sheet
      await tester.tap(find.text('+ MCP'));
      await tester.pumpAndSettle();

      expect(find.byType(AddMcpServerSheet), findsOneWidget);
      expect(find.text('Add Remote MCP Server'), findsOneWidget);
      expect(find.text('QUICK PRESETS'), findsOneWidget);
      expect(find.text('EnterMedia DAM'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // 5. Tap on MCP Server Chat item to enter McpChatDetailScreen
      await tester.tap(find.text('EnterMedia EME World MCP').first);
      await tester.pumpAndSettle();

      expect(find.byType(McpChatDetailScreen), findsOneWidget);
      expect(find.text('EnterMedia EME World MCP'), findsWidgets);
      expect(find.byIcon(Icons.bolt_rounded), findsWidgets);

      // 6. Test opening Tools Explorer / Invocation Sheet
      final firstToolChip = find.text('search_media_assets');
      if (firstToolChip.evaluate().isNotEmpty) {
        await tester.tap(firstToolChip.first);
        await tester.pumpAndSettle();

        expect(find.byType(McpToolInvocationSheet), findsOneWidget);
        expect(find.text('search_media_assets'), findsWidgets);
        expect(find.text('PARAMETERS / ARGUMENTS'), findsOneWidget);

        // Close tool sheet
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
      }

      // 7. Test opening MCP Server Info Sheet
      await tester.tap(find.byIcon(Icons.info_outline_rounded).last);
      await tester.pumpAndSettle();

      expect(find.byType(McpServerInfoSheet), findsOneWidget);
      expect(find.text('ADVERTISED TOOLS (4)'), findsOneWidget);
      expect(find.text('ABOUT SERVER'), findsOneWidget);

      // Close info sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // 8. Test sending user message to MCP server
      final inputFinder = find.byType(TextField).last;
      await tester.enterText(inputFinder, 'What tools are available?');
      await tester.tap(find.byIcon(Icons.send_rounded).last);
      await tester.pumpAndSettle();

      expect(find.text('What tools are available?'), findsOneWidget);
    },
  );
}
