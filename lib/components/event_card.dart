import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../features/events/models/event.dart';
import '../theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final LocalEvent event;
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
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _hasValidAvatar(event.creatorAvatarUrl)
                      ? CachedNetworkImage(
                          imageUrl: event.creatorAvatarUrl,
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: 18,
                            backgroundImage: imageProvider,
                          ),
                          errorWidget: (context, url, error) => const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                        )
                      : const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white, size: 20),
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hosted by ${event.creatorName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'EVENT',
                      style: TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.primaryLight),
                  const SizedBox(width: 6),
                  Text(
                    dateFormat.format(event.eventDate),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      event.locationName,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        '${event.attendeeCount} attending',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: event.eventDate.isBefore(DateTime.now()) ? null : onRSVP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: event.eventDate.isBefore(DateTime.now())
                            ? Colors.grey.withValues(alpha: 0.1)
                            : (event.isUserAttending 
                                ? Colors.green.withValues(alpha: 0.1)
                                : Theme.of(context).primaryColor),
                        foregroundColor: event.eventDate.isBefore(DateTime.now())
                            ? Colors.grey 
                            : (event.isUserAttending 
                                ? Colors.green 
                                : Colors.white),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        event.eventDate.isBefore(DateTime.now()) 
                            ? 'Ended' 
                            : (event.isUserAttending ? 'Attending' : 'RSVP'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
}
