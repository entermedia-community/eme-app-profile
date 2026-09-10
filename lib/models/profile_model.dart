class ProfileModel {
  final String id;
  final String name;
  final String role;
  final String bio;
  final List<String> tags;
  final String? avatarUrl;
  final String portfolioLabel;
  final int totalServers;
  final int totalConnections;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.role,
    required this.bio,
    required this.tags,
    this.avatarUrl,
    this.portfolioLabel = 'PORTFOLIO',
    this.totalServers = 8,
    this.totalConnections = 142,
  });

  ProfileModel copyWith({
    String? id,
    String? name,
    String? role,
    String? bio,
    List<String>? tags,
    String? avatarUrl,
    String? portfolioLabel,
    int? totalServers,
    int? totalConnections,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      bio: bio ?? this.bio,
      tags: tags ?? this.tags,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      portfolioLabel: portfolioLabel ?? this.portfolioLabel,
      totalServers: totalServers ?? this.totalServers,
      totalConnections: totalConnections ?? this.totalConnections,
    );
  }
}
