import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../l10n/app_localizations.dart';
import '../features/request/domain/entities/help_request_entity.dart';
import '../features/request/domain/entities/request_enums.dart';
import '../theme/app_theme.dart';
import 'ai_match_badge.dart';
import 'animated_glow_border.dart';

class RequestCard extends StatelessWidget {
  final HelpRequestEntity request;

  const RequestCard({super.key, required this.request});

  bool _hasValidAvatar(String url) =>
      url.isNotEmpty &&
      (url.startsWith('http://') || url.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isAiMatch = request.aiRelevanceScore > 0;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardBody = Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: () => context.push('/request/${request.id}'),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: 'avatar-${request.id}',
                        child: Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                            gradient: isAiMatch ? AppColors.auraGradient : null,
                            color: isAiMatch ? null : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: _hasValidAvatar(request.requesterAvatarUrl)
                              ? CachedNetworkImage(
                                  imageUrl: request.requesterAvatarUrl,
                                  imageBuilder: (context, imageProvider) => CircleAvatar(
                                    radius: 18,
                                    backgroundImage: imageProvider,
                                  ),
                                  errorWidget: (context, url, error) => CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.grey[200],
                                    child: const Icon(Icons.person, color: Colors.white, size: 18),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey[200],
                                  child: const Icon(Icons.person, color: Colors.white, size: 18),
                                ),
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
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${request.requesterName} • ${timeago.format(request.postedAt, locale: locale)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[500],
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
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (request.distance.isNotEmpty && request.distance.toLowerCase() != 'unknown')
                              Row(
                                children: [
                                  Icon(Icons.near_me_rounded, size: 12, color: Theme.of(context).primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    request.distance,
                                    style: TextStyle(
                                      fontSize: 11, 
                                      fontWeight: FontWeight.w800, 
                                      color: Theme.of(context).primaryColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            if (request.locationName != 'Current Location') ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                                  const SizedBox(width: 4),
                                  Text(
                                    request.locationName,
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isAiMatch) AiMatchBadge(score: request.aiRelevanceScore),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: isAiMatch
          ? AnimatedGlowBorder(
              isActive: true,
              child: cardBody,
            )
          : cardBody,
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
