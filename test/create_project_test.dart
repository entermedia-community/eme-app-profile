import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:cross_file/cross_file.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/project/project_screen.dart';
import 'package:eme_world/screens/projects/create_project_screen.dart';
import 'package:eme_world/screens/projects/my_projects_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

final class _FakeLogo extends PlatformFile {
  @override
  String get name => 'logo.png';

  @override
  Uri get uri => Uri.parse('memory:logo.png');

  @override
  XFile get xFile => XFile.fromData(Uint8List(3), name: name);

  @override
  Future<int?> length() async => 3;

  @override
  int? lengthSync() => 3;

  @override
  Future<Uint8List> readAsBytes() async => Uint8List.fromList([1, 2, 3]);

  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(Uint8List(3));
}

void main() {
  Widget subject(MockApiService api, {Widget? home}) => ProviderScope(
    overrides: [apiServiceProvider.overrideWithValue(api)],
    child: MaterialApp(
      home: home ?? CreateProjectScreen(pickImage: () async => _FakeLogo()),
    ),
  );

  testWidgets('name is required', (tester) async {
    final api = MockApiService();
    await tester.pumpWidget(subject(api));
    await tester.tap(find.bySemanticsIdentifier('create_project_submit'));
    await tester.pumpAndSettle();

    expect(find.text('Give the project a name'), findsOneWidget);
    expect(api.createdProjects, isEmpty);
  });

  testWidgets('creates with only a name and opens the project', (tester) async {
    final api = MockApiService();
    await tester.pumpWidget(subject(api));
    await tester.enterText(
      find.bySemanticsIdentifier('create_project_name'),
      'Coral Reef',
    );
    await tester.tap(find.bySemanticsIdentifier('create_project_submit'));
    await tester.pumpAndSettle();

    expect(api.createdProjects.single.name, 'Coral Reef');
    expect(api.createdProjectLogo, isNull);
    expect(api.createdProjectTags, isEmpty);
    expect(find.byType(ProjectScreen), findsOneWidget);
  });

  testWidgets('slug follows the name, tags and logo are sent', (tester) async {
    final api = MockApiService();
    await tester.pumpWidget(subject(api));
    await tester.enterText(
      find.bySemanticsIdentifier('create_project_name'),
      'Coral Reef!',
    );
    await tester.pump();
    expect(find.widgetWithText(TextFormField, 'coral-reef'), findsOneWidget);

    await tester.enterText(
      find.bySemanticsIdentifier('create_project_tags'),
      'ocean, coral,',
    );
    await tester.pump();
    expect(find.byType(InputChip), findsNWidgets(2));

    await tester.tap(find.bySemanticsIdentifier('create_project_logo'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('create_project_submit'));
    await tester.pumpAndSettle();

    expect(api.createdProjects.single.urlName, 'coral-reef');
    expect(api.createdProjectTags, ['ocean', 'coral']);
    expect(api.createdProjectLogo, 'logo.png');
  });

  testWidgets('shows the server error and stays on the form', (tester) async {
    final api = FailingCreateApi();
    await tester.pumpWidget(subject(api));
    await tester.enterText(
      find.bySemanticsIdentifier('create_project_name'),
      'X',
    );
    await tester.tap(find.bySemanticsIdentifier('create_project_submit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('not allowed'), findsOneWidget);
    expect(find.byType(CreateProjectScreen), findsOneWidget);
  });

  testWidgets('My Projects has a button that opens the form', (tester) async {
    await tester.pumpWidget(
      subject(MockApiService(), home: const MyProjectsScreen()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('my_projects_new'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateProjectScreen), findsOneWidget);
  });
}

class FailingCreateApi extends MockApiService {
  @override
  Future<LibraryCollectionModel> createProject({
    required String name,
    String? description,
    String? urlName,
    List<String> tags = const [],
    MultipartFile? logo,
  }) async => throw Exception('not allowed');
}
