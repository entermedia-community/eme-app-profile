import 'package:eme_world/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../profile/widgets/profile_projects_section.dart';
import 'create_project_screen.dart';

/// Projects the signed-in user owns or is on the team of. Opened from the
/// app bar menu.
class MyProjectsScreen extends StatelessWidget {
  const MyProjectsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const MyProjectsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        actions: [
          Semantics(
            identifier: 'my_projects_new',
            child: IconButton(
              onPressed: () => CreateProjectScreen.open(context),
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.greenAccent,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.greenAccent.withValues(alpha: 0.1),
              ),
            ),
          ),
        ],
      ),
      body: const SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        // Bottom room so the button doesn't cover the last project.
        padding: EdgeInsets.fromLTRB(16, 16, 16, 88),
        child: ProfileProjectsSection(),
      ),
    );
  }
}
