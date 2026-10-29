import 'package:flutter/material.dart';
import '../../widgets/entity_assets/entity_asset_list.dart';
import '../../widgets/entity_assets/entity_asset_upload_button.dart';

/// Entity assets of a project, opened from the project's 3-dot menu.
class EntityAssetsScreen extends StatelessWidget {
  final String collectionId;

  const EntityAssetsScreen({super.key, required this.collectionId});

  static Route<void> route(String collectionId) => MaterialPageRoute<void>(
    builder: (_) => EntityAssetsScreen(collectionId: collectionId),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          identifier: 'entity_assets_back_button',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        title: const Text('Entity Assets'),
        actions: [EntityAssetUploadButton(collectionId: collectionId)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [EntityAssetList(collectionId: collectionId)],
      ),
    );
  }
}
