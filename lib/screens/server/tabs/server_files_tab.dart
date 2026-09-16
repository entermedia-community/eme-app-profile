import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eme_app_sdk/eme_app_sdk.dart';
import '../../../theme/app_colors.dart';

class _FileItem {
  final String name;
  final String size;
  final String date;
  final IconData icon;
  final Color iconColor;

  const _FileItem({
    required this.name,
    required this.size,
    required this.date,
    required this.icon,
    required this.iconColor,
  });
}

class ServerFilesTab extends StatelessWidget {
  final ServerModel server;

  const ServerFilesTab({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final files = [
      const _FileItem(
        name: 'Node_Governance_Charter_v2.pdf',
        size: '2.4 MB',
        date: 'Sep 11, 2026',
        icon: Icons.picture_as_pdf_rounded,
        iconColor: Color(0xFFEF4444),
      ),
      const _FileItem(
        name: 'Decentralized_API_Spec_v3.json',
        size: '148 KB',
        date: 'Sep 09, 2026',
        icon: Icons.code_rounded,
        iconColor: Color(0xFF0284C7),
      ),
      const _FileItem(
        name: 'Treasury_Audit_Report_Q2.xlsx',
        size: '1.8 MB',
        date: 'Aug 30, 2026',
        icon: Icons.table_chart_rounded,
        iconColor: Color(0xFF16A34A),
      ),
      const _FileItem(
        name: 'Architecture_Telemetry_Diagram.png',
        size: '3.1 MB',
        date: 'Aug 24, 2026',
        icon: Icons.image_outlined,
        iconColor: Color(0xFF8B5CF6),
      ),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Node Drive & Assets',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Shared documents, specs, and resources',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.upload_file_rounded),
                color: server.primaryColor,
                tooltip: 'Upload to Server',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upload dialogue ready'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: files.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final file = files[index];
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
                        color: file.iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(file.icon, color: file.iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${file.size} • ${file.date}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, size: 18),
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Downloading ${file.name}...'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
