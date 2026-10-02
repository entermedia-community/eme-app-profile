import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:eme_world/main.dart';

class AuthenticatedMockAuthService implements IAuthService {
  EmUser user = EmUser(
    username: 'usr_test_1',
    firstname: 'Christopher',
    lastname: 'B',
    email: 'chris@emeworld.org',
    screenname: 'christopher.b',
  );
  String token = 'test_token_123';

  @override
  Future<EmUser?> checkAuthSession() async => user;

  @override
  Future<EmUser?> getCurrentUser() async => user;

  @override
  Future<String?> getAuthToken() async => token;

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<void> logout() async {}

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
  }) async => SendUserCodeResult(status: SendUserCodeStatus.ok, email: email);

  @override
  Future<LoginResult> loginWithCode({
    required String email,
    required String code,
  }) async => LoginResult(isSuccess: true, token: token, user: user);

  @override
  Future<List<EmUser>> searchUsers(String query) async {
    return [
      EmUser(
        username: 'admin',
        firstname: 'The',
        lastname: 'Administrator',
        email: 'support@entermediadb.org',
        assetportrait:
            'http://localhost.com:8080/site/mediadb/services/module/asset/generated/Users/The.A/jefferson-santos-9SoCnyQmkzI-unsplash.jpg/image200x200.webp',
      ),
    ];
  }
}

Widget createTestApp({List<Override> overrides = const []}) {
  final mockAuth = AuthenticatedMockAuthService();
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(mockAuth),
      authProvider.overrideWith((ref) => AuthNotifier(authService: mockAuth)
        ..state = AuthState(
          status: AuthStatus.authenticated,
          user: mockAuth.user,
          token: mockAuth.token,
        )),
      ...overrides,
    ],
    child: const EmeWorldApp(),
  );
}
