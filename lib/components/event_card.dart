import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback onRSVP;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onRSVP,
  });

  bool _hasValidAvatar(String url) =>
      url.isNotEmpty &&
      (url.startsWith('http://') || url.startsWith('https://'));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = event.eventDate.isBefore(now);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.5 : 0.8,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? 0.1 : 0.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hasValidAvatar(event.creatorAvatarUrl)
                      ? CachedNetworkImage(
                          imageUrl: event.creatorAvatarUrl,
                          imageBuilder: (context, imageProvider) => Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              ),
                              border: Border.all(
                                color: AppColors.primaryLight.withValues(
                                  alpha: 0.2,
                                ),
                                width: 2,
                              ),
                            ),
                          ),
                          placeholder: (context, url) => const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey,
                          ),
                          errorWidget: (context, url, error) =>
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                        )
                      : const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey,
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.postedBy(event.creatorName),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.eventLabel,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Event Details Grid-like layout
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today_rounded,
                            size: 16,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DATE & TIME',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                _getLocalizedDate(context, event.eventDate),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LOCATION',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.grey[500],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                event.locationName,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.people_alt_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPast
                            ? AppLocalizations.of(
                                context,
                              )!.attendedCount(event.attendeeCount)
                            : AppLocalizations.of(
                                context,
                              )!.attendingCount(event.attendeeCount),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: isPast ? null : onRSVP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPast
                            ? Colors.grey.withValues(alpha: 0.1)
                            : (event.isUserAttending
                                  ? Colors.green
                                  : AppColors.primaryLight),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        isPast
                            ? AppLocalizations.of(context)!.ended
                            : (event.isUserAttending
                                  ? AppLocalizations.of(context)!.attending
                                  : AppLocalizations.of(context)!.rsvp),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLocalizedDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('MMM d, yyyy • h:mm a', locale).format(date);
  }
}
