import 'package:flutter/material.dart';
import '../../widgets/files/files_section.dart';

/// The signed-in user's knowledgebase (entity assets). Opened from the app
/// bar menu.
class MyKnowledgebaseScreen extends StatelessWidget {
  const MyKnowledgebaseScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MyKnowledgebaseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Knowledgebase')),
      body: const SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: FilesSection(),
      ),
    );
  }
}
