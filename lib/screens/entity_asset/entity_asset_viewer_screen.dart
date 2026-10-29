import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';

/// Shows the file behind an entity asset: image, PDF or video in a viewer;
/// anything else offers a download.
class EntityAssetViewerScreen extends StatelessWidget {
  final EntityAssetModel asset;

  const EntityAssetViewerScreen({super.key, required this.asset});

  static Route<void> route(EntityAssetModel asset) => MaterialPageRoute<void>(
    builder: (_) => EntityAssetViewerScreen(asset: asset),
  );

  /// The media URLs need the same bearer token as the API calls.
  static Future<Map<String, String>> authHeaders() async {
    final token = await SharedPref.getEMKey() ?? AuthService.token;
    return {
      'X-tokentype': 'entermedia',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<void> download(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = asset.mediaUrl;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: mediaUrl == null ? null : 96,
        leading: Semantics(
          identifier: 'entity_asset_viewer_back_button',
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        actions: mediaUrl == null
            ? null
            : [
                Semantics(
                  identifier: 'entity_asset_viewer_download_button',
                  child: IconButton(
                    icon: const Icon(Icons.download_rounded),
                    tooltip: 'Download',
                    onPressed: () => download(context, mediaUrl),
                  ),
                ),
              ],
        title: Text(
          asset.fileName ?? asset.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: authHeaders(),
        builder: (context, snapshot) {
          final url = asset.mediaUrl;
          if (url == null) {
            return const Center(child: Text('This asset has no file.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final headers = snapshot.data!;
          switch (asset.mediaType) {
            case 'image':
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    url,
                    headers: headers,
                    errorBuilder: (_, e, _) =>
                        Center(child: Text('Could not load the image: $e')),
                  ),
                ),
              );
            case 'pdf':
              return PdfViewer.uri(Uri.parse(url), headers: headers);
            case 'video':
              return _VideoPlayer(url: url, headers: headers);
            default:
              return _DownloadPrompt(asset: asset, url: url);
          }
        },
      ),
    );
  }
}

class _VideoPlayer extends StatefulWidget {
  final String url;
  final Map<String, String> headers;

  const _VideoPlayer({required this.url, required this.headers});

  @override
  State<_VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<_VideoPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _ready;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: widget.headers,
    );
    _ready = _controller.initialize().then((_) => _controller.play());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Could not play the video: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
            VideoProgressIndicator(_controller, allowScrubbing: true),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller,
              builder: (_, value, _) => Semantics(
                identifier: 'entity_asset_video_toggle',
                child: IconButton(
                  iconSize: 40,
                  tooltip: value.isPlaying ? 'Pause' : 'Play',
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                  onPressed: () => value.isPlaying
                      ? _controller.pause()
                      : _controller.play(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DownloadPrompt extends StatelessWidget {
  final EntityAssetModel asset;
  final String url;

  const _DownloadPrompt({required this.asset, required this.url});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_outlined, size: 64),
            const SizedBox(height: 12),
            Text(asset.fileName ?? asset.name, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            const Text('This file type cannot be previewed.'),
            const SizedBox(height: 16),
            Semantics(
              identifier: 'entity_asset_download',
              child: FilledButton.icon(
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download to device'),
                onPressed: () => EntityAssetViewerScreen.download(context, url),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
