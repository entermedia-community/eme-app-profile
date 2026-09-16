import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/models.dart';
import '../../../theme/app_colors.dart';

typedef _BlogPost = BlogPostModel;

class ServerBlogTab extends StatelessWidget {
  final ServerModel server;

  const ServerBlogTab({super.key, required this.server});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final posts = [
      _BlogPost(
        id: 'post_01',
        title: 'Decentralized Collective Intelligence: State of the Node in 2026',
        author: 'Lead Architect',
        date: 'Sep 14, 2026',
        readTime: '4 min read',
        excerpt:
            'How ${server.title} is scaling distributed compute, local governance, and verifiable data pipelines across 12 countries.',
        tag: 'Architecture',
        likes: 128,
      ),
      _BlogPost(
        id: 'post_02',
        title: 'Community Roadmap Update: What to Expect in Q4',
        author: 'Ecosystem Core',
        date: 'Sep 08, 2026',
        readTime: '3 min read',
        excerpt:
            'A breakdown of the newly funded bounties, protocol upgrades, and upcoming integrations in the EME network.',
        tag: 'Announcements',
        likes: 94,
      ),
      _BlogPost(
        id: 'post_03',
        title: 'Zero-Knowledge Privacy and Humanitarian Impact Passports',
        author: 'Security Research Group',
        date: 'Aug 29, 2026',
        readTime: '6 min read',
        excerpt:
            'Ensuring identity self-sovereignty without sacrificing cryptographic proof-of-humanity.',
        tag: 'Research',
        likes: 215,
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
                    'Blog & Updates',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Announcements and publications from ${server.title}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.rss_feed_rounded),
                color: server.primaryColor,
                tooltip: 'Subscribe to RSS',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscribed to node feed updates'),
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
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(context, post, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, _BlogPost post, bool isDark) {
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
                  color: server.primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  post.tag,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: server.primaryColor,
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    post.readTime,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.excerpt,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: isDark ? AppColors.textDarkSecondary : const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${post.author} • ${post.date}',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textDarkMuted : AppColors.textMuted,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likes}',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
