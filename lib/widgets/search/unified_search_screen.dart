import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import '../eme_world/eme_profile_card.dart';
import '../../screens/profile/widgets/add_server_sheet.dart';
import '../../screens/profile/widgets/server_card.dart';
import '../../screens/event/event_screen.dart';
import '../../screens/project/project_screen.dart';
import 'preview_cards.dart';

enum SearchResultType { all, people, projects, servers, events }

/// One search across people, projects, EME Servers and events: a single
/// query field and a single category bar, with the results in one list.
///
/// The query and category go to the backend's unified search
/// (`searchProvider`) in one request. The category pills are the backend
/// server categories plus the EME profile categories, de-duplicated by name;
/// servers are matched by category name, and people by their profile category.
class UnifiedSearchScreen extends ConsumerStatefulWidget {
  const UnifiedSearchScreen({
    super.key,
    this.initialType = SearchResultType.all,
  });

  /// The result type selected when the screen opens.
  final SearchResultType initialType;

  /// Opens Search as a full-screen modal.
  static Future<void> show(
    BuildContext context, {
    SearchResultType initialType = SearchResultType.all,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => UnifiedSearchScreen(initialType: initialType),
      ),
    );
  }

  @override
  ConsumerState<UnifiedSearchScreen> createState() =>
      _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends ConsumerState<UnifiedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late SearchResultType _type = widget.initialType;
  String _category = _allCategory;

  static const _allCategory = 'All';
  static const _debounce = Duration(milliseconds: 300);

  Timer? _debounceTimer;

  /// The query last sent to the backend; trails the text field by [_debounce].
  String _searchedQuery = '';

  /// The previous results, shown while a new search loads.
  SearchResults? _lastResults;

  String get _query => _searchController.text.trim();

  @override
  void initState() {
    super.initState();
    // The server store holds the categories and the joined state of servers.
    Future.microtask(
      () => ref.read(serverProvider.notifier).loadServersFromApi(),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (mounted) setState(() => _searchedQuery = _query);
    });
  }

  bool _sameName(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// Backend id of the selected category for the server search, if the
  /// servers have a category by that name.
  String? _serverCategoryId() {
    if (_category == _allCategory) return null;
    for (final c in ref.read(serverProvider).categories) {
      if (_sameName(c.name, _category)) return c.id;
    }
    return null;
  }

  /// Server categories from the backend, then EME profile categories that
  /// aren't already listed.
  List<String> _categoryNames(List<ServerCategoryModel> serverCategories) {
    final names = <String>[_allCategory];
    void add(String name) {
      if (name.trim().isEmpty) return;
      if (names.any((n) => _sameName(n, name))) return;
      names.add(name);
    }

    for (final c in serverCategories) {
      add(c.name);
    }
    kEmeProfileCategories.forEach(add);
    return names;
  }

  void _selectCategory(String name) {
    setState(() => _category = name);
  }

  void _resetFilters() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _type = SearchResultType.all;
      _searchedQuery = '';
      _category = _allCategory;
    });
  }

  Future<void> _refresh() async {
    final key = _searchKey();
    ref.invalidate(searchProvider(key));
    await Future.wait([
      ref.read(searchProvider(key).future),
      ref
          .read(serverProvider.notifier)
          .loadServersFromApi(forceRefreshCategories: true),
    ]);
  }

  SearchKey _searchKey() =>
      SearchKey(query: _searchedQuery, category: _serverCategoryId());

  void _openAddServerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddServerSheet(),
    );
  }

  /// The searched servers plus servers only the local store has (custom
  /// servers added on this device), narrowed to the selected category by
  /// name. The store's joined state wins over the search's, which can be
  /// older.
  List<ServerModel> _filterServers(
    List<ServerModel> searched,
    List<ServerModel> known,
  ) {
    final q = _searchedQuery.toLowerCase();
    final knownById = {for (final s in known) s.id: s};
    final searchedIds = {for (final s in searched) s.id};
    final localOnly = known.where(
      (s) =>
          !searchedIds.contains(s.id) &&
          (q.isEmpty ||
              s.name.toLowerCase().contains(q) ||
              (s.subtitle?.toLowerCase().contains(q) ?? false) ||
              s.description.toLowerCase().contains(q) ||
              s.servicesOffered.any((x) => x.toLowerCase().contains(q))),
    );
    return [
      for (final s in [...searched, ...localOnly])
        if (_category == _allCategory || _sameName(s.category.name, _category))
          knownById.containsKey(s.id)
              ? s.copyWith(isJoined: knownById[s.id]!.isJoined)
              : s,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final serverState = ref.watch(serverProvider);

    final searchAsync = ref.watch(searchProvider(_searchKey()));
    final fetched = searchAsync.valueOrNull;
    if (fetched != null) _lastResults = fetched;
    final data = fetched ?? _lastResults ?? const SearchResults();

    final people =
        (_type == SearchResultType.servers ||
            _type == SearchResultType.projects ||
            _type == SearchResultType.events)
        ? const <EmeProfileModel>[]
        : data.people
              .where(
                (p) =>
                    _category == _allCategory ||
                    p.category.label == _category ||
                    p.tags.contains(_category),
              )
              .toList();

    final servers =
        (_type == SearchResultType.people ||
            _type == SearchResultType.projects ||
            _type == SearchResultType.events)
        ? const <ServerModel>[]
        : _filterServers(data.servers, serverState.servers);

    // Projects and events have no category, so a category pill hides them.
    final hideUncategorized = _category != _allCategory;
    final projects =
        (_type == SearchResultType.people ||
            _type == SearchResultType.servers ||
            _type == SearchResultType.events ||
            hideUncategorized)
        ? const <LibraryCollectionModel>[]
        : data.projects;
    final events =
        (_type == SearchResultType.people ||
            _type == SearchResultType.servers ||
            _type == SearchResultType.projects ||
            hideUncategorized)
        ? const <EventModel>[]
        : data.events;

    final categories = _categoryNames(serverState.categories);

    // One combined list, A-Z by name.
    final results = <_SearchResult>[
      for (final p in people) _SearchResult.person(p),
      for (final s in servers) _SearchResult.server(s),
      for (final pr in projects) _SearchResult.project(pr),
      for (final ev in events) _SearchResult.event(ev),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final loading = results.isEmpty && searchAsync.isLoading;
    final errors = [if (searchAsync.hasError) 'Search: ${searchAsync.error}'];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Semantics(
          identifier: 'search_back',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text('Search'),
        actions: [
          Semantics(
            identifier: 'add_custom_server',
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded, size: 24),
              tooltip: 'Add Custom Server',
              color: AppColors.primary,
              onPressed: _openAddServerSheet,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(isDark),
              const SizedBox(height: 12),
              _buildSearchField(searchAsync.isLoading && _lastResults != null),
              const SizedBox(height: 12),
              _buildCategoryBar(categories, isDark),
              const SizedBox(height: 20),

              _buildResultsHeader(
                peopleCount: people.length,
                projectCount: projects.length,
                serverCount: servers.length,
                eventCount: events.length,
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              for (final e in errors) ...[
                _buildErrorLine(e),
                const SizedBox(height: 8),
              ],
              if (loading)
                _buildLoading()
              else if (results.isEmpty)
                _buildEmptyState(isDark)
              else
                _buildResultsTable(results, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isSearching) {
    return Semantics(
      identifier: 'search_input',
      child: TextField(
        controller: _searchController,
        autofocus: false,
        onChanged: (_) {
          setState(() {});
          _runSearch();
        },
        decoration: InputDecoration(
          hintText: 'Search people, projects, servers and events...',
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          suffixIcon: isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              : (_searchController.text.isNotEmpty
                    ? Semantics(
                        identifier: 'search_clear',
                        child: IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          tooltip: 'Clear',
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            _runSearch();
                          },
                        ),
                      )
                    : null),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Semantics(
      identifier: 'search_type_selector',
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip(
                label: 'All',
                type: SearchResultType.all,
                semanticId: 'search_type_all',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'People',
                type: SearchResultType.people,
                semanticId: 'search_type_people',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Projects',
                type: SearchResultType.projects,
                semanticId: 'search_type_projects',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Servers',
                type: SearchResultType.servers,
                semanticId: 'search_type_servers',
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Events',
                type: SearchResultType.events,
                semanticId: 'search_type_events',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required SearchResultType type,
    required String semanticId,
    required bool isDark,
  }) {
    final isSelected = _type == type;

    return Semantics(
      identifier: semanticId,
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _type = type),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.darkSurface : AppColors.lightBg),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark
                          ? AppColors.darkCardBorder
                          : AppColors.lightCardBorder),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBar(List<String> categories, bool isDark) {
    final selectedBg = isDark ? AppColors.primary : const Color(0xFF64748B);

    return Semantics(
      identifier: 'search_category_bar',
      child: SizedBox(
        height: 36,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final name = categories[index];
              final isSelected = _sameName(name, _category);

              return Semantics(
                identifier: 'search_category_$index',
                child: InkWell(
                  onTap: () => _selectCategory(name),
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectedBg
                          : (isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark
                                  ? AppColors.darkCardBorder
                                  : AppColors.lightCardBorder),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                    ? AppColors.textDarkSecondary
                                    : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResultsHeader({
    required int peopleCount,
    required int projectCount,
    required int serverCount,
    required int eventCount,
    required bool isDark,
  }) {
    final muted = isDark ? AppColors.textDarkMuted : AppColors.textMuted;
    final counts = <String>[
      if (_type == SearchResultType.all || _type == SearchResultType.people)
        '$peopleCount people',
      if (_type == SearchResultType.all || _type == SearchResultType.projects)
        '$projectCount projects',
      if (_type == SearchResultType.all || _type == SearchResultType.servers)
        '$serverCount servers',
      if (_type == SearchResultType.all || _type == SearchResultType.events)
        '$eventCount events',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Results',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            counts.join(' · '),
            maxLines: 2,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsTable(List<_SearchResult> results, bool isDark) {
    final border = isDark
        ? AppColors.darkCardBorder
        : AppColors.lightCardBorder;
    return Semantics(
      identifier: 'search_results',
      // Material (not a decorated Container) so row ink splashes show.
      child: Material(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: results.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: border),
          itemBuilder: (context, index) =>
              _buildResultRow(results[index], index, isDark),
        ),
      ),
    );
  }

  Widget _buildResultRow(_SearchResult r, int index, bool isDark) {
    final secondary = isDark
        ? AppColors.textDarkSecondary
        : AppColors.textSecondary;
    final Color typeColor;
    if (r.isEvent) {
      typeColor = const Color(0xFFEA580C);
    } else if (r.isProject) {
      typeColor = const Color(0xFF3B82F6);
    } else if (r.isServer) {
      typeColor = const Color(0xFF6366F1);
    } else {
      typeColor = AppColors.primary;
    }

    final server = r.server;
    final joining =
        server != null &&
        ref.watch(serverProvider.select((s) => s.isJoining(server.id)));

    return Semantics(
      identifier: 'search_result_$index',
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          final person = r.person;
          if (r.event != null) {
            Navigator.of(context).push(EventScreen.route(r.event!));
          } else if (person != null) {
            EmeProfileCard(profile: person).showDetails(context);
          } else if (r.isProject) {
            final project = r.collection!;
            ProjectPreviewCard.show(
              context,
              project: project,
              onOpen: () => Navigator.of(
                context,
              ).push(ProjectScreen.routeForCollection(project)),
            );
          } else {
            ServerPreviewCard.show(
              context,
              server: server!,
              onJoin: () =>
                  ServerCard(server: server).joinAndOpen(context, ref),
            );
          }
        },
        leading: _buildResultAvatar(r, isDark),
        title: Text(
          r.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          [r.category, r.detail].where((t) => t.isNotEmpty).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontSize: 12, color: secondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                r.isEvent
                    ? 'Event'
                    : (r.isProject
                          ? 'Project'
                          : (r.isServer ? 'Server' : 'Person')),
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: typeColor,
                ),
              ),
            ),
            if (server != null && !r.isProject && !r.isEvent) ...[
              const SizedBox(height: 4),
              Text(
                joining
                    ? 'Joining...'
                    : (server.isJoined ? 'Joined' : 'Tap to preview'),
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: server.isJoined ? AppColors.greenAccent : secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultAvatar(_SearchResult r, bool isDark) {
    final fallback = CircleAvatar(
      radius: 22,
      backgroundColor: r.color.withValues(alpha: isDark ? 0.25 : 0.12),
      child: (r.isServer || r.isProject || r.isEvent)
          ? Text(
              r.initials,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: r.color,
              ),
            )
          : Icon(Icons.person_rounded, color: r.color),
    );
    final url = r.avatarUrl;
    if (url == null || url.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }

  Widget _buildErrorLine(String message) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: AppColors.redAccent,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.redAccent),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 40,
            color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
          ),
          const SizedBox(height: 10),
          Text(
            'No results',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try a different search or category, or add a custom server.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            identifier: 'search_reset_filters',
            child: OutlinedButton(
              onPressed: _resetFilters,
              child: const Text('Reset filters'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row in the combined results: a person, a project, a server or an event.
class _SearchResult {
  final EmeProfileModel? person;
  final ServerModel? server;
  final LibraryCollectionModel? collection;
  final EventModel? event;
  final bool isProject;

  const _SearchResult.person(EmeProfileModel this.person)
    : server = null,
      collection = null,
      event = null,
      isProject = false;

  const _SearchResult.server(ServerModel this.server)
    : person = null,
      collection = null,
      event = null,
      isProject = false;

  const _SearchResult.project(LibraryCollectionModel this.collection)
    : person = null,
      server = null,
      event = null,
      isProject = true;

  const _SearchResult.event(EventModel this.event)
    : person = null,
      server = null,
      collection = null,
      isProject = false;

  bool get isEvent => event != null;
  bool get isServer => server != null && !isProject;

  String get name {
    if (isEvent) return event!.name;
    if (isProject && collection != null && collection!.name.isNotEmpty) {
      return collection!.name;
    }
    return person?.name ?? server!.name;
  }

  String get category {
    if (isEvent) return 'Event';
    if (isProject) {
      return collection?.isProposal == true ? 'Proposal' : 'Project';
    }
    return person?.category.label ?? server!.category.name;
  }

  String get detail {
    if (isEvent) {
      return [
        if (event!.startDate != null) formatEventDate(event!.startDate!),
        event!.location,
      ].where((t) => t.isNotEmpty).join(' · ');
    }
    final p = person;
    if (p != null) return p.specialistTitle ?? p.location ?? '';
    if (isProject && collection != null) return collection!.displayDescription;
    return server!.subtitle ?? server!.description;
  }

  String? get avatarUrl {
    if (isEvent) return event!.imageUrl;
    if (isProject) {
      return collection?.primaryImageUrl;
    }
    return isServer ? server!.avatarUrl : person!.avatarUrl;
  }

  Color get color {
    if (isEvent) return const Color(0xFFEA580C);
    if (isProject) return const Color(0xFF3B82F6);
    return person?.primaryColor ?? server!.primaryColor;
  }

  String get initials {
    final label = isEvent
        ? event!.name
        : (isProject ? collection?.name ?? '' : '');
    if (label.isNotEmpty) {
      final words = label.trim().split(RegExp(r'\s+'));
      if (words.length >= 2 && words[0].isNotEmpty && words[1].isNotEmpty) {
        return (words[0][0] + words[1][0]).toUpperCase();
      }
      return label.substring(0, label.length.clamp(1, 2)).toUpperCase();
    }
    return server?.displayInitials ?? 'PR';
  }
}
