import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:civic_net/models/models.dart';
import 'package:civic_net/services/supabase_service.dart';
import 'package:civic_net/services/toast_service.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Announcement announcement;

  const AnnouncementDetailScreen({
    super.key,
    required this.announcement,
  });

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  late int _voteCount;
  late bool _isVotedByMe;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Use data passed from the list for immediate display
    _voteCount = widget.announcement.voteCount;
    _isVotedByMe = widget.announcement.isVotedByMe;
    
    // Refresh for absolute accuracy in the background
    _fetchLatestVoteStatus();
  }

  Future<void> _fetchLatestVoteStatus() async {
    try {
      final data = await SupabaseService().getAnnouncementVotesInfo(widget.announcement.id);
      if (mounted) {
        setState(() {
          _voteCount = data['count'];
          _isVotedByMe = data['user_voted'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching vote status: $e');
    }
  }

  Future<void> _toggleVote() async {
    if (_isLoading) return;
    
    final originalVoted = _isVotedByMe;
    final originalCount = _voteCount;

    setState(() {
      _isLoading = true;
      _isVotedByMe = !_isVotedByMe;
      _voteCount = _isVotedByMe ? _voteCount + 1 : _voteCount - 1;
    });

    try {
      await SupabaseService().toggleAnnouncementVote(widget.announcement.id, _isVotedByMe);
      if (mounted) {
        ToastService.showSuccess(
          context, 
          _isVotedByMe ? 'You upvoted this' : 'Upvote removed'
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVotedByMe = originalVoted;
          _voteCount = originalCount;
        });
        ToastService.showError(context, 'Failed to vote: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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

  Future<void> _launchURL(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(widget.announcement.category);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: widget.announcement.imageUrl != null && widget.announcement.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.announcement.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            categoryColor.withValues(alpha: 0.8),
                            categoryColor.withValues(alpha: 0.4),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(widget.announcement.category),
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getCategoryIcon(widget.announcement.category), 
                                 size: 14, color: categoryColor),
                            const SizedBox(width: 6),
                            Text(
                              widget.announcement.category.name.toUpperCase(),
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: categoryColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        timeago.format(widget.announcement.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.announcement.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (widget.announcement.isVerified)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, color: Colors.blue, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Trusted Information',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  Text(
                    widget.announcement.content,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (widget.announcement.sourceUrl != null && widget.announcement.sourceUrl!.isNotEmpty) ...[
                    Text(
                      'REFERENCE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => _launchURL(widget.announcement.sourceUrl!),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outline.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.link_rounded, size: 20, color: theme.primaryColor),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Source Information',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    widget.announcement.sourceUrl!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.primaryColor,
                                      decoration: TextDecoration.underline,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.open_in_new_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                  _buildAuthorAndVoteSection(context, theme),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthorAndVoteSection(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: widget.announcement.authorAvatarUrl != null && widget.announcement.authorAvatarUrl!.isNotEmpty
                    ? NetworkImage(widget.announcement.authorAvatarUrl!)
                    : null,
                child: widget.announcement.authorAvatarUrl == null || widget.announcement.authorAvatarUrl!.isEmpty
                    ? const Icon(Icons.person, size: 24)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'POSTED BY',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      widget.announcement.authorName ?? 'Community Leader',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HELPFUL?',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    '$_voteCount community members agreed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _VoteButton(
                isVoted: _isVotedByMe,
                onTap: _toggleVote,
                isLoading: _isLoading,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final bool isVoted;
  final VoidCallback onTap;
  final bool isLoading;

  const _VoteButton({
    required this.isVoted,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Material(
      color: isVoted ? primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isVoted ? primaryColor : theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              else
                Icon(
                  isVoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                  size: 18,
                  color: isVoted ? Colors.white : primaryColor,
                ),
              const SizedBox(width: 8),
              Text(
                'Agree',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isVoted ? Colors.white : primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
