import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';

enum AddTeamMemberMode { search, newUser }

/// The web sidebar's "Add Agent" (search existing users) and "New User"
/// (add by email) dialogs. Puts the user on the project's team.
class AddTeamMemberSheet extends ConsumerStatefulWidget {
  final ProjectCollectionKey collectionKey;
  final AddTeamMemberMode mode;

  const AddTeamMemberSheet({
    super.key,
    required this.collectionKey,
    required this.mode,
  });

  static Future<void> show(
    BuildContext context, {
    required ProjectCollectionKey collectionKey,
    required AddTeamMemberMode mode,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          AddTeamMemberSheet(collectionKey: collectionKey, mode: mode),
    );
  }

  @override
  ConsumerState<AddTeamMemberSheet> createState() => _AddTeamMemberSheetState();
}

class _AddTeamMemberSheetState extends ConsumerState<AddTeamMemberSheet> {
  final _queryController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  Future<List<EmeProfileModel>>? _results;
  bool _busy = false;

  @override
  void dispose() {
    _queryController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _results = ref.read(apiServiceProvider).searchUsers(query);
    });
  }

  Future<void> _add({String? userId}) async {
    final email = _emailController.text.trim();
    if (userId == null && !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email address')),
      );
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(apiServiceProvider)
          .addProjectTeamMember(
            widget.collectionKey.collectionId,
            userId: userId,
            email: userId == null ? email : null,
            firstName: userId == null ? _firstNameController.text.trim() : null,
            lastName: userId == null ? _lastNameController.text.trim() : null,
          );
      ref.invalidate(projectCollectionProvider(widget.collectionKey));
      if (mounted) Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Added to the team')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redAccent,
          content: Text('Could not add to the team: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSearch = widget.mode == AddTeamMemberMode.search;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      // Material, not a decorated Container, so the result ListTiles can ink.
      child: Material(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isSearch ? 'Add Agent' : 'Add New User to Team',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              if (isSearch) ..._buildSearch(isDark) else ..._buildNewUser(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSearch(bool isDark) {
    return [
      Semantics(
        identifier: 'project_add_agent_input',
        child: TextField(
          controller: _queryController,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'Search people by name or email',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: Semantics(
              identifier: 'project_add_agent_search',
              child: IconButton(
                icon: const Icon(Icons.arrow_forward_rounded),
                tooltip: 'Search',
                onPressed: _search,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      if (_results != null)
        Flexible(
          child: FutureBuilder<List<EmeProfileModel>>(
            future: _results,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Search failed: ${snapshot.error}'),
                );
              }
              final people = snapshot.data ?? const [];
              if (people.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No people found'),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: people.length,
                itemBuilder: (context, index) {
                  final person = people[index];
                  return Semantics(
                    identifier: 'project_add_agent_result_$index',
                    child: ListTile(
                      enabled: !_busy,
                      leading: CircleAvatar(
                        foregroundImage: person.avatarUrl != null
                            ? NetworkImage(person.avatarUrl!)
                            : null,
                        child: Text(
                          person.name.isNotEmpty
                              ? person.name[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(person.name),
                      subtitle: Text(person.username),
                      trailing: const Icon(Icons.person_add_alt_1_rounded),
                      onTap: () => _add(userId: person.username),
                    ),
                  );
                },
              );
            },
          ),
        ),
    ];
  }

  List<Widget> _buildNewUser() {
    return [
      Semantics(
        identifier: 'project_new_user_email',
        child: TextField(
          controller: _emailController,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
      ),
      const SizedBox(height: 8),
      Semantics(
        identifier: 'project_new_user_first_name',
        child: TextField(
          controller: _firstNameController,
          decoration: const InputDecoration(labelText: 'First name'),
        ),
      ),
      const SizedBox(height: 8),
      Semantics(
        identifier: 'project_new_user_last_name',
        child: TextField(
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: 'Last name'),
        ),
      ),
      const SizedBox(height: 16),
      Semantics(
        identifier: 'project_new_user_submit',
        child: FilledButton(
          onPressed: _busy ? null : () => _add(),
          child: const Text('Add to Team'),
        ),
      ),
    ];
  }
}
