import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';

/// Dialog to put someone on a project's team: pick from the list of users, or
/// add a new one by first name, last name and email.
class AddTeamMemberDialog extends ConsumerStatefulWidget {
  final ProjectCollectionKey collectionKey;

  const AddTeamMemberDialog({super.key, required this.collectionKey});

  static Future<void> show(
    BuildContext context, {
    required ProjectCollectionKey collectionKey,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AddTeamMemberDialog(collectionKey: collectionKey),
    );
  }

  @override
  ConsumerState<AddTeamMemberDialog> createState() =>
      _AddTeamMemberDialogState();
}

class _AddTeamMemberDialogState extends ConsumerState<AddTeamMemberDialog> {
  final _filterController = TextEditingController();
  final _emailController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _byEmail = false;
  bool _busy = false;

  @override
  void dispose() {
    _filterController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _add({String? userId}) async {
    final messenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    if (userId == null && !email.contains('@')) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter a valid email address')),
      );
      return;
    }
    setState(() => _busy = true);
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
      ref.invalidate(
        projectTeamCandidatesProvider(widget.collectionKey.collectionId),
      );
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
    return AlertDialog(
      title: const Text('Add team member'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: const Text('Users'),
                  icon: Semantics(
                    identifier: 'team_add_mode_users',
                    child: const Icon(Icons.people_alt_outlined),
                  ),
                ),
                ButtonSegment(
                  value: true,
                  label: const Text('New user'),
                  icon: Semantics(
                    identifier: 'team_add_mode_new',
                    child: const Icon(Icons.person_add_alt_outlined),
                  ),
                ),
              ],
              selected: {_byEmail},
              onSelectionChanged: (s) => setState(() => _byEmail = s.first),
            ),
            const SizedBox(height: 12),
            Flexible(child: _byEmail ? _buildNewUser() : _buildUsers()),
          ],
        ),
      ),
      actions: [
        Semantics(
          identifier: 'team_add_cancel',
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
        if (_byEmail)
          Semantics(
            identifier: 'team_add_submit',
            child: FilledButton(
              onPressed: _busy ? null : () => _add(),
              child: const Text('Add to team'),
            ),
          ),
      ],
    );
  }

  Widget _buildUsers() {
    final users = ref.watch(
      projectTeamCandidatesProvider(widget.collectionKey.collectionId),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          identifier: 'team_add_filter',
          child: TextField(
            controller: _filterController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Filter users',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Flexible(
          child: users.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Could not load users: $e'),
            data: (all) {
              final q = _filterController.text.trim().toLowerCase();
              final list = all
                  .where(
                    (p) =>
                        q.isEmpty ||
                        p.name.toLowerCase().contains(q) ||
                        p.username.toLowerCase().contains(q),
                  )
                  .toList();
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No users found'),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final p = list[i];
                  return Semantics(
                    identifier: 'team_add_user_${p.username}',
                    child: ListTile(
                      enabled: !_busy,
                      leading: CircleAvatar(
                        foregroundImage: p.avatarUrl != null
                            ? NetworkImage(p.avatarUrl!)
                            : null,
                        child: Text(
                          p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        ),
                      ),
                      title: Text(p.name),
                      subtitle: Text(p.username),
                      trailing: const Icon(Icons.person_add_alt_1_rounded),
                      onTap: () => _add(userId: p.username),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNewUser() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            identifier: 'team_add_first_name',
            child: TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            identifier: 'team_add_last_name',
            child: TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            identifier: 'team_add_email',
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ),
        ],
      ),
    );
  }
}
