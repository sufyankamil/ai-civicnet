
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'ai_match_badge.dart';

class HelperCard extends StatelessWidget {
  final Helper helper;
  final VoidCallback onTap;

  const HelperCard({
    super.key,
    required this.helper,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0, // Flat style
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: helper.user.avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: helper.user.avatarUrl,
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
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.verified, color: AppColors.secondaryLight, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            helper.user.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AiMatchBadge(score: helper.matchScore),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${helper.distance} • ${helper.user.rating} ★ (${AppLocalizations.of(context)!.helpsCount(helper.user.helpCount)})',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      children: helper.matchReasons.take(2).map((reason) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reason,
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
