import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/models.dart';
import '../../../theme/app_colors.dart';

typedef _TransactionItem = TransactionItemModel;

class ServerFinanceTab extends StatelessWidget {
  final ServerModel server;

  const ServerFinanceTab({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final transactions = [
      const _TransactionItem(
        id: 'tx_01',
        title: 'Community DAO Ecosystem Grant',
        date: 'Today, 2:15 PM',
        amount: '+ \$5,000.00',
        isCredit: true,
        category: 'Grant',
      ),
      const _TransactionItem(
        id: 'tx_02',
        title: 'Compute Cluster Hosting Node #04',
        date: 'Yesterday',
        amount: '- \$240.00',
        isCredit: false,
        category: 'Infrastructure',
      ),
      const _TransactionItem(
        id: 'tx_03',
        title: 'Biometric Verification Bounty Payout',
        date: 'Sep 12, 2026',
        amount: '- \$1,200.00',
        isCredit: false,
        category: 'Bounty',
      ),
      const _TransactionItem(
        id: 'tx_04',
        title: 'Cross-Border FX Micro-Settlement Fee Pool',
        date: 'Sep 10, 2026',
        amount: '+ \$890.50',
        isCredit: true,
        category: 'Revenue',
      ),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Treasury Card (Impact Bank)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF0C4A6E), const Color(0xFF0284C7)]
                    : [const Color(0xFF0369A1), const Color(0xFF0284C7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
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
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.account_balance_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'DAO Treasury & Escrow',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Audited',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Total Vault Balance',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$142,850.00',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Deposit to Vault initialized'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Deposit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0369A1),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Grant proposal form opened'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        icon: const Icon(Icons.send_rounded, size: 15, color: Colors.white),
                        label: const Text('Request Grant', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Financial Health Overview
          Text(
            'Node Economics',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Monthly Inflow',
                  '+\$18,400',
                  AppColors.greenAccent,
                  Icons.trending_up_rounded,
                  isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  'Staking APY',
                  '8.45%',
                  const Color(0xFF8B5CF6),
                  Icons.pie_chart_outline_rounded,
                  isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Recent Activity
          Text(
            'Recent Transactions & Escrow',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return _buildTransactionCard(tx, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                ),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(_TransactionItem tx, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (tx.isCredit ? AppColors.greenAccent : const Color(0xFFEF4444))
                  .withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              tx.isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: tx.isCredit ? AppColors.greenAccent : const Color(0xFFEF4444),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tx.category} • ${tx.date}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            tx.amount,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: tx.isCredit
                  ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534))
                  : (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }
}
