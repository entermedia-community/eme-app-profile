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
  Future<FirebaseCredentials?> getFirebaseCredentials() async => null;

  @override
  Future<bool> refreshToken() async => false;

  @override
  Future<bool> isAuthenticated() async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<void> saveUserFields(
    List<MapEntry<String, String>> fields, {
    MultipartFile? portrait,
  }) async {
    savedFields = fields;
    savedPortrait = portrait?.filename;
    String? value(String key) {
      for (final e in fields) {
        if (e.key == '$key.value') return e.value;
      }
      return null;
    }

    user = user.copyWith(
      firstname: value('firstName'),
      lastname: value('lastName'),
      properties: portrait == null
          ? null
          : {...user.properties, 'assetportraitstatus': 'pending'},
    );
  }

  /// What the last [saveUserFields] was given.
  List<MapEntry<String, String>> savedFields = const [];
  String? savedPortrait;

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
            'http://localhost:8080/site/mediadb/services/module/asset/generated/Users/The.A/jefferson-santos-9SoCnyQmkzI-unsplash.jpg/image200x200.webp',
      ),
    ];
  }
}

class UploadedEntityAsset {
  final String? collectionId;
  final String? filename;
  final String? name;
  final String? description;
  final List<String> tags;

  const UploadedEntityAsset(
    this.collectionId,
    this.filename,
    this.name,
    this.description,
    this.tags,
  );
}

class MockApiService implements IApiService {
  /// Projects returned by [search].
  final searchableProjects = <LibraryCollectionModel>[];

  /// `caneditcollection` returned by [connectProjectChat].
  bool projectCanEdit = true;

  /// `canviewsettings` returned by [connectProjectChat].
  bool projectCanViewSettings = false;
  final memberUpdates = <String>[];

  @override
  Future<List<ProjectTeamRole>> fetchTeamRoles() async => const [
    ProjectTeamRole(id: 'role_1', name: 'Lead'),
    ProjectTeamRole(id: 'role_2', name: 'Testing Engineer'),
  ];

  @override
  Future<void> updateProjectTeamMember(
    String collectionId, {
    required String memberId,
    bool? onTheTeam,
    List<String>? roleIds,
  }) async {
    memberUpdates.add('$memberId:$onTheTeam:${roleIds?.join(',')}');
  }

  /// `priviacylevel` returned by [fetchProjectCollection].
  String projectPrivacy = 'community';

  /// `owner` returned by [fetchProjectCollection].
  String? projectOwner;
  int followToggles = 0;
  final addedTeamMembers = <String>[];

  @override
  Future<List<EmeProfileModel>> fetchTeamCandidates(
    String collectionId, {
    String? query,
  }) async => const [];

  @override
  Future<void> addProjectTeamMember(
    String collectionId, {
    String? userId,
    String? email,
    String? firstName,
    String? lastName,
  }) async {
    addedTeamMembers.add(userId ?? email!);
  }

  @override
  Future<List<LibraryCollectionModel>> fetchUserProjects() async => const [];

  /// Events returned by [fetchEvents]/[fetchEvent]; RSVPs update them.
  final events = <EventModel>[
    const EventModel(
      id: 'evt_1',
      name: 'Beach Cleanup',
      description: 'Bring gloves and water.',
      location: 'Pier 3',
      hostName: 'Alice Smith',
      goingCount: 4,
      interestedCount: 2,
    ),
  ];
  final rsvps = <String>[];

  @override
  Future<SearchResults> search({
    String? query,
    Set<SearchType>? types,
    String? category,
  }) async {
    bool wants(SearchType t) =>
        types == null || types.isEmpty || types.contains(t);
    final q = (query ?? '').toLowerCase();
    return SearchResults(
      people: wants(SearchType.people)
          ? (await fetchUsers())
                .where((p) => p.name.toLowerCase().contains(q))
                .toList()
          : const [],
      servers: wants(SearchType.servers)
          ? await fetchServers(query: query, category: category)
          : const [],
      projects: wants(SearchType.projects)
          ? searchableProjects
                .where((p) => p.name.toLowerCase().contains(q))
                .toList()
          : const [],
      events: wants(SearchType.events)
          ? await fetchEvents(query: query)
          : const [],
    );
  }

  /// Entity assets returned by [fetchEntityAssets], per project id.
  final entityAssets = <String, List<EntityAssetModel>>{};

  @override
  Future<List<EntityAssetModel>> fetchEntityAssets({
    String? userId,
    String? collectionId,
    String? query,
  }) async => entityAssets[collectionId ?? userId ?? 'me'] ?? const [];

  /// Answers of [fetchAssetPreviewStatus], per asset id, in order; the last repeats.
  final previewStatuses = <String, List<String>>{};

  @override
  Future<AssetPreviewStatus> fetchAssetPreviewStatus(
    String assetId, {
    String size = 'image200x200',
  }) async {
    final answers = previewStatuses[assetId] ?? const ['ready'];
    final state = answers.length > 1 ? answers.removeAt(0) : answers.first;
    return AssetPreviewStatus(
      assetId: assetId,
      state: state,
      url: state == 'ready' ? 'http://localhost/$assetId.jpg' : null,
    );
  }

  /// What was passed to [uploadEntityAsset].
  final uploadedEntityAssets = <UploadedEntityAsset>[];

  @override
  Future<void> uploadEntityAsset(
    MultipartFile file, {
    String? collectionId,
    String? name,
    String? description,
    List<String> tags = const [],
  }) async => uploadedEntityAssets.add(
    UploadedEntityAsset(collectionId, file.filename, name, description, tags),
  );

  @override
  Future<List<EventModel>> fetchEvents({
    String? query,
    bool rsvpedOnly = false,
  }) async => events
      .where((e) => !rsvpedOnly || e.myRsvp != EventRsvp.none)
      .where(
        (e) =>
            query == null ||
            query.isEmpty ||
            e.name.toLowerCase().contains(query.toLowerCase()),
      )
      .toList();

  @override
  Future<EventModel> fetchEvent(String eventId) async =>
      events.firstWhere((e) => e.id == eventId);

  @override
  Future<EventRsvpResult> setEventRsvp(String eventId, EventRsvp rsvp) async {
    rsvps.add('$eventId:${rsvp.name}');
    final i = events.indexWhere((e) => e.id == eventId);
    final old = events[i];
    int delta(EventRsvp which, EventRsvp r) =>
        (r == which ? 1 : 0) - (old.myRsvp == which ? 1 : 0);
    events[i] = old.copyWith(
      goingCount: old.goingCount + delta(EventRsvp.going, rsvp),
      interestedCount: old.interestedCount + delta(EventRsvp.interested, rsvp),
      myRsvp: rsvp,
    );
    return EventRsvpResult(
      goingCount: events[i].goingCount,
      interestedCount: events[i].interestedCount,
      myRsvp: rsvp,
    );
  }

  /// Projects made through [createProject].
  final createdProjects = <LibraryCollectionModel>[];

  /// Logo filename and tags of the last [createProject] call.
  String? createdProjectLogo;
  List<String> createdProjectTags = const [];

  @override
  Future<LibraryCollectionModel> createProject({
    required String name,
    String? description,
    String? urlName,
    List<String> tags = const [],
    MultipartFile? logo,
  }) async {
    createdProjectLogo = logo?.filename;
    createdProjectTags = tags;
    final project = LibraryCollectionModel(
      id: 'proj_${createdProjects.length + 1}',
      name: name,
      description: description,
      urlName: urlName,
    );
    createdProjects.add(project);
    return project;
  }

  /// `name:description:urlName:tags` of each [updateProject] call.
  final projectUpdates = <String>[];

  @override
  Future<LibraryCollectionModel> updateProject(
    String collectionId, {
    required String name,
    String? description,
    String? urlName,
    List<String> tags = const [],
  }) async {
    projectUpdates.add('$name:$description:$urlName:${tags.join(',')}');
    return LibraryCollectionModel(id: collectionId, name: name);
  }

  @override
  Future<EventModel> createEvent({
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
    String? location,
  }) async {
    final event = EventModel(
      id: 'evt_${events.length + 1}',
      name: name,
      description: description ?? '',
      location: location ?? '',
      startDate: startDate,
      endDate: endDate,
      goingCount: 1,
      myRsvp: EventRsvp.going,
    );
    events.add(event);
    return event;
  }

  @override
  Future<String> connectServerChat(
    String serverId, {
    Map<String, dynamic>? params,
  }) async => 'ch_$serverId';

  @override
  Future<String> connectEventChat(String eventId) async => 'ch_$eventId';

  @override
  Future<ProjectChatConnection> connectProjectChat(
    String collectionId, {
    Map<String, dynamic>? params,
  }) async {
    if (collectionId != 'coll_123') {
      throw Exception('Project chat $collectionId: not found');
    }
    return ProjectChatConnection(
      channelId: 'ch_$collectionId',
      topicId: 'topic_general',
      canEditCollection: projectCanEdit,
      canViewSettings: projectCanViewSettings,
    );
  }

  @override
  Future<ProjectFollowState> toggleProjectFollow(String collectionId) async {
    followToggles++;
    return const ProjectFollowState(following: true, followerCount: 4);
  }

  @override
  Future<LibraryCollectionModel> fetchProjectCollection(
    String collectionId, {
    String? baseUrl,
  }) async {
    if (collectionId != 'coll_123') {
      throw Exception('Project $collectionId: not found');
    }
    return LibraryCollectionModel(
      id: 'coll_123',
      name: 'Clean Water Initiative',
      description: 'Decentralized ecological project',
      privacyLevel: projectPrivacy,
      ownerId: projectOwner,
      contactEmail: 'water@example.com',
      projectLink: 'https://water.example.com/clean-water',
      donateDescription: 'Help us build wells',
      proposalTestimonials: '<p>Changed our village.</p>',
      websiteLink: 'https://water.example.com',
      followerCount: 3,
      followedByUser: false,
      team: [
        ProjectTeamMember(
          memberId: 'm1',
          userId: 'u1',
          firstName: 'Alice',
          lastName: 'Smith',
          teamRoles: ['role_1'],
          teamRoleNames: ['Lead'],
        ),
      ],
    );
  }

  @override
  Future<List<ServerModel>> fetchServers({
    String? query,
    String? category,
  }) async => const [
    ServerModel(
      id: 'srv_test_1',
      name: 'Lakeview Stays & House Rentals',
      subtitle: 'HOUSE RENTALS',
      description: 'Verified off-grid eco-villas and lakefront stays.',
      category: ServerCategoryModel(id: 'rental_gear', name: 'Rental & Gear'),
      primaryColor: Color(0xFF0D9488),
      secondaryColor: Color(0xFFCCFBF1),
      memberCount: 530,
      isJoined: true,
      servicesOffered: ['Solar Eco-Villas', 'Private Boat Dock Access'],
    ),
    ServerModel(
      id: 'srv_test_2',
      name: 'Artisan Goods & Organic Market',
      subtitle: 'PRODUCER-DIRECT COMMERCE',
      description:
          'Direct-to-consumer marketplace for shade coffee and textiles.',
      category: ServerCategoryModel(
        id: 'marketplace',
        name: 'Marketplace & Goods',
      ),
      primaryColor: Color(0xFFD97706),
      secondaryColor: Color(0xFFFEF3C7),
      memberCount: 1680,
      isJoined: false,
      servicesOffered: ['Single-Origin Coffee', 'Handwoven Textiles'],
    ),
  ];

  @override
  Future<List<ServerCategoryModel>> fetchServerCategories() async => const [
    ServerCategoryModel(id: 'all', name: 'All'),
    ServerCategoryModel(id: 'rental_gear', name: 'Rental & Gear'),
    ServerCategoryModel(id: 'marketplace', name: 'Marketplace & Goods'),
    ServerCategoryModel(id: 'software_tools', name: 'Software Tools'),
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
  Future<List<ChatMessage>> fetchUserChatMessages(String channelId) async {
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

  /// Sessions returned by [fetchChatSessions].
  final chatSessions = <ChatSession>[];

  @override
  Future<List<ChatSession>> fetchChatSessions({
    String? toUser,
    String? serverId,
    String? collectionId,
    String? baseUrl,
  }) async => chatSessions;

  @override
  Future<ChatSession> createChatSession({
    String? toUser,
    String? serverId,
    String? collectionId,
    String? baseUrl,
  }) async =>
      ChatSession(channelId: 'new_session', refreshDate: DateTime.now());

  @override
  Future<List<ChatMessage>> fetchServerChatMessages(
    String channelId, {
    String? serverId,
    String? baseUrl,
  }) async {
    return [
      ChatMessage(
        messageId: 'msg_server_1',
        channel: channelId,
        userId: 'admin',
        message: 'Welcome to server discussions & proposals.',
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
