import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/screens/auth/auth_gate.dart';
import 'package:eme_world/screens/main_shell_screen.dart';
import 'package:eme_world/widgets/auth/auth_modal_sheet.dart';
import 'package:eme_world/widgets/auth/otp_input_field.dart';

class MockAuthService implements IAuthService {
  String? mockToken;
  EmUser? mockUser;

  @override
  Future<EmUser?> checkAuthSession() async => mockUser;

  @override
  Future<EmUser?> getCurrentUser() async => mockUser;

  @override
  Future<String?> getAuthToken() async => mockToken;

  @override
  Future<FirebaseCredentials?> getFirebaseCredentials() async => null;

  @override
  Future<bool> refreshToken() async => false;

  @override
  Future<void> authenticateRemoteServer(String serverMediaDbUrl) async {}

  @override
  Future<bool> isAuthenticated() async =>
      mockToken != null && mockToken!.isNotEmpty;

  @override
  Future<void> logout() async {
    mockToken = null;
    mockUser = null;
  }

  @override
  Future<void> saveUserFields(
    List<MapEntry<String, String>> fields, {
    MultipartFile? portrait,
  }) async {}

  @override
  Future<SendUserCodeResult> sendUserCode({
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    if (email.contains('new') && (firstName == null || firstName.isEmpty)) {
      return SendUserCodeResult(
        status: SendUserCodeStatus.nouser,
        email: email,
        allowGuestRegistration: true,
      );
    }
    if (email.contains('error')) {
      return const SendUserCodeResult(
        status: SendUserCodeStatus.error,
        errorMessage: 'Invalid email address',
      );
    }
    return SendUserCodeResult(status: SendUserCodeStatus.ok, email: email);
  }

  @override
  Future<LoginResult> loginWithCode({
    required String email,
    required String code,
  }) async {
    if (code == '123456') {
      final user = EmUser(
        username: 'usr_test_1',
        firstname: 'Test',
        lastname: 'User',
        email: email,
        screenname: 'tester',
      );
      mockUser = user;
      mockToken = 'mock_entermediakey_123';
      return LoginResult(isSuccess: true, token: mockToken, user: user);
    }
    return const LoginResult(
      isSuccess: false,
      errorMessage: 'Invalid OTP code',
    );
  }

  @override
  Future<List<EmUser>> searchUsers(String query) async {
    return [
      EmUser(
        username: 'admin',
        firstname: 'The',
        lastname: 'Administrator',
        email: 'support@entermediadb.org',
        assetportrait:
            'http://localhost:8080/site/mediadb/services/module/asset/generated/Users/The.A/jefferson-santos-9SoCnyQmkzI-unsplash.jpg/image200x200.webp',
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth UI & OTP Tests', () {
    testWidgets(
      'OtpInputField handles individual digit entry and paste callback',
      (WidgetTester tester) async {
        String enteredCode = '';

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OtpInputField(
                length: 6,
                onChanged: (code) => enteredCode = code,
              ),
            ),
          ),
        );

        // Verify 6 input boxes exist
        expect(find.byType(TextField), findsNWidgets(6));

        // Enter digits into each text field
        await tester.enterText(find.byType(TextField).at(0), '1');
        await tester.enterText(find.byType(TextField).at(1), '2');
        await tester.enterText(find.byType(TextField).at(2), '3');
        await tester.enterText(find.byType(TextField).at(3), '4');
        await tester.enterText(find.byType(TextField).at(4), '5');
        await tester.enterText(find.byType(TextField).at(5), '6');
        await tester.pump();

        expect(enteredCode, '123456');
      },
    );

    testWidgets(
      'OtpInputField pasting a valid code into a box fills all boxes',
      (WidgetTester tester) async {
        String code = '';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OtpInputField(length: 6, onChanged: (c) => code = c),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField).at(2), ' 135790 ');
        await tester.pump();
        await tester.pump();

        expect(code, '135790');
      },
    );

    testWidgets(
      'OtpInputField backspace moves focus to and clears previous box',
      (WidgetTester tester) async {
        String code = '';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OtpInputField(length: 6, onChanged: (c) => code = c),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField).at(0), '1');
        await tester.pump();
        // Focus is now on box 1 (empty); backspace should clear box 0.
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pump();

        expect(code, '');
        expect(
          tester
              .widget<TextField>(find.byType(TextField).at(0))
              .controller!
              .text,
          '',
        );
      },
    );

    testWidgets('OtpInputField typing advances focus, even over a filled box', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: OtpInputField(length: 6))),
      );

      TextField box(int i) =>
          tester.widget<TextField>(find.byType(TextField).at(i));

      await tester.enterText(find.byType(TextField).at(0), '1');
      await tester.pump();
      expect(box(1).focusNode!.hasFocus, isTrue);

      // Back to box 0 (already holds '1') and type the same digit again.
      box(0).focusNode!.requestFocus();
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), '11');
      await tester.pump();
      await tester.pump();

      expect(box(0).controller!.text, '1');
      expect(box(1).focusNode!.hasFocus, isTrue);
    });

    testWidgets('OtpInputField rejects invalid paste with a snackbar', (
      WidgetTester tester,
    ) async {
      String code = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputField(length: 6, onChanged: (c) => code = c),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), '12345');
      await tester.pump();
      await tester.pump();

      expect(code, '');
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets(
      'AuthModalSheet renders email step, sends code, and transitions to OTP',
      (WidgetTester tester) async {
        final mockAuth = MockAuthService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuth)],
            child: const MaterialApp(home: Scaffold(body: AuthModalSheet())),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sign in to EME World'), findsOneWidget);
        expect(find.text('Continue with Email'), findsOneWidget);

        // Enter valid email
        await tester.enterText(
          find.byType(TextField).first,
          'test@emeworld.org',
        );
        await tester.tap(find.text('Continue with Email'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify transition to OTP verification view
        expect(find.text('Verification Code'), findsOneWidget);
        expect(find.byType(OtpInputField), findsOneWidget);
        expect(find.text('Verify & Sign In'), findsOneWidget);
      },
    );

    testWidgets(
      'AuthModalSheet shows guest registration form when user does not exist',
      (WidgetTester tester) async {
        final mockAuth = MockAuthService();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuth)],
            child: const MaterialApp(home: Scaffold(body: AuthModalSheet())),
          ),
        );
        await tester.pumpAndSettle();

        // Enter new email that triggers nouser status
        await tester.enterText(
          find.byType(TextField).first,
          'newuser@emeworld.org',
        );
        await tester.tap(find.text('Continue with Email'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify guest registration form
        expect(find.text('Create Your Profile'), findsOneWidget);
        expect(find.text('First Name'), findsOneWidget);
        expect(find.text('Last Name'), findsOneWidget);
        expect(find.text('Register & Send Code'), findsOneWidget);

        // Complete registration
        await tester.enterText(
          find.widgetWithText(TextField, 'First Name'),
          'Sarah',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Last Name'),
          'Connor',
        );
        await tester.tap(find.text('Register & Send Code'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify transition to OTP verification
        expect(find.text('Verification Code'), findsOneWidget);
        expect(find.byType(OtpInputField), findsOneWidget);
      },
    );

    testWidgets(
      'AuthGate displays AuthScreen when unauthenticated and MainShellScreen when authenticated',
      (WidgetTester tester) async {
        final mockAuth = MockAuthService();

        // Case 1: Unauthenticated -> shows AuthScreen with EME branding
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(mockAuth)],
            child: const MaterialApp(home: AuthGate()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Collective Intelligence Economy'), findsOneWidget);
        expect(find.text('Sign in to EME World'), findsOneWidget);
        expect(find.byType(MainShellScreen), findsNothing);

        // Case 2: Authenticated -> shows MainShellScreen
        final authMock2 = MockAuthService();
        authMock2.mockUser = EmUser(
          username: 'usr_authenticated',
          firstname: 'Alice',
          lastname: 'Smith',
          email: 'alice@emeworld.org',
        );
        authMock2.mockToken = 'valid_token_xyz';

        await tester.pumpWidget(
          ProviderScope(
            overrides: [authServiceProvider.overrideWithValue(authMock2)],
            child: const MaterialApp(home: AuthGate()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(MainShellScreen), findsOneWidget);
      },
    );
  });
}
