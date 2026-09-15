import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server_model.dart';

final List<String> kServerCategories = [
  'All',
  'Rental & Gear',
  'Mobility & Rides',
  'Marketplace & Goods',
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
      final matchesCategory =
          selectedCategory == 'All' ||
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
              isJoined: false, // Joined server for Profile page
              location: 'Lake Atitlan, Guatemala',
              servicePricing: 'Free / DAO Fee',
              servicesOffered: [
                'Currency Exchange',
                'Local Merchant Settlement',
                'Eco Tourism Passports',
              ],
              lastNotification:
                  'Liquidity pool rebalanced & DAO settlement active',
              lastNotificationTime: '2m ago',
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
              isJoined: false, // Joined server for Profile page
              location: 'Global / Decentralized',
              servicePricing: '0% Humanitarian Fee',
              servicesOffered: [
                'Biometric ID Issuance',
                'Cross-border Verification',
                'Micro-credit Escrow',
              ],
              lastNotification: 'Identity mesh verified (v2.4) • Zero alerts',
              lastNotificationTime: '15m ago',
              statusColor: Color(0xFF0284C7),
            ),

            // ==========================================
            // SERVERS (Discoverable in EME World)
            // ==========================================
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
              lastNotification:
                  'High compute load • 12 inference workers active',
              lastNotificationTime: 'Just now',
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
              statusColor: Color(0xFFE11D48),
            ),
            ServerModel(
              id: 'srv_008',
              title: 'PeerSpace & Gear Rentals',
              subtitle: 'PEER-TO-PEER ASSET RENTING',
              description:
                  'Verified equipment, studio workspace, tool libraries, and eco-vehicle rentals secured by decentralized escrow.',
              category: 'Rental & Gear',
              tags: ['Rental & Gear', 'Eco Tourism', 'Startup'],
              iconData: Icons.key_rounded,
              primaryColor: Color(0xFF0D9488),
              secondaryColor: Color(0xFFCCFBF1),
              memberCount: 530,
              bannerSvgOrType: 'gear_eco',
              isJoined: true,
              location: 'Pan-Regional Hubs & Local Lockers',
              servicePricing: 'Hourly & Daily Escrow',
              servicesOffered: [
                'Cinema & AV Gear Rental',
                'Co-Working Studio Booking',
                'Solar Power Tool Lending',
              ],
              lastNotification: 'Cinema camera kit returned & inspected',
              lastNotificationTime: '45m ago',
              statusColor: Color(0xFF0D9488),
            ),
            ServerModel(
              id: 'srv_009',
              title: 'EcoTransit Mobility & Rides',
              subtitle: 'ZERO-EMISSION RIDESHARE',
              description:
                  'Community-owned ride sharing, electric shuttle routes, and localized micro-transit with zero intermediary platform fees.',
              category: 'Mobility & Rides',
              tags: ['Mobility & Rides', 'Eco Tourism', 'Social Services'],
              iconData: Icons.electric_car_rounded,
              primaryColor: Color(0xFF0284C7),
              secondaryColor: Color(0xFFE0F2FE),
              memberCount: 1120,
              bannerSvgOrType: 'dev_forge',
              isJoined: true,
              location: 'Atitlan & Guatemala City Corridor',
              servicePricing: 'Per-Km Tokenized Fare',
              servicesOffered: [
                'On-Demand EV Rides',
                'Daily Intercity Carpool',
                'Eco-Cargo Delivery',
              ],
              lastNotification: '14 electric shuttles active in lake loop',
              lastNotificationTime: '10m ago',
              statusColor: Color(0xFF0284C7),
            ),
            ServerModel(
              id: 'srv_010',
              title: 'Artisan Goods & Organic Market',
              subtitle: 'PRODUCER-DIRECT COMMERCE',
              description:
                  'Direct-to-consumer marketplace for single-origin shade coffee, handwoven indigenous textiles, and organic bio-goods.',
              category: 'Marketplace & Goods',
              tags: ['Marketplace & Goods', 'Social Services', 'Startup'],
              iconData: Icons.storefront_rounded,
              primaryColor: Color(0xFFD97706),
              secondaryColor: Color(0xFFFEF3C7),
              memberCount: 1680,
              bannerSvgOrType: 'tree_canopy',
              isJoined: true,
              location: 'Highlands & Lake Basin Cooperatives',
              servicePricing: 'Direct Producer Price',
              servicesOffered: [
                'Single-Origin Shade Coffee',
                'Handwoven Indigenous Textiles',
                'Organic Seedling Kits',
              ],
              lastNotification: 'Fresh harvest batch roasted and packaged',
              lastNotificationTime: '20m ago',
              statusColor: Color(0xFFD97706),
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
