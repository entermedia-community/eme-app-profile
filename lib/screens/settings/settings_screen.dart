import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dedicated app settings screen, opened from the profile app bar menu.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        children: [
          Semantics(
            identifier: 'settings_push_notifications_tile',
            child: ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: const Text('Push Notifications'),
              trailing: Semantics(
                identifier: 'settings_push_notifications_switch',
                child: Switch(value: true, onChanged: (v) {}),
              ),
            ),
          ),
          Semantics(
            identifier: 'settings_privacy_security_tile',
            child: ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text('Privacy & Security'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
          Semantics(
            identifier: 'settings_language_tile',
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language (English)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
