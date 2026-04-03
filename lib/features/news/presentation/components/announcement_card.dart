import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:civic_net/models/models.dart';
import 'package:civic_net/services/supabase_service.dart';
import 'package:civic_net/services/toast_service.dart';
import '../screens/announcement_detail_screen.dart';
import '../../../../theme/app_theme.dart';
import '../../../../components/animated_glow_border.dart';
import '../../../../widgets/haptic_buttons.dart';

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
    final glassColor = isDark ? AppColors.glassSurfaceDark : AppColors.glassSurfaceLight;

    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: glassColor,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnnouncementDetailScreen(announcement: announcement),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty)
                      Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: announcement.imageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: 200,
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                              child: const Center(child: CircularProgressIndicator.adaptive()),
                            ),
                            errorWidget: (context, url, error) => const SizedBox.shrink(),
                          ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.4),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: categoryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: categoryColor.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(_getCategoryIcon(announcement.category), 
                                         size: 14, color: categoryColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      announcement.category.name.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: categoryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                timeago.format(announcement.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  announcement.title,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    height: 1.2,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (announcement.isVerified)
                                Container(
                                  margin: const EdgeInsets.only(left: 8, top: 4),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.verified_rounded, 
                                             color: Colors.blue, size: 16),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            announcement.content,
                            style: TextStyle(
                              fontSize: 15,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              height: 1.6,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (announcement.sourceUrl != null && announcement.sourceUrl!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            AppHaptic(
                              onTap: () => _launchURL(announcement.sourceUrl!),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.link_rounded, size: 16, color: theme.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(context)!.sourceInformation,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Container(
                            height: 1,
                            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  gradient: AppColors.auraGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: (announcement.authorAvatarUrl != null && 
                                                    announcement.authorAvatarUrl!.isNotEmpty)
                                      ? CachedNetworkImageProvider(announcement.authorAvatarUrl!)
                                      : null,
                                  child: (announcement.authorAvatarUrl == null || 
                                          announcement.authorAvatarUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 16, color: Colors.grey)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      announcement.authorName ?? 'Community Leader',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Official Source',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!.readMore,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded, 
                                       size: 18, color: theme.primaryColor),
                                ],
                              ),
                            ],
                          ),
                          _buildAdminActions(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (announcement.isVerified) {
      return AnimatedGlowBorder(
        borderRadius: 24,
        child: cardContent,
      );
    }
    return cardContent;
  }

  void _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildAdminActions(BuildContext context) {
    return FutureBuilder<User?>(
      future: SupabaseService().getCurrentUserProfile(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        if (currentUser == null) return const SizedBox.shrink();

        final isSuperAdmin = currentUser.role == 'super_admin';
        final isAdminAuthor = currentUser.role == 'admin' && announcement.authorId == currentUser.id;

        if (!isSuperAdmin && !isAdminAuthor) return const SizedBox.shrink();

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  isSuperAdmin ? AppLocalizations.of(context)!.superAdminActions : AppLocalizations.of(context)!.adminActions,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                if (isSuperAdmin)
                  AppHaptic(
                    onTap: () => _handleVerify(context, !announcement.isVerified),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (announcement.isVerified ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            announcement.isVerified ? Icons.unpublished_rounded : Icons.verified_rounded,
                            size: 16,
                            color: announcement.isVerified ? Colors.orange : Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            announcement.isVerified ? AppLocalizations.of(context)!.unverify : AppLocalizations.of(context)!.verify,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: announcement.isVerified ? Colors.orange : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                AppHaptic(
                  onTap: () => _handleDelete(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                        const SizedBox(width: 6),
                        Text(
                          AppLocalizations.of(context)!.delete,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAnnouncementTitle),
        content: Text(AppLocalizations.of(context)!.deleteAnnouncementContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService().deleteAnnouncement(announcement.id);
        if (context.mounted) {
          ToastService.showSuccess(context, AppLocalizations.of(context)!.announcementDeleted);
        }
      } catch (e) {
        if (context.mounted) {
          ToastService.showError(context, AppLocalizations.of(context)!.actionFailed(e.toString()));
        }
      }
    }
  }

  Future<void> _handleVerify(BuildContext context, bool verify) async {
    try {
      await SupabaseService().verifyAnnouncement(announcement.id, verify);
      if (context.mounted) {
        ToastService.showSuccess(context, verify ? AppLocalizations.of(context)!.announcementVerified : AppLocalizations.of(context)!.verificationRemoved);
      }
    } catch (e) {
      if (context.mounted) {
        ToastService.showError(context, AppLocalizations.of(context)!.actionFailed(e.toString()));
      }
    }
  }
}
