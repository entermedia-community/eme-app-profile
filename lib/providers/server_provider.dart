import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server_model.dart';

final List<String> kServerCategories = [
  'All',
  'Social Services',
  'Eco Tourism',
  'Finance',
  'Artificial Intelligence',
  'Research',
  'Software Tools',
  'Startup',
  'Education',
];

class ServerState {
  final List<ServerModel> servers;
  final String selectedCategory;
  final String searchQuery;

  const ServerState({
    required this.servers,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  List<ServerModel> get filteredServers {
    return servers.where((server) {
      final matchesCategory = selectedCategory == 'All' ||
          server.category == selectedCategory ||
          server.tags.contains(selectedCategory);

      final matchesQuery = searchQuery.isEmpty ||
          server.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          (server.subtitle?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false) ||
          server.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          server.tags.any((tag) => tag.toLowerCase().contains(searchQuery.toLowerCase()));

      return matchesCategory && matchesQuery;
    }).toList();
  }

  ServerState copyWith({
    List<ServerModel>? servers,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return ServerState(
      servers: servers ?? this.servers,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ServerNotifier extends StateNotifier<ServerState> {
  ServerNotifier()
      : super(
          ServerState(
            servers: [
              const ServerModel(
                id: 'srv_001',
                title: 'Atitlan Exchange',
                subtitle: 'STARTUPS FOR SOCIAL IMPACT',
                description:
                    'Providing exchange services for tourist and local Guatemalans around lake Atitlan.',
                category: 'Startup',
                tags: ['Social Services', 'Startup', 'Eco Tourism'],
                iconData: Icons.eco_rounded,
                primaryColor: Color(0xFF059669),
                secondaryColor: Color(0xFFECFDF5),
                memberCount: 840,
                bannerSvgOrType: 'gear_eco',
              ),
              const ServerModel(
                id: 'srv_002',
                title: 'Atitlan Passports',
                subtitle: 'IMPACT BANK',
                description:
                    'Decentralized impact identity and financial passporting system for global mobility.',
                category: 'Finance',
                tags: ['Startup', 'Finance'],
                iconData: Icons.account_balance_outlined,
                primaryColor: Color(0xFF0284C7),
                secondaryColor: Color(0xFFF0F9FF),
                memberCount: 1420,
                bannerSvgOrType: 'impact_bank',
              ),
              const ServerModel(
                id: 'srv_003',
                title: 'Circular Panchayat of India',
                subtitle: 'Punaryoji Vikas Services',
                description:
                    'Empowering rural communities and fostering self-sufficiency. Blueprint for a Rural Bioeconomy of Wellbeing',
                category: 'Social Services',
                tags: ['Social Services', 'Startup', 'Eco Tourism'],
                iconData: Icons.all_inclusive_rounded,
                primaryColor: Color(0xFF475569),
                secondaryColor: Color(0xFFF8FAFC),
                memberCount: 620,
                bannerSvgOrType: 'infinity_loop',
              ),
              const ServerModel(
                id: 'srv_004',
                title: 'Neural Matrix Collective',
                subtitle: 'DEEP TECH INFERENCE',
                description:
                    'Open collective intelligence compute nodes and decentralized agent coordination.',
                category: 'Artificial Intelligence',
                tags: ['Artificial Intelligence', 'Software Tools', 'Research'],
                iconData: Icons.auto_awesome_rounded,
                primaryColor: Color(0xFF7C3AED),
                secondaryColor: Color(0xFFF5F3FF),
                memberCount: 2310,
                bannerSvgOrType: 'ai_brain',
              ),
              const ServerModel(
                id: 'srv_005',
                title: 'EcoTourism Sanctuary',
                subtitle: 'CONSERVATION HUB',
                description:
                    'Community-driven biodiversity preservation and regenerative travel experiences.',
                category: 'Eco Tourism',
                tags: ['Eco Tourism', 'Social Services'],
                iconData: Icons.forest_rounded,
                primaryColor: Color(0xFF16A34A),
                secondaryColor: Color(0xFFF0FDF4),
                memberCount: 940,
                bannerSvgOrType: 'tree_canopy',
              ),
              const ServerModel(
                id: 'srv_006',
                title: 'Developer Nexus Tools',
                subtitle: 'OPEN SOURCE FORGE',
                description:
                    'Modular developer utilities, smart contracts, and microservice mesh integrations.',
                category: 'Software Tools',
                tags: ['Software Tools', 'Startup'],
                iconData: Icons.terminal_rounded,
                primaryColor: Color(0xFFEA580C),
                secondaryColor: Color(0xFFFFF7ED),
                memberCount: 1850,
                bannerSvgOrType: 'dev_forge',
              ),
            ],
          ),
        );

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void addServer(ServerModel server) {
    state = state.copyWith(servers: [server, ...state.servers]);
  }

  void toggleJoin(String id) {
    final updated = state.servers.map((s) {
      if (s.id == id) {
        return s.copyWith(isJoined: !s.isJoined);
      }
      return s;
    }).toList();
    state = state.copyWith(servers: updated);
  }
}

final serverProvider = StateNotifierProvider<ServerNotifier, ServerState>((ref) {
  return ServerNotifier();
});
