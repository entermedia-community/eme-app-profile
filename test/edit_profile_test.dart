import 'dart:typed_data';
// ignore: depend_on_referenced_packages
import 'package:cross_file/cross_file.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/profile/widgets/edit_profile_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_helpers.dart';

final class _FakeImage extends PlatformFile {
  @override
  String get name => 'me.png';

  @override
  Uri get uri => Uri.parse('memory:me.png');

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
  Future<AuthenticatedMockAuthService> open(
    WidgetTester tester, {
    Future<PlatformFile?> Function()? pickImage,
  }) async {
    final auth = AuthenticatedMockAuthService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(auth)],
        child: MaterialApp(
          home: Scaffold(
            body: EditProfileSheet(
              user: auth.user,
              pickImage: pickImage ?? () async => null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  testWidgets('fields start with the user\'s data', (tester) async {
    await open(tester);

    expect(find.widgetWithText(TextField, 'Christopher'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'B'), findsOneWidget);
    expect(find.text('chris@emeworld.org'), findsOneWidget);
  });

  testWidgets('saves the edited name and the new picture', (tester) async {
    final auth = await open(tester, pickImage: () async => _FakeImage());

    await tester.enterText(
      find.bySemanticsIdentifier('edit_profile_first_name'),
      'Chris',
    );
    await tester.tap(find.bySemanticsIdentifier('edit_profile_change_picture'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsIdentifier('edit_profile_save'));
    await tester.pumpAndSettle();

    expect(auth.user.firstname, 'Chris');
    expect(auth.user.portraitStatus, 'pending');
    expect(auth.savedPortrait, 'me.png');
    expect(
      auth.savedFields.map((e) => '${e.key}=${e.value}'),
      containsAll(['field=firstName', 'firstName.value=Chris']),
    );
  });
}
