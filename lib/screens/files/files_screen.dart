import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/file_item_model.dart';
import '../../theme/app_colors.dart';

class FilesScreen extends StatefulWidget {
  const FilesScreen({super.key});

  @override
  State<FilesScreen> createState() => _FilesScreenState();
}

class _FilesScreenState extends State<FilesScreen> {
  final List<FileItemModel> _files = const [
    FileItemModel(
      id: 'f_1',
      name: 'Atitlan_Ecosystem_Architecture.pdf',
      category: 'Documents',
      size: '4.8 MB',
      updatedAt: '2 hours ago',
      icon: Icons.picture_as_pdf_rounded,
      color: Color(0xFFEF4444),
    ),
    FileItemModel(
      id: 'f_2',
      name: 'Impact_Tokenomics_v2.xlsx',
      category: 'Spreadsheet',
      size: '1.2 MB',
      updatedAt: 'Yesterday',
      icon: Icons.table_chart_rounded,
      color: Color(0xFF10B981),
    ),
    FileItemModel(
      id: 'f_3',
      name: 'Circular_Bioeconomy_Blueprint.docx',
      category: 'Research',
      size: '8.4 MB',
      updatedAt: 'Sep 8, 2026',
      icon: Icons.description_rounded,
      color: Color(0xFF3B82F6),
    ),
    FileItemModel(
      id: 'f_4',
      name: 'Smart_Contract_Audit_Report.pdf',
      category: 'Audit',
      size: '2.1 MB',
      updatedAt: 'Sep 4, 2026',
      icon: Icons.verified_user_rounded,
      color: Color(0xFF8B5CF6),
    ),
    FileItemModel(
      id: 'f_5',
      name: 'Brand_Assets_Pack.zip',
      category: 'Design',
      size: '42.5 MB',
      updatedAt: 'Aug 28, 2026',
      icon: Icons.folder_zip_rounded,
      color: Color(0xFFF59E0B),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              Text(
                'EME Drive & Files',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.cloud_upload_outlined, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Storage overview card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E3A8A), const Color(0xFF1E293B)]
                    : [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
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
                    Text(
                      'Cloud Storage',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '14.2 GB / 50 GB',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: 0.284,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '28.4% used • Free tier storage',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Folders
          Text(
            'Quick Folders',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildFolderCard(
                context,
                title: 'Documents',
                itemsCount: '18 files',
                icon: Icons.folder_rounded,
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildFolderCard(
                context,
                title: 'Contracts',
                itemsCount: '6 files',
                icon: Icons.folder_special_rounded,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _buildFolderCard(
                context,
                title: 'Media',
                itemsCount: '34 files',
                icon: Icons.folder_copy_rounded,
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recent Files Header
          Text(
            'Recent Files',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Files list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _files.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final file = _files[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: file.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(file.icon, color: file.color, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${file.size} • ${file.updatedAt}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                      onPressed: () {},
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFolderCard(
    BuildContext context, {
    required String title,
    required String itemsCount,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              itemsCount,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
