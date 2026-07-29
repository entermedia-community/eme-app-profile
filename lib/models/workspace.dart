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

  factory Workspace.fromJson(Map<String, dynamic> json) {
    return Workspace(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      mediaDBRoot:
          json['mediaDBRoot'] as String? ?? json['mediadbroot'] as String? ?? '',
      iconAsset: json['iconAsset'] as String? ?? json['iconasset'] as String?,
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
