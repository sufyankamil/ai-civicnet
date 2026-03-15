import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:civic_net/models/models.dart';

class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback? onTap;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.onTap,
  });

  Color _getCategoryColor(AnnouncementCategory category) {
    switch (category) {
      case AnnouncementCategory.warning:
        return Colors.red;
      case AnnouncementCategory.update:
        return Colors.blue;
      case AnnouncementCategory.event:
        return Colors.orange;
      case AnnouncementCategory.community:
        return Colors.green;
    }
  }

  IconData _getCategoryIcon(AnnouncementCategory category) {
    switch (category) {
      case AnnouncementCategory.warning:
        return Icons.warning_amber_rounded;
      case AnnouncementCategory.update:
        return Icons.info_outline_rounded;
      case AnnouncementCategory.event:
        return Icons.event_available_rounded;
      case AnnouncementCategory.community:
        return Icons.people_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categoryColor = _getCategoryColor(announcement.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: announcement.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 180,
                      color: Colors.grey.withValues(alpha: 0.1),
                      child: const Center(child: CircularProgressIndicator.adaptive()),
                    ),
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getCategoryIcon(announcement.category), 
                                     size: 14, color: categoryColor),
                                const SizedBox(width: 4),
                                Text(
                                  announcement.category.name.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: categoryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            timeago.format(announcement.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              announcement.title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (announcement.isVerified)
                            const Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(Icons.verified_rounded, 
                                         color: Colors.blue, size: 20),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        announcement.content,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            backgroundImage: (announcement.authorAvatarUrl != null && 
                                              announcement.authorAvatarUrl!.isNotEmpty)
                                ? NetworkImage(announcement.authorAvatarUrl!)
                                : null,
                            child: (announcement.authorAvatarUrl == null || 
                                    announcement.authorAvatarUrl!.isEmpty)
                                ? const Icon(Icons.person, size: 14, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            announcement.authorName ?? 'Community Leader',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Read More',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, 
                               size: 16, color: theme.primaryColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
