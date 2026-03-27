import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../l10n/app_localizations.dart';
import '../features/request/domain/entities/help_request_entity.dart';
import '../features/request/domain/entities/request_enums.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';
import 'ai_match_badge.dart';

class RequestCard extends StatelessWidget {
  final HelpRequestEntity request;

  const RequestCard({super.key, required this.request});

  bool _hasValidAvatar(String url) =>
      url.isNotEmpty &&
      (url.startsWith('http://') || url.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
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
                  Hero(
                    tag: 'avatar-${request.id}',
                    child: _hasValidAvatar(request.requesterAvatarUrl)
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
                          '${request.requesterName} • ${timeago.format(request.postedAt, locale: locale)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
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
                    Icon(Icons.map_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                       request.locationName,
                       style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                                Icon(Icons.location_on_outlined, size: 14, color: Theme.of(context).primaryColor),
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
                                Icon(Icons.map_outlined, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  request.locationName,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String text;

    switch (category) {
      case HelpCategory.emergency:
        color = AppColors.accentLight;
        text = l10n.categoryEmergency;
        break;
      case HelpCategory.techSupport:
        color = Colors.blue;
        text = l10n.categoryTechSupport;
        break;
      case HelpCategory.education:
        color = Colors.purple;
        text = l10n.categoryEducation;
        break;
      case HelpCategory.household:
        color = Colors.orange;
        text = l10n.categoryHousehold;
        break;
      default:
        color = Colors.grey;
        text = l10n.categoryGeneral;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
