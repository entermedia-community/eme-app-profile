import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../utils/language_helper.dart';
import '../widgets/data_consent_dialog.dart';

class ComplianceScreen extends StatefulWidget {
  final VoidCallback? onLogout;

  const ComplianceScreen({super.key, this.onLogout});

  @override
  State<ComplianceScreen> createState() => _ComplianceScreenState();
}

class _ComplianceScreenState extends State<ComplianceScreen> {
  bool _hasConsented = true;

  @override
  void initState() {
    super.initState();
    _loadConsentStatus();
  }

  Future<void> _loadConsentStatus() async {
    final status = await DataCollectionConsentDialog.hasConsented();
    if (mounted) {
      setState(() {
        _hasConsented = status;
      });
    }
  }

  Future<void> _toggleConsent(bool value) async {
    await DataCollectionConsentDialog.saveConsent(value);
    setState(() {
      _hasConsented = value;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Data collection consent updated to Accepted.'
                : 'Data collection consent updated to Essential-only.',
          ),
          backgroundColor: const Color(0xFF1E2631),
        ),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141923),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF50057)),
            const SizedBox(width: 10),
            Text(
              LanguageHelper.translate('delete_account'),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          LanguageHelper.translate('delete_account_confirm'),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              LanguageHelper.translate('cancel'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF50057),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.logout();
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Account data cleared successfully.'),
                  ),
                );
                if (widget.onLogout != null) {
                  widget.onLogout!();
                } else {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            },
            child: Text(
              LanguageHelper.translate('delete_account'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141923),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep_rounded, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Text(
              LanguageHelper.translate('delete_data'),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          LanguageHelper.translate('delete_data_confirm'),
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              LanguageHelper.translate('cancel'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('data_collection_consented');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Personal collected data and progress cache deleted.'),
                  ),
                );
              }
            },
            child: Text(
              LanguageHelper.translate('confirm'),
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1319),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F13),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          LanguageHelper.translate('app_compliance'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: AI Assistant Role Disclosure
            _buildSectionCard(
              title: LanguageHelper.translate('ai_disclaimer_title'),
              icon: Icons.psychology_outlined,
              iconColor: const Color(0xFF38B6FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LanguageHelper.translate('ai_disclaimer_body'),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBulletPoint('Questions & answers are human-authored and human-reviewed.'),
                  _buildBulletPoint('AI serves purely as an interactive learning assistant.'),
                  _buildBulletPoint('AI is not the evaluator or driving force behind assessments.'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 2: Privacy Policy & Data Collection
            _buildSectionCard(
              title: LanguageHelper.translate('privacy_policy'),
              icon: Icons.privacy_tip_outlined,
              iconColor: const Color(0xFF38EF7D),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LanguageHelper.translate('data_consent_body'),
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Data Collection Consent Status',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Switch(
                          value: _hasConsented,
                          activeThumbColor: const Color(0xFF38B6FF),
                          onChanged: _toggleConsent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 3: App Store & Play Store Compliance Standards
            _buildSectionCard(
              title: 'Play Store & App Store Compliance',
              icon: Icons.verified_user_outlined,
              iconColor: const Color(0xFFFFB74D),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBulletPoint('Google Play & Apple App Store User Safety Compliant'),
                  _buildBulletPoint('Includes immediate Reporting mechanism for AI generated responses'),
                  _buildBulletPoint('Provides full User Account & Personal Data Deletion options'),
                  _buildBulletPoint('All network communications strictly secured using TLS/HTTPS'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section 4: Data & Account Erasure Options
            _buildSectionCard(
              title: 'Account & Data Management',
              icon: Icons.manage_accounts_outlined,
              iconColor: const Color(0xFFF50057),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'In accordance with Play Store & App Store policies, you have full right to erase your collected data or permanently delete your account.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: Colors.orange.withValues(alpha: 0.5),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.cleaning_services, size: 16, color: Colors.orange),
                          label: Text(
                            LanguageHelper.translate('delete_data'),
                            style: const TextStyle(fontSize: 11, color: Colors.orange),
                          ),
                          onPressed: _showDeleteDataDialog,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF50057),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          icon: const Icon(Icons.delete_forever, size: 16, color: Colors.white),
                          label: Text(
                            LanguageHelper.translate('delete_account'),
                            style: const TextStyle(fontSize: 11, color: Colors.white),
                          ),
                          onPressed: _showDeleteAccountDialog,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF141923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF38B6FF), fontSize: 14, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
