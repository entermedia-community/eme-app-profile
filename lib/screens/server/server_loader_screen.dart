import 'package:eme_app_sdk/eme_app_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'server_detail_screen.dart';

/// Resolves a server from its id (e.g. when opened from a URL or a
/// notification) and shows [ServerDetailScreen]. Shows the real error when
/// the server cannot be loaded.
class ServerLoaderScreen extends ConsumerStatefulWidget {
  const ServerLoaderScreen({super.key, required this.serverId});

  final String serverId;

  @override
  ConsumerState<ServerLoaderScreen> createState() => _ServerLoaderScreenState();
}

class _ServerLoaderScreenState extends ConsumerState<ServerLoaderScreen> {
  late Future<ServerModel?> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(apiServiceProvider).fetchServerById(widget.serverId);
  }

  void _retry() {
    setState(() {
      _future = ref.read(apiServiceProvider).fetchServerById(widget.serverId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ServerModel?>(
      future: _future,
      builder: (context, snapshot) {
        final server = snapshot.data;
        if (server != null) return ServerDetailScreen(server: server);

        final loading = snapshot.connectionState != ConnectionState.done;
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: loading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        snapshot.hasError
                            ? 'Could not load server: ${snapshot.error}'
                            : 'Server not found',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        identifier: 'server_loader_retry_button',
                        child: TextButton(
                          onPressed: _retry,
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
