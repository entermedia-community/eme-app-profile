import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/entity_assets/entity_asset_upload_button.dart';
import '../../widgets/files/files_section.dart';

/// The signed-in user's knowledgebase (entity assets). Opened from the app
/// bar menu; uploads start from the app bar.
class MyKnowledgebaseScreen extends ConsumerWidget {
  const MyKnowledgebaseScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MyKnowledgebaseScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.username;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Knowledgebase'),
        actions: [EntityAssetUploadButton(userId: userId)],
      ),
      body: const SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: FilesSection(),
      ),
    );
  }
}
