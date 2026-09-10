import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/chat_model.dart';
import '../../../theme/app_colors.dart';

class QrConnectModal extends StatelessWidget {
  final ChatModel chat;

  const QrConnectModal({
    super.key,
    required this.chat,
  });

  static Future<void> show(BuildContext context, ChatModel chat) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => QrConnectModal(chat: chat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 580),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top header bar with close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Connect via QR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // User / Channel Preview Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkBg.withValues(alpha: 0.6)
                        : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: chat.avatarColor.withValues(alpha: 0.2),
                        child: Text(
                          chat.avatarInitials ?? chat.userName.substring(0, 2),
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            color: chat.avatarColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              chat.userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              chat.userRole,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // QR Code Frame
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    size: const Size(170, 170),
                    painter: _QrCodePainter(
                      color: const Color(0xFF0F172A),
                      accentColor: AppColors.primary,
                      initials: chat.avatarInitials ?? chat.userName.substring(0, 2),
                      initialsColor: chat.avatarColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'Scan this code to instantly connect and start chatting in EME World.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  children: [
                    // Save QR Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.of(context).pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    'QR code saved to your device!',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.greenAccent,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(
                          'Save QR',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Copy Link / Share Button
                    OutlinedButton.icon(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Clipboard.setData(
                          ClipboardData(text: 'https://eme.world/connect/${chat.id}'),
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Invite link copied to clipboard!',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: Text(
                        'Copy Link',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        foregroundColor: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                        side: BorderSide(
                          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom QR matrix painter to generate crisp, standard-looking QR patterns with center badge
class _QrCodePainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final String initials;
  final Color initialsColor;

  _QrCodePainter({
    required this.color,
    required this.accentColor,
    required this.initials,
    required this.initialsColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const int modules = 21;
    final double moduleSize = size.width / modules;

    // Standard static QR matrix pattern representation (Version 1-like mockup)
    final pattern = [
      '11111110010101111111',
      '10000010101001000001',
      '10111010111101011101',
      '10111010001001011101',
      '10111010101011011101',
      '10000010110101000001',
      '11111110101011111111',
      '00000000111000000000',
      '11101101010110110111',
      '01010011000011001010',
      '10110100011000110101',
      '01001011110110101010',
      '11011100101001011011',
      '00000000110111000100',
      '11111110101001010111',
      '10000010111010100001',
      '10111010010101011101',
      '10111010101001011101',
      '10111010110110011101',
      '10000010011101000001',
      '11111110100111111111',
    ];

    for (int r = 0; r < pattern.length && r < modules; r++) {
      final row = pattern[r];
      for (int c = 0; c < row.length && c < modules; c++) {
        // Skip center region for logo
        if (r >= 8 && r <= 12 && c >= 8 && c <= 12) {
          continue;
        }
        if (row[c] == '1') {
          // Corner position markers get slightly rounded rects
          final isCornerMarker = (r < 7 && c < 7) || (r < 7 && c >= 14) || (r >= 14 && c < 7);
          final rect = Rect.fromLTWH(
            c * moduleSize,
            r * moduleSize,
            moduleSize * 0.92,
            moduleSize * 0.92,
          );
          if (isCornerMarker) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(moduleSize * 0.25)),
              paint,
            );
          } else {
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(moduleSize * 0.3)),
              paint,
            );
          }
        }
      }
    }

    // Draw center badge with initial / logo
    final centerRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: moduleSize * 5.2,
      height: moduleSize * 5.2,
    );

    // White badge background & shadow
    final badgeBgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, Radius.circular(moduleSize * 1.5)),
      badgeBgPaint,
    );

    // Border around center badge
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(centerRect, Radius.circular(moduleSize * 1.5)),
      borderPaint,
    );

    // Text painter for initials
    final textPainter = TextPainter(
      text: TextSpan(
        text: initials,
        style: GoogleFonts.plusJakartaSans(
          color: AppColors.primary,
          fontSize: moduleSize * 2.1,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerRect.center.dx - textPainter.width / 2,
        centerRect.center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
