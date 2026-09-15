import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/eme_profile_model.dart';

final List<String> kEmeProfileCategories = [
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

class EmeProfileState {
  final List<EmeProfileModel> profiles;
  final String selectedCategory;
  final String searchQuery;

  const EmeProfileState({
    required this.profiles,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  int get totalCount => profiles.length;

  List<EmeProfileModel> get filteredProfiles {
    return profiles.where((item) {
      // Category Filter
      final matchesCategory =
          selectedCategory == 'All' ||
          item.category == selectedCategory ||
          item.tags.contains(selectedCategory);

      if (!matchesCategory) return false;

      // Search Query Filter
      if (searchQuery.isEmpty) return true;

      final query = searchQuery.toLowerCase();
      final nameMatch = item.name.toLowerCase().contains(query);
      final subtitleMatch =
          item.subtitle?.toLowerCase().contains(query) ?? false;
      final specialistMatch =
          item.specialistTitle?.toLowerCase().contains(query) ?? false;
      final descMatch = item.description.toLowerCase().contains(query);
      final tagMatch = item.tags.any(
        (tag) => tag.toLowerCase().contains(query),
      );
      final serviceMatch = item.servicesOffered.any(
        (srv) => srv.toLowerCase().contains(query),
      );
      final locationMatch =
          item.location?.toLowerCase().contains(query) ?? false;

      return nameMatch ||
          subtitleMatch ||
          specialistMatch ||
          descMatch ||
          tagMatch ||
          serviceMatch ||
          locationMatch;
    }).toList();
  }

  EmeProfileState copyWith({
    List<EmeProfileModel>? profiles,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return EmeProfileState(
      profiles: profiles ?? this.profiles,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class EmeProfileNotifier extends StateNotifier<EmeProfileState> {
  EmeProfileNotifier()
    : super(
        const EmeProfileState(
          profiles: [
            EmeProfileModel(
              id: 'ind_001',
              name: 'Dr. Maya Lin',
              specialistTitle: 'Bio-credit & Hydrology Auditor',
              subtitle: 'SENIOR ECOLOGICAL SCIENTIST',
              description:
                  'Specializing in decentralized freshwater telemetry, watershed validation, and verifiable biodiversity impact certificates.',
              category: 'Eco Tourism',
              tags: ['Eco Tourism', 'Research', 'Social Services'],
              iconData: Icons.water_drop_rounded,
              avatarUrl: 'https://randomuser.me/api/portraits/women/44.jpg',
              primaryColor: Color(0xFF0284C7),
              secondaryColor: Color(0xFFF0F9FF),
              memberCount: 42,
              rating: 4.9,
              reviewsCount: 142,
              servicePricing: r'$60/hr • Grants',
              location: 'Panajachel, Guatemala',
              isVerified: true,
              servicesOffered: [
                'Water Quality Certification',
                'Bio-credit Verification',
                'Watershed GIS Analysis',
              ],
            ),
            EmeProfileModel(
              id: 'ind_002',
              name: 'Marcus Chen',
              specialistTitle: 'Autonomous AI Agent Architect',
              subtitle: 'EX-STANFORD AI LAB',
              description:
                  'Builds decentralized multi-agent workflows, model quantization pipelines, and privacy-preserving inference nodes.',
              category: 'Artificial Intelligence',
              tags: ['Artificial Intelligence', 'Software Tools'],
              iconData: Icons.psychology_rounded,
              avatarUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
              primaryColor: Color(0xFF8B5CF6),
              secondaryColor: Color(0xFFF5F3FF),
              memberCount: 89,
              rating: 5.0,
              reviewsCount: 89,
              servicePricing: r'$85/hr • Escrow',
              location: 'Singapore • Remote',
              isVerified: true,
              servicesOffered: [
                'Multi-Agent System Architecture',
                'Model Quantization (GGUF/AWQ)',
                'Agentic Tool Calling Integration',
              ],
            ),
            EmeProfileModel(
              id: 'ind_003',
              name: 'Sofia Alcantara',
              specialistTitle: 'Regenerative Finance & Tokenomics Advisor',
              subtitle: 'IMPACT PROTOCOL STRATEGIST',
              description:
                  'Advising communities on micro-credit token design, impact bonds, and decentralized treasury management.',
              category: 'Finance',
              tags: ['Finance', 'Startup', 'Social Services'],
              iconData: Icons.account_balance_wallet_rounded,
              avatarUrl: 'https://randomuser.me/api/portraits/women/65.jpg',
              primaryColor: Color(0xFF10B981),
              secondaryColor: Color(0xFFECFDF5),
              memberCount: 76,
              rating: 4.8,
              reviewsCount: 76,
              servicePricing: r'$50/hr • DAO',
              location: 'Berlin, Germany',
              isVerified: true,
              servicesOffered: [
                'DeFi & Impact Tokenomics Design',
                'Micro-lending Mesh Setup',
                'Treasury Multi-sig Governance',
              ],
            ),
            EmeProfileModel(
              id: 'ind_005',
              name: 'Elena Vance',
              specialistTitle: 'Smart Contract & Security Auditor',
              subtitle: 'ZK-SNARK & CONSENSUS AUDITOR',
              description:
                  'Formal verification and vulnerability audits for cross-chain bridges, token contracts, and zero-knowledge identity protocols.',
              category: 'Software Tools',
              tags: ['Software Tools', 'Finance'],
              iconData: Icons.security_rounded,
              avatarUrl: 'https://randomuser.me/api/portraits/women/33.jpg',
              primaryColor: Color(0xFF6366F1),
              secondaryColor: Color(0xFFEEF2FF),
              memberCount: 215,
              rating: 5.0,
              reviewsCount: 215,
              servicePricing: r'$95/hr',
              location: 'Zurich, Switzerland',
              isVerified: true,
              servicesOffered: [
                'Solidity & Rust Contract Audits',
                'ZK Circuit Security Verification',
                'Economic Attack Simulation',
              ],
            ),
            EmeProfileModel(
              id: 'ind_006',
              name: 'Prof. Kwame Mensah',
              specialistTitle: 'Decentralized Curriculum Architect',
              subtitle: 'GLOBAL OPEN PEDAGOGY',
              description:
                  'Designs peer-to-peer educational syllabi, verifiable credentialing schemas, and open-access STEM modules.',
              category: 'Education',
              tags: ['Education', 'Social Services', 'Research'],
              iconData: Icons.school_rounded,
              avatarUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
              primaryColor: Color(0xFFEC4899),
              secondaryColor: Color(0xFFFDF2F8),
              memberCount: 54,
              rating: 4.9,
              reviewsCount: 54,
              servicePricing: r'$40/hr • Pro Bono',
              location: 'Accra, Ghana',
              isVerified: true,
              servicesOffered: [
                'Verifiable Credential Schema Design',
                'Peer-to-Peer Learning Workflows',
                'Open Textbook Curriculum',
              ],
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

  void addProfile(EmeProfileModel profile) {
    state = state.copyWith(profiles: [profile, ...state.profiles]);
  }
}

final emeProfileProvider =
    StateNotifierProvider<EmeProfileNotifier, EmeProfileState>((ref) {
      return EmeProfileNotifier();
    });
