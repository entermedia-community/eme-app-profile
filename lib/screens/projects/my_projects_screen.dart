import 'package:flutter/material.dart';
import '../profile/widgets/profile_projects_section.dart';

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
      appBar: AppBar(title: const Text('My Projects')),
      body: const SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: ProfileProjectsSection(),
      ),
    );
  }
}
