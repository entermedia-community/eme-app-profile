import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/server_model.dart';
import '../../../theme/app_colors.dart';

class _ProductItem {
  final String title;
  final String category;
  final String description;
  final String price;
  final String tag;
  final IconData icon;

  const _ProductItem({
    required this.title,
    required this.category,
    required this.description,
    required this.price,
    required this.tag,
    required this.icon,
  });
}

class ServerProductsTab extends StatefulWidget {
  final ServerModel server;

  const ServerProductsTab({super.key, required this.server});

  @override
  State<ServerProductsTab> createState() => _ServerProductsTabState();
}

class _ServerProductsTabState extends State<ServerProductsTab> {
  String _selectedFilter = 'All';

  List<_ProductItem> _getProductsForServer() {
    // Generate specialized products tailored to the server's category & services
    final cat = widget.server.category.toLowerCase();

    if (cat.contains('finance') || widget.server.title.contains('Passport')) {
      return [
        const _ProductItem(
          title: 'Decentralized Biometric ID Pass',
          category: 'Identity',
          description:
              'Zero-knowledge encrypted global impact passport verifiable across cross-border nodes.',
          price: 'Free / DAO Grant',
          tag: 'Official Tier',
          icon: Icons.badge_outlined,
        ),
        const _ProductItem(
          title: 'Micro-Credit Liquidity Vault',
          category: 'Escrow',
          description:
              'Peer-to-peer micro-lending smart contract escrow with automated 0% humanitarian yield.',
          price: '0.25% Node Fee',
          tag: 'High Demand',
          icon: Icons.account_balance_wallet_outlined,
        ),
        const _ProductItem(
          title: 'Cross-Border FX Settlement Gateway',
          category: 'Payments',
          description:
              'Instant non-custodial fiat-to-crypto local settlement engine for remote communities.',
          price: '\$1.50 per batch',
          tag: 'Fast Sync',
          icon: Icons.currency_exchange_rounded,
        ),
      ];
    } else if (cat.contains('eco') || widget.server.title.contains('Atitlan')) {
      return [
        const _ProductItem(
          title: 'Regenerative Eco-Tourism Pass',
          category: 'Passes',
          description:
              'All-inclusive sustainable pass for lake Atitlan preserves, cultural nodes, and zero-carbon transport.',
          price: '\$45 / Week',
          tag: 'Most Popular',
          icon: Icons.forest_rounded,
        ),
        const _ProductItem(
          title: 'Lake Water Telemetry Sensor Node',
          category: 'Hardware',
          description:
              'Decentralized solar water purity sensor kit streaming real-time IoT bio-credit data.',
          price: '\$120 / Kit',
          tag: 'IoT Hardware',
          icon: Icons.sensors_rounded,
        ),
        const _ProductItem(
          title: 'Local Merchant Fair-Trade Token',
          category: 'Commerce',
          description:
              'Community-backed exchange credit accepted by over 80+ artisans and cooperatives.',
          price: '1:1 GTQ Backed',
          tag: 'Local Currency',
          icon: Icons.storefront_rounded,
        ),
      ];
    } else if (cat.contains('ai') || cat.contains('intelligence')) {
      return [
        const _ProductItem(
          title: 'High-Throughput Llama-3 70B Compute API',
          category: 'Compute',
          description:
              'Low-latency distributed inference mesh with cryptographic proof of compute execution.',
          price: '\$0.002 / 1k Tokens',
          tag: 'Ultra Fast',
          icon: Icons.memory_rounded,
        ),
        const _ProductItem(
          title: 'Autonomous Swarm Orchestration SDK',
          category: 'Agent Mesh',
          description:
              'Framework for coordinating multi-agent task execution and self-healing worker pools.',
          price: '\$29 / Node Mo',
          tag: 'Pro Developer',
          icon: Icons.hub_rounded,
        ),
        const _ProductItem(
          title: 'Decentralized Vector Embedding Store',
          category: 'Storage',
          description:
              'Privacy-preserving vector index distributed across verifiable IPFS and Arweave shards.',
          price: '\$5 / 1M Vectors',
          tag: 'DePIN Storage',
          icon: Icons.dataset_rounded,
        ),
      ];
    } else if (cat.contains('rental') || widget.server.title.contains('Rental') || widget.server.title.contains('PeerSpace')) {
      return [
        const _ProductItem(
          title: 'Sony FX3 Cinema Camera Kit',
          category: 'Equipment',
          description:
              'Full 4K cinema package with 24-70mm G-Master lens, wireless audio mics, and memory cards.',
          price: '\$65 / Day',
          tag: 'Verified Gear',
          icon: Icons.videocam_rounded,
        ),
        const _ProductItem(
          title: 'Co-Working Creative Studio Desk',
          category: 'Spaces',
          description:
              'Quiet acoustic studio pod with gigabit fiber, 4K monitors, and espresso bar access.',
          price: '\$18 / Day',
          tag: 'Smart Lock Access',
          icon: Icons.desk_rounded,
        ),
        const _ProductItem(
          title: 'Off-Grid Solar Power Generator (2000W)',
          category: 'Power & Tools',
          description:
              'Portable LiFePO4 battery station with foldable solar panels for field expeditions.',
          price: '\$35 / Day',
          tag: 'High Capacity',
          icon: Icons.solar_power_rounded,
        ),
      ];
    } else if (cat.contains('mobility') || cat.contains('ride') || widget.server.title.contains('Transit')) {
      return [
        const _ProductItem(
          title: 'On-Demand Lake Basin EV Ride',
          category: 'On-Demand',
          description:
              'Direct peer-to-peer zero-emission ride hailing with instant tokenized driver settlement.',
          price: '\$0.85 / km',
          tag: 'Instant Pickup',
          icon: Icons.electric_car_rounded,
        ),
        const _ProductItem(
          title: 'Daily Intercity Electric Shuttle Pass',
          category: 'Shuttle Pass',
          description:
              'Guaranteed commuter seat between Panajachel and Antigua with onboard WiFi.',
          price: '\$12 / Trip',
          tag: 'Scheduled Route',
          icon: Icons.airport_shuttle_rounded,
        ),
        const _ProductItem(
          title: 'Shared Eco-Cargo Van Haul',
          category: 'Cargo',
          description:
              'Luggage and agricultural product freight transport across municipal partner hubs.',
          price: '\$25 / Batch',
          tag: 'Heavy Freight',
          icon: Icons.local_shipping_rounded,
        ),
      ];
    } else if (cat.contains('market') || cat.contains('artisan') || widget.server.title.contains('Artisan')) {
      return [
        const _ProductItem(
          title: 'Single-Origin Volcanic Shade Coffee (1kg)',
          category: 'Organic Coffee',
          description:
              'Micro-lot specialty arabica harvested at 1600m altitude by local San Juan cooperativa.',
          price: '\$18.50',
          tag: 'Direct Trade',
          icon: Icons.coffee_rounded,
        ),
        const _ProductItem(
          title: 'Handwoven Natural-Dye Textile Throw',
          category: 'Artisan Textiles',
          description:
              'Backstrap-loom woven heirloom blanket dyed with bark and avocado pit pigments.',
          price: '\$75.00',
          tag: 'Authentic Craft',
          icon: Icons.style_rounded,
        ),
        const _ProductItem(
          title: 'Native Medicinal Herb & Tea Assortment',
          category: 'Herbal Goods',
          description:
              'Organic chamomile, pericon, and lemongrass harvest kit in biodegradable tins.',
          price: '\$14.00',
          tag: 'Organic Certified',
          icon: Icons.local_florist_rounded,
        ),
      ];
    } else {
      return [
        _ProductItem(
          title: '${widget.server.title} Core Service Node',
          category: 'Core Service',
          description:
              'Dedicated workspace infrastructure and collaboration tools for verified members.',
          price: widget.server.servicePricing ?? 'Free tier available',
          tag: 'Core Offering',
          icon: widget.server.iconData,
        ),
        const _ProductItem(
          title: 'Decentralized API Integration Suite',
          category: 'Developer API',
          description:
              'Direct gRPC & REST webhooks for integrating node services into third-party dApps.',
          price: '\$15 / Month',
          tag: 'Developer',
          icon: Icons.api_rounded,
        ),
        const _ProductItem(
          title: 'Community Governance Voting Bond',
          category: 'Governance',
          description:
              'Staked proposal rights and verified voting power on treasury allocations.',
          price: 'Stake 100 EME',
          tag: 'DAO Governance',
          icon: Icons.how_to_vote_rounded,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final products = _getProductsForServer();
    final categories = ['All', ...products.map((p) => p.category).toSet()];

    final filteredProducts = _selectedFilter == 'All'
        ? products
        : products.where((p) => p.category == _selectedFilter).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Products & Services',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Browse offerings provided by ${widget.server.title}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.server.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${filteredProducts.length} Items',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.server.primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = cat == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedFilter = cat);
                    },
                    labelStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
                    ),
                    backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    selectedColor: widget.server.primaryColor,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Product List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredProducts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = filteredProducts[index];
              return _buildProductCard(context, item, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, _ProductItem item, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.server.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, size: 24, color: widget.server.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.greenAccent.withValues(alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.greenAccent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            item.tag,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppColors.textDarkSecondary : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PRICING',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    item.price,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: widget.server.primaryColor,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected: ${item.title}'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.server.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: const Text('Acquire / Deploy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
