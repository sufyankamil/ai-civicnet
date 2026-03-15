
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:timeago/timeago.dart' as timeago;
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'ai_match_badge.dart';

class HelpRequestCard extends StatelessWidget {
  final HelpRequest request;

  const HelpRequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/request/${request.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  request.requesterAvatarUrl.isNotEmpty &&
                          (request.requesterAvatarUrl.startsWith('http://') || request.requesterAvatarUrl.startsWith('https://'))
                      ? CachedNetworkImage(
                          imageUrl: request.requesterAvatarUrl,
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: 20,
                            backgroundImage: imageProvider,
                          ),
                          errorWidget: (context, url, error) => const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                        )
                      : const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request.requesterName} • ${timeago.format(request.postedAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCategoryChip(context, request.category),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              if (request.requesterId == SupabaseService().currentUserId)
                Row(
                  children: [
                    Icon(Icons.map_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      request.locationName,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (request.distance.isNotEmpty && request.distance.toLowerCase() != 'unknown') ...[
                          Row(
                            children: [
                              Icon(Icons.location_on, size: 14, color: Theme.of(context).primaryColor),
                              const SizedBox(width: 4),
                              Text(
                                request.distance,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                              ),
                            ],
                          ),
                          if (request.locationName != 'Current Location') const SizedBox(height: 4),
                        ],
                        if (request.locationName != 'Current Location')
                          Row(
                            children: [
                              Icon(Icons.map_outlined, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                request.locationName,
                                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const Spacer(),
                    AiMatchBadge(score: request.aiRelevanceScore),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(BuildContext context, HelpCategory category) {
    Color color;
    String text;

    switch (category) {
      case HelpCategory.emergency:
        color = AppColors.accentLight;
        text = 'Emergency';
        break;
      case HelpCategory.techSupport:
        color = Colors.blue;
        text = 'Tech';
        break;
      case HelpCategory.education:
        color = Colors.purple;
        text = 'Education';
        break;
      case HelpCategory.household:
        color = Colors.orange;
        text = 'Household';
        break;
      default:
        color = Colors.grey;
        text = 'General';
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
        border: isDark ? Border.all(color: color.withValues(alpha: 0.3), width: 1) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? color.withValues(alpha: 0.9) : color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
