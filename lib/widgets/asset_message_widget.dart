import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import '../models/chat_message.dart';
import 'fullscreen_mediaviewer.dart';

/// Widget for displaying a chat message of type asset.
/// Shows [assetThumbnail] image and opens [FullScreenMediaViewer] on click.
class AssetMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final String? assetThumbnail;
  final String? assetUrl;
  final String? caption;
  final String? mediaType;

  const AssetMessageWidget({
    super.key,
    required this.message,
    this.assetThumbnail,
    this.assetUrl,
    this.caption,
    this.mediaType,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveThumb = assetThumbnail ?? message.assetThumbnail;
    final effectiveUrl = assetUrl ?? message.assetUrl;
    final effectiveCaption = caption ?? message.assetCaption;
    final effectiveMediaType =
        mediaType ?? message.rawJson['mediatype']?.toString();

    final hasThumb = effectiveThumb != null && effectiveThumb.trim().isNotEmpty;
    final hasUrl = effectiveUrl != null && effectiveUrl.trim().isNotEmpty;

    if (!hasThumb && !hasUrl) {
      return const SizedBox.shrink();
    }

    final imageUrl = hasThumb ? effectiveThumb : effectiveUrl!;
    final targetUrl = hasUrl ? effectiveUrl : imageUrl;

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              FullScreenMediaViewer.open(
                context,
                url: targetUrl,
                caption: effectiveCaption,
                mediaType: effectiveMediaType,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Thumbnail image
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Container(
                        color: const Color(0xFF1E293B),
                        child: FadeInImage.memoryNetwork(
                          placeholder: kTransparentImage,
                          image: imageUrl,
                          fit: BoxFit.cover,
                          imageErrorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF1E293B),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white54,
                                    size: 36,
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Media Preview',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Soft gradient overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.35),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (effectiveCaption != null &&
              effectiveCaption.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              effectiveCaption.trim(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
