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
  final String selectedType; // 'All', 'Servers', 'Specialists'
  final String searchQuery;

  const ServerState({
    required this.servers,
    this.selectedCategory = 'All',
    this.selectedType = 'All',
    this.searchQuery = '',
  });

  /// Servers that the user has already joined (for the Profile page)
  List<ServerModel> get joinedServers {
    return servers.where((s) => s.isJoined && s.providerType == ProviderType.server).toList();
  }

  int get joinedCount => joinedServers.length;

  int get serverCount => servers.where((s) => s.providerType == ProviderType.server).length;

  int get individualCount => servers.where((s) => s.providerType == ProviderType.individual).length;

  /// Individuals / Specialists filtered for EME World
  List<ServerModel> get filteredIndividuals {
    return servers.where((item) {
      if (item.providerType != ProviderType.individual) return false;

      // Category Filter
      final matchesCategory = selectedCategory == 'All' ||
          item.category == selectedCategory ||
          item.tags.contains(selectedCategory);

      if (!matchesCategory) return false;

      // Search Query Filter
      if (searchQuery.isEmpty) return true;

      final query = searchQuery.toLowerCase();
      final titleMatch = item.title.toLowerCase().contains(query);
      final subtitleMatch = item.subtitle?.toLowerCase().contains(query) ?? false;
      final specialistMatch = item.specialistTitle?.toLowerCase().contains(query) ?? false;
      final descMatch = item.description.toLowerCase().contains(query);
      final tagMatch = item.tags.any((tag) => tag.toLowerCase().contains(query));
      final serviceMatch = item.servicesOffered.any((srv) => srv.toLowerCase().contains(query));
      final locationMatch = item.location?.toLowerCase().contains(query) ?? false;

      return titleMatch ||
          subtitleMatch ||
          specialistMatch ||
          descMatch ||
          tagMatch ||
          serviceMatch ||
          locationMatch;
    }).toList();
  }

  /// Servers filtered for Server Picker & Catalog
  List<ServerModel> get filteredServers {
    return servers.where((item) {
      if (item.providerType != ProviderType.server) return false;

      // Category Filter
      final matchesCategory = selectedCategory == 'All' ||
          item.category == selectedCategory ||
          item.tags.contains(selectedCategory);

      if (!matchesCategory) return false;

      // Search Query Filter
      if (searchQuery.isEmpty) return true;

      final query = searchQuery.toLowerCase();
      final titleMatch = item.title.toLowerCase().contains(query);
      final subtitleMatch = item.subtitle?.toLowerCase().contains(query) ?? false;
      final descMatch = item.description.toLowerCase().contains(query);
      final tagMatch = item.tags.any((tag) => tag.toLowerCase().contains(query));
      final serviceMatch = item.servicesOffered.any((srv) => srv.toLowerCase().contains(query));
      final locationMatch = item.location?.toLowerCase().contains(query) ?? false;

      return titleMatch ||
          subtitleMatch ||
          descMatch ||
          tagMatch ||
          serviceMatch ||
          locationMatch;
    }).toList();
  }

  /// Global catalog filtered for EME World Marketplace
  List<ServerModel> get filteredCatalog {
    return servers.where((item) {
      // Type Filter
      if (selectedType == 'Servers' && item.providerType != ProviderType.server) {
        return false;
      }
      if ((selectedType == 'Specialists' || selectedType == 'Individuals') &&
          item.providerType != ProviderType.individual) {
        return false;
      }

      // Category Filter
      final matchesCategory = selectedCategory == 'All' ||
          item.category == selectedCategory ||
          item.tags.contains(selectedCategory);

      if (!matchesCategory) return false;

      // Search Query Filter
      if (searchQuery.isEmpty) return true;

      final query = searchQuery.toLowerCase();
      final titleMatch = item.title.toLowerCase().contains(query);
      final subtitleMatch = item.subtitle?.toLowerCase().contains(query) ?? false;
      final specialistMatch = item.specialistTitle?.toLowerCase().contains(query) ?? false;
      final descMatch = item.description.toLowerCase().contains(query);
      final tagMatch = item.tags.any((tag) => tag.toLowerCase().contains(query));
      final serviceMatch = item.servicesOffered.any((srv) => srv.toLowerCase().contains(query));
      final locationMatch = item.location?.toLowerCase().contains(query) ?? false;

      return titleMatch ||
          subtitleMatch ||
          specialistMatch ||
          descMatch ||
          tagMatch ||
          serviceMatch ||
          locationMatch;
    }).toList();
  }

  ServerState copyWith({
    List<ServerModel>? servers,
    String? selectedCategory,
    String? selectedType,
    String? searchQuery,
  }) {
    return ServerState(
      servers: servers ?? this.servers,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedType: selectedType ?? this.selectedType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ServerNotifier extends StateNotifier<ServerState> {
  ServerNotifier()
      : super(
          ServerState(
            servers: [
              // ==========================================
              // SERVERS (Joined by default for Profile)
              // ==========================================
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
                providerType: ProviderType.server,
                isJoined: true, // Joined server for Profile page
                location: 'Lake Atitlan, Guatemala',
                servicePricing: 'Free / DAO Fee',
                servicesOffered: [
                  'Currency Exchange',
                  'Local Merchant Settlement',
                  'Eco Tourism Passports'
                ],
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
                providerType: ProviderType.server,
                isJoined: true, // Joined server for Profile page
                location: 'Global / Decentralized',
                servicePricing: '0% Humanitarian Fee',
                servicesOffered: [
                  'Biometric ID Issuance',
                  'Cross-border Verification',
                  'Micro-credit Escrow'
                ],
              ),

              // ==========================================
              // SERVERS (Discoverable in EME World)
              // ==========================================
              const ServerModel(
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
                providerType: ProviderType.server,
                isJoined: false,
                location: 'Rural India Nodes',
                servicePricing: 'Community Grants',
                servicesOffered: [
                  'Agricultural IoT telemetry',
                  'Circular Waste Loops',
                  'Bio-economy Governance'
                ],
              ),
              const ServerModel(
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
                providerType: ProviderType.server,
                isJoined: false,
                location: 'Global DePIN',
                servicePricing: 'Pay-per-token / Staking',
                servicesOffered: [
                  'Distributed Model Inference',
                  'Agent Swarm Hosting',
                  'Dataset Verification'
                ],
              ),
              const ServerModel(
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
                providerType: ProviderType.server,
                isJoined: false,
                location: 'Costa Rica & Amazonia',
                servicePricing: 'Bio-credits & Bookings',
                servicesOffered: [
                  'Eco-stay Booking',
                  'Regenerative Credits',
                  'Flora & Fauna Tracking'
                ],
              ),
              const ServerModel(
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
                providerType: ProviderType.server,
                isJoined: false,
                location: 'Global Open Source',
                servicePricing: '100% Free & Open Source',
                servicesOffered: [
                  'Smart Contract Templates',
                  'CI/CD Web3 Oracles',
                  'Decentralized Storage APIs'
                ],
              ),
              const ServerModel(
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
                providerType: ProviderType.server,
                isJoined: false,
                location: 'Geneva / Remote',
                servicePricing: 'Tiered Medical Escrow',
                servicesOffered: [
                  'Zero-Knowledge Health Records',
                  'Remote Triage Consultations',
                  'Drug Efficacy Registry'
                ],
              ),

              // ==========================================
              // INDIVIDUAL SERVICE PROVIDERS & SPECIALISTS
              // ==========================================
              const ServerModel(
                id: 'ind_001',
                title: 'Dr. Maya Lin',
                specialistTitle: 'Bio-credit & Hydrology Auditor',
                subtitle: 'SENIOR ECOLOGICAL SCIENTIST',
                description:
                    'Specializing in decentralized freshwater telemetry, watershed validation, and verifiable biodiversity impact certificates.',
                category: 'Eco Tourism',
                tags: ['Eco Tourism', 'Research', 'Social Services'],
                iconData: Icons.water_drop_rounded,
                primaryColor: Color(0xFF0284C7),
                secondaryColor: Color(0xFFF0F9FF),
                memberCount: 42,
                providerType: ProviderType.individual,
                rating: 4.9,
                reviewsCount: 142,
                servicePricing: '\$60/hr • Grants',
                location: 'Panajachel, Guatemala',
                isVerified: true,
                servicesOffered: [
                  'Water Quality Certification',
                  'Bio-credit Verification',
                  'Watershed GIS Analysis'
                ],
              ),
              const ServerModel(
                id: 'ind_002',
                title: 'Marcus Chen',
                specialistTitle: 'Autonomous AI Agent Architect',
                subtitle: 'EX-STANFORD AI LAB',
                description:
                    'Builds decentralized multi-agent workflows, model quantization pipelines, and privacy-preserving inference nodes.',
                category: 'Artificial Intelligence',
                tags: ['Artificial Intelligence', 'Software Tools'],
                iconData: Icons.psychology_rounded,
                primaryColor: Color(0xFF8B5CF6),
                secondaryColor: Color(0xFFF5F3FF),
                memberCount: 89,
                providerType: ProviderType.individual,
                rating: 5.0,
                reviewsCount: 89,
                servicePricing: '\$85/hr • Escrow',
                location: 'Singapore • Remote',
                isVerified: true,
                servicesOffered: [
                  'Multi-Agent System Architecture',
                  'Model Quantization (GGUF/AWQ)',
                  'Agentic Tool Calling Integration'
                ],
              ),
              const ServerModel(
                id: 'ind_003',
                title: 'Sofia Alcantara',
                specialistTitle: 'Regenerative Finance & Tokenomics Advisor',
                subtitle: 'IMPACT PROTOCOL STRATEGIST',
                description:
                    'Advising communities on micro-credit token design, impact bonds, and decentralized treasury management.',
                category: 'Finance',
                tags: ['Finance', 'Startup', 'Social Services'],
                iconData: Icons.account_balance_wallet_rounded,
                primaryColor: Color(0xFF10B981),
                secondaryColor: Color(0xFFECFDF5),
                memberCount: 76,
                providerType: ProviderType.individual,
                rating: 4.8,
                reviewsCount: 76,
                servicePricing: '\$50/hr • DAO',
                location: 'Berlin, Germany',
                isVerified: true,
                servicesOffered: [
                  'DeFi & Impact Tokenomics Design',
                  'Micro-lending Mesh Setup',
                  'Treasury Multi-sig Governance'
                ],
              ),
              const ServerModel(
                id: 'ind_004',
                title: 'Arjun Patel',
                specialistTitle: 'Rural IoT & Telemetry Engineer',
                subtitle: 'HARDWARE & EDGE COMPUTE',
                description:
                    'Deploying solar-powered LoRaWAN mesh nodes, soil sensor arrays, and low-bandwidth community networks in remote villages.',
                category: 'Social Services',
                tags: ['Social Services', 'Research', 'Software Tools'],
                iconData: Icons.sensors_rounded,
                primaryColor: Color(0xFFD97706),
                secondaryColor: Color(0xFFFFFBEB),
                memberCount: 110,
                providerType: ProviderType.individual,
                rating: 4.9,
                reviewsCount: 110,
                servicePricing: 'Community Grants / Free',
                location: 'Bangalore, India',
                isVerified: true,
                servicesOffered: [
                  'LoRaWAN Gateway Deployment',
                  'Soil & Weather Telemetry Setup',
                  'Offline Edge Compute Firmware'
                ],
              ),
              const ServerModel(
                id: 'ind_005',
                title: 'Elena Vance',
                specialistTitle: 'Smart Contract & Security Auditor',
                subtitle: 'ZK-SNARK & CONSENSUS AUDITOR',
                description:
                    'Formal verification and vulnerability audits for cross-chain bridges, token contracts, and zero-knowledge identity protocols.',
                category: 'Software Tools',
                tags: ['Software Tools', 'Finance'],
                iconData: Icons.security_rounded,
                primaryColor: Color(0xFF6366F1),
                secondaryColor: Color(0xFFEEF2FF),
                memberCount: 215,
                providerType: ProviderType.individual,
                rating: 5.0,
                reviewsCount: 215,
                servicePricing: '\$95/hr',
                location: 'Zurich, Switzerland',
                isVerified: true,
                servicesOffered: [
                  'Solidity & Rust Contract Audits',
                  'ZK Circuit Security Verification',
                  'Economic Attack Simulation'
                ],
              ),
              const ServerModel(
                id: 'ind_006',
                title: 'Prof. Kwame Mensah',
                specialistTitle: 'Decentralized Curriculum Architect',
                subtitle: 'GLOBAL OPEN PEDAGOGY',
                description:
                    'Designs peer-to-peer educational syllabi, verifiable credentialing schemas, and open-access STEM modules.',
                category: 'Education',
                tags: ['Education', 'Social Services', 'Research'],
                iconData: Icons.school_rounded,
                primaryColor: Color(0xFFEC4899),
                secondaryColor: Color(0xFFFDF2F8),
                memberCount: 54,
                providerType: ProviderType.individual,
                rating: 4.9,
                reviewsCount: 54,
                servicePricing: '\$40/hr • Pro Bono',
                location: 'Accra, Ghana',
                isVerified: true,
                servicesOffered: [
                  'Verifiable Credential Schema Design',
                  'Peer-to-Peer Learning Workflows',
                  'Open Textbook Curriculum'
                ],
              ),
            ],
          ),
        );

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setTypeFilter(String type) {
    state = state.copyWith(selectedType: type);
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

