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

class MockApiService implements IApiService {
  @override
  Future<List<ServerModel>> fetchServers({
    String? query,
    String? category,
  }) async => const [
    ServerModel(
      id: 'srv_test_1',
      title: 'Lakeview Stays & House Rentals',
      subtitle: 'HOUSE RENTALS',
      description: 'Verified off-grid eco-villas and lakefront stays.',
      category: 'Rental & Gear',
      primaryColor: Color(0xFF0D9488),
      secondaryColor: Color(0xFFCCFBF1),
      memberCount: 530,
      isJoined: true,
      servicesOffered: ['Solar Eco-Villas', 'Private Boat Dock Access'],
    ),
    ServerModel(
      id: 'srv_test_2',
      title: 'Artisan Goods & Organic Market',
      subtitle: 'PRODUCER-DIRECT COMMERCE',
      description: 'Direct-to-consumer marketplace for shade coffee and textiles.',
      category: 'Marketplace & Goods',
      primaryColor: Color(0xFFD97706),
      secondaryColor: Color(0xFFFEF3C7),
      memberCount: 1680,
      isJoined: false,
      servicesOffered: ['Single-Origin Coffee', 'Handwoven Textiles'],
    ),
  ];

  @override
  Future<ServerModel?> fetchServerById(String id) async {
    final servers = await fetchServers();
    return servers.cast<ServerModel?>().firstWhere(
      (s) => s?.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<bool> joinServer(String serverId) async => true;

  @override
  Future<bool> leaveServer(String serverId) async => true;

  @override
  Future<List<ServerModel>> fetchUserServers() async {
    final servers = await fetchServers();
    return servers.where((s) => s.isJoined).toList();
  }

  @override
  Future<List<EmeProfileModel>> fetchSpecialistProfiles() async => fetchUsers();

  @override
  Future<ProfileModel> fetchUserProfile({String? userId}) async =>
      const ProfileModel(
        id: 'usr_test_1',
        name: 'Christopher B',
        role: 'Community Lead',
        bio: 'Open source contributor & community lead.',
        tags: ['Flutter', 'OpenEdit'],
      );

  @override
  Future<List<ProductMessageModel>> fetchProducts({
    String? serverId,
    ProductType? type,
  }) async => ProductMessageModel.sampleCatalog;

  @override
  Future<List<ChatModel>> fetchChats() async {
    return const [
      ChatModel(
        channelId: 'admin',
        username: 'admin',
        displayName: 'The Administrator',
        lastMessage: 'Welcome to EME Direct Messaging.',
        time: 'Just now',
        unreadCount: 0,
        avatarColor: Color(0xFF2563EB),
        avatarInitials: 'TA',
      ),
    ];
  }

  @override
  Future<List<ChatMessage>> fetchChatMessages(String channelId) async {
    return [
      ChatMessage(
        messageId: 'msg_1',
        channel: channelId,
        userId: 'admin',
        message: 'Welcome to EME Direct Messaging.',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<List<FileItemModel>> fetchFiles({String? serverId}) async => [];

  @override
  Future<List<GoalItemModel>> fetchServerGoals(String serverId) async => [];

  @override
  Future<List<TransactionItemModel>> fetchServerTransactions(
    String serverId,
  ) async => [];

  @override
  Future<List<BlogPostModel>> fetchServerBlogPosts(String serverId) async => [];

  @override
  Future<List<EmeProfileModel>> searchUsers(String query) async => fetchUsers();

  @override
  Future<List<EmeProfileModel>> fetchUsers() async {
    return const [
      EmeProfileModel(
        username: 'admin',
        name: 'The Administrator',
        category: ProfileCategory.softwareTools,
        description: 'System Administrator',
        tags: ['Admin'],
        iconData: Icons.admin_panel_settings,
        isVerified: true,
        servicesOffered: ['Admin'],
      ),
    ];
  }
}

Widget createTestApp({List<Override> overrides = const []}) {
  final mockAuth = AuthenticatedMockAuthService();
  final mockApi = MockApiService();
  return ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(mockAuth),
      apiServiceProvider.overrideWithValue(mockApi),
      authProvider.overrideWith(
        (ref) => AuthNotifier(authService: mockAuth)
          ..state = AuthState(
            status: AuthStatus.authenticated,
            user: mockAuth.user,
            token: mockAuth.token,
          ),
      ),
      emeProfileProvider.overrideWith(
        (ref) => EmeProfileNotifier(apiService: mockApi, authService: mockAuth),
      ),
      ...overrides,
    ],
    child: const EmeWorldApp(),
  );
}
