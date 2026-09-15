import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server_model.dart';

final List<String> kServerCategories = [
  'All',
  'Eco Tourism',
  'Finance',
  'Artificial Intelligence',
  'Social Services',
  'Software Tools',
  'Research',
  'Education',
  'Healthcare',
  'Startup',
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

  /// Servers that the user has already joined (for the Profile page)
  List<ServerModel> get joinedServers {
    return servers.where((s) => s.isJoined).toList();
  }

  int get joinedCount => joinedServers.length;

  int get serverCount => servers.length;

  /// Servers filtered for Server Picker & Catalog
  List<ServerModel> get filteredServers {
    return servers.where((item) {
      // Category Filter
      final matchesCategory = selectedCategory == 'All' ||
          item.category == selectedCategory ||
          item.tags.contains(selectedCategory);

      if (!matchesCategory) return false;

      // Search Query Filter
      if (searchQuery.isEmpty) return true;

      final query = searchQuery.toLowerCase();
      final titleMatch = item.title.toLowerCase().contains(query);
      final subtitleMatch =
          item.subtitle?.toLowerCase().contains(query) ?? false;
      final descMatch = item.description.toLowerCase().contains(query);
      final tagMatch = item.tags.any(
        (tag) => tag.toLowerCase().contains(query),
      );
      final serviceMatch = item.servicesOffered.any(
        (srv) => srv.toLowerCase().contains(query),
      );
      final locationMatch =
          item.location?.toLowerCase().contains(query) ?? false;

      return titleMatch ||
          subtitleMatch ||
          descMatch ||
          tagMatch ||
          serviceMatch ||
          locationMatch;
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
          const ServerState(
            servers: [
              // ==========================================
              // SERVERS (Joined by default for Profile)
              // ==========================================
              ServerModel(
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
                isJoined: true, // Joined server for Profile page
                location: 'Lake Atitlan, Guatemala',
                servicePricing: 'Free / DAO Fee',
                servicesOffered: [
                  'Currency Exchange',
                  'Local Merchant Settlement',
                  'Eco Tourism Passports',
                ],
                lastNotification: 'Liquidity pool rebalanced & DAO settlement active',
                lastNotificationTime: '2m ago',
                status: 'Operational',
                statusColor: Color(0xFF10B981),
              ),
              ServerModel(
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
                isJoined: true, // Joined server for Profile page
                location: 'Global / Decentralized',
                servicePricing: '0% Humanitarian Fee',
                servicesOffered: [
                  'Biometric ID Issuance',
                  'Cross-border Verification',
                  'Micro-credit Escrow',
                ],
                lastNotification: 'Identity mesh verified (v2.4) • Zero alerts',
                lastNotificationTime: '15m ago',
                status: 'Healthy',
                statusColor: Color(0xFF0284C7),
              ),

              // ==========================================
              // SERVERS (Discoverable in EME World)
              // ==========================================
              ServerModel(
                id: 'srv_003',
                title: 'Circular Panchayat of India',
                subtitle: 'Punaryoji Vikas Services',
                description:
                    'Empowering rural communities and fostering self-sufficiency. Blueprint for a Rural Bioeconomy of Wellbeing.',
                category: 'Social Services',
                tags: ['Social Services', 'Startup', 'Eco Tourism'],
                iconData: Icons.all_inclusive_rounded,
                primaryColor: Color(0xFF475569),
                secondaryColor: Color(0xFFF8FAFC),
                memberCount: 620,
                bannerSvgOrType: 'infinity_loop',
                isJoined: false,
                location: 'Rural India Nodes',
                servicePricing: 'Community Grants',
                servicesOffered: [
                  'Agricultural IoT telemetry',
                  'Circular Waste Loops',
                  'Bio-economy Governance',
                ],
                lastNotification: 'Soil telemetry sync completed across 42 nodes',
                lastNotificationTime: '1h ago',
                status: 'Sync Complete',
                statusColor: Color(0xFF10B981),
              ),
              ServerModel(
                id: 'srv_004',
                title: 'Neural Matrix Collective',
                subtitle: 'DEEP TECH INFERENCE',
                description:
                    'Open collective intelligence compute nodes and decentralized agent coordination mesh.',
                category: 'Artificial Intelligence',
                tags: ['Artificial Intelligence', 'Software Tools', 'Research'],
                iconData: Icons.auto_awesome_rounded,
                primaryColor: Color(0xFF7C3AED),
                secondaryColor: Color(0xFFF5F3FF),
                memberCount: 2310,
                bannerSvgOrType: 'ai_brain',
                isJoined: false,
                location: 'Global DePIN',
                servicePricing: 'Pay-per-token / Staking',
                servicesOffered: [
                  'Distributed Model Inference',
                  'Agent Swarm Hosting',
                  'Dataset Verification',
                ],
                lastNotification: 'High compute load • 12 inference workers active',
                lastNotificationTime: 'Just now',
                status: 'High Load',
                statusColor: Color(0xFFF59E0B),
              ),
              ServerModel(
                id: 'srv_005',
                title: 'EcoTourism Sanctuary',
                subtitle: 'CONSERVATION HUB',
                description:
                    'Community-driven biodiversity preservation, carbon sink auditing, and regenerative travel experiences.',
                category: 'Eco Tourism',
                tags: ['Eco Tourism', 'Social Services'],
                iconData: Icons.forest_rounded,
                primaryColor: Color(0xFF16A34A),
                secondaryColor: Color(0xFFF0FDF4),
                memberCount: 940,
                bannerSvgOrType: 'tree_canopy',
                isJoined: false,
                location: 'Costa Rica & Amazonia',
                servicePricing: 'Bio-credits & Bookings',
                servicesOffered: [
                  'Eco-stay Booking',
                  'Regenerative Credits',
                  'Flora & Fauna Tracking',
                ],
                lastNotification: 'Carbon sink audit verified for Amazonia zone',
                lastNotificationTime: '3h ago',
                status: 'Verified',
                statusColor: Color(0xFF10B981),
              ),
              ServerModel(
                id: 'srv_006',
                title: 'Developer Nexus Tools',
                subtitle: 'OPEN SOURCE FORGE',
                description:
                    'Modular developer utilities, smart contracts, zero-knowledge toolchains, and microservice mesh.',
                category: 'Software Tools',
                tags: ['Software Tools', 'Startup'],
                iconData: Icons.terminal_rounded,
                primaryColor: Color(0xFFEA580C),
                secondaryColor: Color(0xFFFFF7ED),
                memberCount: 1850,
                bannerSvgOrType: 'dev_forge',
                isJoined: false,
                location: 'Global Open Source',
                servicePricing: '100% Free & Open Source',
                servicesOffered: [
                  'Smart Contract Templates',
                  'CI/CD Web3 Oracles',
                  'Decentralized Storage APIs',
                ],
                lastNotification: 'Oracle smart contract release v1.8 deployed',
                lastNotificationTime: '5h ago',
                status: 'Updated',
                statusColor: Color(0xFFEA580C),
              ),
              ServerModel(
                id: 'srv_007',
                title: 'Decentralized Health Mesh',
                subtitle: 'TELEMEDICINE & CLINICAL REGISTRY',
                description:
                    'Privacy-preserving clinical trial data registry and peer-to-peer remote doctor consultations.',
                category: 'Healthcare',
                tags: ['Healthcare', 'Research', 'Social Services'],
                iconData: Icons.health_and_safety_rounded,
                primaryColor: Color(0xFFE11D48),
                secondaryColor: Color(0xFFFFF1F2),
                memberCount: 780,
                bannerSvgOrType: 'health_mesh',
                isJoined: false,
                location: 'Geneva / Remote',
                servicePricing: 'Tiered Medical Escrow',
                servicesOffered: [
                  'Zero-Knowledge Health Records',
                  'Remote Triage Consultations',
                  'Drug Efficacy Registry',
                ],
                lastNotification: 'Zero-knowledge clinical batch finalized',
                lastNotificationTime: 'Yesterday',
                status: 'Synced',
                statusColor: Color(0xFFE11D48),
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

final serverProvider = StateNotifierProvider<ServerNotifier, ServerState>((
  ref,
) {
  return ServerNotifier();
});
