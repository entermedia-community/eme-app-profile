import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/server_model.dart';
import '../../../theme/app_colors.dart';

class _GoalItem {
  final String title;
  final String quarter;
  final String description;
  final double progress;
  final String status;
  final String bountyReward;
  final Color statusColor;

  const _GoalItem({
    required this.title,
    required this.quarter,
    required this.description,
    required this.progress,
    required this.status,
    required this.bountyReward,
    required this.statusColor,
  });
}

class ServerGoalsTab extends StatelessWidget {
  final ServerModel server;

  const ServerGoalsTab({super.key, required this.server});

  List<_GoalItem> _getGoalsForServer() {
    return [
      const _GoalItem(
        title: 'Launch Cross-Node Sync & P2P Data Bridge',
        quarter: 'Q3 2026',
        description:
            'Deploy low-latency gossip sub-network for syncing node states and shared ledger transactions.',
        progress: 0.85,
        status: 'In Progress',
        bountyReward: '1,200 EME',
        statusColor: Color(0xFF2563EB),
      ),
      const _GoalItem(
        title: 'Community Governance & Tokenized Voting',
        quarter: 'Q3 2026',
        description:
            'Implement quadratic voting mechanisms for node budget approvals and grant funding distribution.',
        progress: 1.0,
        status: 'Completed',
        bountyReward: '800 EME',
        statusColor: Color(0xFF16A34A),
      ),
      const _GoalItem(
        title: 'Decentralized Identity & Zero-Knowledge Verification',
        quarter: 'Q4 2026',
        description:
            'Integrate zk-SNARK verifiable credentials for instant privacy-preserving user attestation.',
        progress: 0.40,
        status: 'Bounty Active',
        bountyReward: '2,500 EME',
        statusColor: Color(0xFF7C3AED),
      ),
      const _GoalItem(
        title: 'Global Mobile Client Native Mesh Routing',
        quarter: 'Q1 2027',
        description:
            'Build background BLE & WebRTC ad-hoc mesh connectivity for offline emergency synchronizations.',
        progress: 0.15,
        status: 'Upcoming',
        bountyReward: '3,000 EME',
        statusColor: Color(0xFFEA580C),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goals = _getGoalsForServer();

    final completedCount = goals.where((g) => g.progress >= 1.0).length;
    final totalProgress = goals.fold<double>(0.0, (acc, g) => acc + g.progress) / goals.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEEF2FF), const Color(0xFFF8FAFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.3 : 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.track_changes_rounded,
                            color: Color(0xFF6366F1),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Node Roadmap & OKRs',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$completedCount/${goals.length} Done',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4F46E5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Milestone Completion',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      '${(totalProgress * 100).toInt()}%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: totalProgress,
                    minHeight: 8,
                    backgroundColor: isDark ? const Color(0xFF312E81) : const Color(0xFFE0E7FF),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Active Deliverables & Milestones',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Goals list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: goals.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final goal = goals[index];
              return _buildGoalCard(context, goal, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, _GoalItem goal, bool isDark) {
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
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  goal.quarter,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: goal.statusColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal.status,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: goal.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            goal.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            goal.description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark ? AppColors.textDarkSecondary : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Progress & Bounty
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.card_giftcard_rounded,
                    size: 14,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Bounty: ${goal.bountyReward}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              Text(
                '${(goal.progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(goal.statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
