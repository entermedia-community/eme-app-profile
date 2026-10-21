import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../theme/app_colors.dart';
import '../eme_world/eme_profile_card.dart';
import '../../screens/profile/widgets/add_server_sheet.dart';
import '../../screens/profile/widgets/server_card.dart';

enum SearchResultType { all, people, servers }

/// One search for people and EME Servers: a single query field and a single
/// category bar, with the two result lists shown in their own sections.
///
/// Until the backend has a combined search, the query and category are sent
/// to both the people search (`emeProfileProvider`) and the server search
/// (`serverProvider`), and the results are merged into one list. The category
/// pills are the backend server categories plus the EME profile categories,
/// de-duplicated by name; both kinds of result are matched by category name.
class UnifiedSearchScreen extends ConsumerStatefulWidget {
  const UnifiedSearchScreen({super.key});

  /// Opens Search as a full-screen modal.
  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const UnifiedSearchScreen(),
      ),
    );
  }

  @override
  ConsumerState<UnifiedSearchScreen> createState() =>
      _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends ConsumerState<UnifiedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SearchResultType _type = SearchResultType.all;
  String _category = _allCategory;

  static const _allCategory = 'All';

  String get _query => _searchController.text.trim();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(emeProfileProvider.notifier)
        ..clearSearch()
        ..setCategory('All')
        ..loadUsers();
      ref.read(serverProvider.notifier).loadServersFromApi();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch() {
    final q = _query;
    ref.read(emeProfileProvider.notifier).searchUsers(q);
    ref
        .read(serverProvider.notifier)
        .loadServersFromApi(
          query: q.isEmpty ? null : q,
          category: _serverCategoryId(),
        );
  }

  bool _sameName(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  /// Backend id of the selected category for the server search, if the
  /// servers have a category by that name.
  String? _serverCategoryId() {
    if (_category == _allCategory) return ServerCategoryModel.all.id;
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
    ref.read(emeProfileProvider.notifier).setCategory(name);
    ref
        .read(serverProvider.notifier)
        .loadServersFromApi(
          query: _query.isEmpty ? null : _query,
          category: _serverCategoryId(),
        );
  }

  void _resetFilters() {
    _searchController.clear();
    setState(() => _type = SearchResultType.all);
    _selectCategory(_allCategory);
    ref.read(emeProfileProvider.notifier).clearSearch();
  }

  Future<void> _refresh() async {
    await Future.wait([
      ref.read(emeProfileProvider.notifier).loadUsers(),
      ref
          .read(serverProvider.notifier)
          .loadServersFromApi(
            query: _query.isEmpty ? null : _query,
            category: _serverCategoryId(),
            forceRefreshCategories: true,
          ),
    ]);
  }

  void _openAddServerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddServerSheet(),
    );
  }

  List<ServerModel> _filterServers(List<ServerModel> servers) {
    final q = _query.toLowerCase();
    return servers.where((s) {
      if (_category != _allCategory && !_sameName(s.category.name, _category)) {
        return false;
      }
      if (q.isEmpty) return true;
      return s.name.toLowerCase().contains(q) ||
          (s.subtitle?.toLowerCase().contains(q) ?? false) ||
          s.description.toLowerCase().contains(q) ||
          s.servicesOffered.any((x) => x.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileState = ref.watch(emeProfileProvider);
    final serverState = ref.watch(serverProvider);

    final people = _type == SearchResultType.servers
        ? const <EmeProfileModel>[]
        : profileState.filteredProfiles;
    final servers = _type == SearchResultType.people
        ? const <ServerModel>[]
        : _filterServers(serverState.servers);
    final categories = _categoryNames(serverState.categories);

    // One combined list, A-Z by name.
    final results = <_SearchResult>[
      for (final p in people) _SearchResult.person(p),
      for (final s in servers) _SearchResult.server(s),
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final loading =
        results.isEmpty &&
        ((_type != SearchResultType.servers && profileState.isLoading) ||
            (_type != SearchResultType.people && serverState.isLoading));
    final errors = [
      if (_type != SearchResultType.servers && profileState.error != null)
        'People: ${profileState.error}',
      if (_type != SearchResultType.people && serverState.error != null)
        'Servers: ${serverState.error}',
    ];

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
              _buildSearchField(profileState.isSearching),
              const SizedBox(height: 12),
              _buildCategoryBar(categories, isDark),
              const SizedBox(height: 20),

              _buildResultsHeader(people.length, servers.length, isDark),
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
          hintText: 'Search people and servers by name, skill, or topic...',
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
            label: 'Servers',
            type: SearchResultType.servers,
            semanticId: 'search_type_servers',
            isDark: isDark,
          ),
        ],
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

  Widget _buildResultsHeader(int peopleCount, int serverCount, bool isDark) {
    final muted = isDark ? AppColors.textDarkMuted : AppColors.textMuted;
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
        Text(
          '$peopleCount people · $serverCount servers',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: muted,
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
    final typeColor = r.isServer ? const Color(0xFF6366F1) : AppColors.primary;

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
          if (person != null) {
            EmeProfileCard(profile: person).showDetails(context);
          } else {
            ServerCard(server: server!).joinAndOpen(context, ref);
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
                r.isServer ? 'Server' : 'Person',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: typeColor,
                ),
              ),
            ),
            if (server != null) ...[
              const SizedBox(height: 4),
              Text(
                joining
                    ? 'Joining...'
                    : (server.isJoined ? 'Joined' : 'Tap to join'),
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
      child: r.isServer
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

/// A row in the combined results: either a person or a server.
class _SearchResult {
  final EmeProfileModel? person;
  final ServerModel? server;

  const _SearchResult.person(EmeProfileModel this.person) : server = null;
  const _SearchResult.server(ServerModel this.server) : person = null;

  bool get isServer => server != null;

  String get name => person?.name ?? server!.name;

  String get category => person?.category.label ?? server!.category.name;

  String get detail {
    final p = person;
    if (p != null) return p.specialistTitle ?? p.location ?? '';
    return server!.subtitle ?? server!.description;
  }

  String? get avatarUrl => isServer ? server!.avatarUrl : person!.avatarUrl;

  Color get color => person?.primaryColor ?? server!.primaryColor;

  String get initials => server?.displayInitials ?? '';
}
