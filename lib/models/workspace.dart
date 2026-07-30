class Workspace {
  final String id;
  final String name;
  final String mediaDBRoot;
  final String? iconAsset;

  const Workspace({
    required this.id,
    required this.name,
    required this.mediaDBRoot,
    this.iconAsset,
  });

  /// Extracts the hostname label from a URL or mediaDBRoot string.
  /// Example: 'https://minsur.genailabs.tech/site/mediadb' -> 'minsur'
  static String extractHostname(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return 'workspace';
    try {
      final formattedUrl =
          trimmed.contains('://') ? trimmed : 'https://$trimmed';
      final uri = Uri.parse(formattedUrl);
      final host = uri.host.isNotEmpty ? uri.host : trimmed;
      final parts = host.split('.');
      if (parts.isNotEmpty) {
        final first = parts.first.toLowerCase();
        if (first != 'www' && first.isNotEmpty) {
          return first;
        } else if (parts.length > 1) {
          return parts[1].toLowerCase();
        }
      }
      return host.toLowerCase();
    } catch (_) {
      return 'workspace';
    }
  }

  /// Capitalizes a string (e.g. 'minsur' -> 'Minsur')
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    if (text.length == 1) return text.toUpperCase();
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Creates a dynamic [Workspace] requiring only [mediaDBRoot].
  /// Defaults:
  /// - [id]: lowercase hostname extracted from [mediaDBRoot]
  /// - [name]: capitalized hostname extracted from [mediaDBRoot]
  /// - [iconAsset]: null
  factory Workspace.fromMediaDBRoot(
    String mediaDBRoot, {
    String? id,
    String? name,
    String? iconAsset,
  }) {
    final hostname = extractHostname(mediaDBRoot);
    final derivedId = (id != null && id.trim().isNotEmpty)
        ? id.trim().toLowerCase()
        : hostname.toLowerCase();
    final derivedName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : capitalize(hostname);

    return Workspace(
      id: derivedId,
      name: derivedName,
      mediaDBRoot: mediaDBRoot.trim(),
      iconAsset: iconAsset,
    );
  }

  factory Workspace.fromJson(Map<String, dynamic> json) {
    final mediaDBRoot =
        json['mediaDBRoot'] as String? ?? json['mediadbroot'] as String? ?? '';
    final hostname = extractHostname(mediaDBRoot);

    final rawId = json['id'] as String?;
    final id = (rawId != null && rawId.trim().isNotEmpty)
        ? rawId.trim().toLowerCase()
        : hostname.toLowerCase();

    final rawName = json['name'] as String?;
    final name = (rawName != null && rawName.trim().isNotEmpty)
        ? rawName.trim()
        : capitalize(hostname);

    final iconAsset =
        json['iconAsset'] as String? ?? json['iconasset'] as String?;

    return Workspace(
      id: id,
      name: name,
      mediaDBRoot: mediaDBRoot,
      iconAsset: iconAsset,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mediaDBRoot': mediaDBRoot,
        if (iconAsset != null) 'iconAsset': iconAsset,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Workspace &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          mediaDBRoot == other.mediaDBRoot;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ mediaDBRoot.hashCode;
}
