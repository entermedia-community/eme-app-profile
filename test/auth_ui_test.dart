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
  Future<bool> isAuthenticated() async => mockToken != null && mockToken!.isNotEmpty;

  @override
  Future<void> logout() async {
    mockToken = null;
    mockUser = null;
  }

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
    return SendUserCodeResult(
      status: SendUserCodeStatus.ok,
      email: email,
    );
  }

  @override
  Future<LoginResult> loginWithCode({
    required String email,
    required String code,
  }) async {
    if (code == '123456') {
      final user = EmUser(
        userid: 'usr_test_1',
        firstname: 'Test',
        lastname: 'User',
        email: email,
        screenname: 'tester',
      );
      mockUser = user;
      mockToken = 'mock_entermediakey_123';
      return LoginResult(
        isSuccess: true,
        token: mockToken,
        user: user,
      );
    }
    return const LoginResult(
      isSuccess: false,
      errorMessage: 'Invalid OTP code',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth UI & OTP Tests', () {
    testWidgets('OtpInputField handles individual digit entry and paste callback',
        (WidgetTester tester) async {
      String enteredCode = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputField(
              length: 6,
              onCompleted: (code) => enteredCode = code,
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
    });

    testWidgets('OtpInputField paste button distributes multi-digit string',
        (WidgetTester tester) async {
      String enteredCode = '';

      // Mock system clipboard
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.getData') {
            return {'text': '987654'};
          }
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputField(
              length: 6,
              onCompleted: (code) => enteredCode = code,
            ),
          ),
        ),
      );

      // Tap 'Paste code from clipboard' button
      await tester.tap(find.text('Paste code from clipboard'));
      await tester.pump();

      expect(enteredCode, '987654');
    });

    testWidgets('AuthModalSheet renders email step, sends code, and transitions to OTP',
        (WidgetTester tester) async {
      final mockAuth = MockAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AuthModalSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to EME World'), findsOneWidget);
      expect(find.text('Continue with Email'), findsOneWidget);

      // Enter valid email
      await tester.enterText(find.byType(TextField).first, 'test@emeworld.org');
      await tester.tap(find.text('Continue with Email'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify transition to OTP verification view
      expect(find.text('Verification Code'), findsOneWidget);
      expect(find.byType(OtpInputField), findsOneWidget);
      expect(find.text('Verify & Sign In'), findsOneWidget);
    });

    testWidgets('AuthModalSheet shows guest registration form when user does not exist',
        (WidgetTester tester) async {
      final mockAuth = MockAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AuthModalSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter new email that triggers nouser status
      await tester.enterText(find.byType(TextField).first, 'newuser@emeworld.org');
      await tester.tap(find.text('Continue with Email'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify guest registration form
      expect(find.text('Create Your Profile'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Register & Send Code'), findsOneWidget);

      // Complete registration
      await tester.enterText(find.widgetWithText(TextField, 'First Name'), 'Sarah');
      await tester.enterText(find.widgetWithText(TextField, 'Last Name'), 'Connor');
      await tester.tap(find.text('Register & Send Code'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify transition to OTP verification
      expect(find.text('Verification Code'), findsOneWidget);
      expect(find.byType(OtpInputField), findsOneWidget);
    });

    testWidgets('AuthGate displays AuthScreen when unauthenticated and MainShellScreen when authenticated',
        (WidgetTester tester) async {
      final mockAuth = MockAuthService();

      // Case 1: Unauthenticated -> shows AuthScreen with EME World branding
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
          ],
          child: const MaterialApp(
            home: AuthGate(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EME World'), findsOneWidget);
      expect(find.text('Sign in to EME World'), findsOneWidget);
      expect(find.byType(MainShellScreen), findsNothing);

      // Case 2: Authenticated -> shows MainShellScreen
      final authMock2 = MockAuthService();
      authMock2.mockUser = EmUser(
        userid: 'usr_authenticated',
        firstname: 'Alice',
        lastname: 'Smith',
        email: 'alice@emeworld.org',
      );
      authMock2.mockToken = 'valid_token_xyz';

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(authMock2),
          ],
          child: const MaterialApp(
            home: AuthGate(),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(MainShellScreen), findsOneWidget);
    });
  });
}
