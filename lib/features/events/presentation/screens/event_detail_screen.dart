import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/toast_service.dart';
import '../viewmodels/events_viewmodel.dart';

class EventDetailScreen extends StatelessWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final EventsViewModel viewModel = Get.find<EventsViewModel>();
    
    return Obx(() {
      final event = viewModel.events.firstWhereOrNull((e) => e.id == eventId);
      
      // If event is missing, we might have just deleted it. 
      // We pop the screen and show a loader while it's transitioning.
      if (event == null) {
        Future.microtask(() {
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        });
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
      final timeFormat = DateFormat('h:mm a');

      return Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              actions: [
                if (event.creatorId == SupabaseService().currentUserId)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white),
                          onPressed: () => _showDeleteConfirmation(context, viewModel, event.id),
                        ),
                      ),
                    ),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (event.lat != 0 && event.lng != 0)
                      Image.network(
                        'https://maps.googleapis.com/maps/api/staticmap?center=${event.lat},${event.lng}&zoom=15&size=600x400&markers=color:red%7C${event.lat},${event.lng}&key=${dotenv.env["GOOGLE_MAPS_API_KEY"]}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          child: const Icon(Icons.map, size: 50, color: Colors.grey),
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.event_available,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    // Gradient overlay for better text readability and transition
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.3),
                            Colors.transparent,
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'COMMUNITY EVENT',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      event.title,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(
                      context,
                      Icons.calendar_today_outlined,
                      dateFormat.format(event.eventDate),
                      timeFormat.format(event.eventDate),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      context,
                      Icons.location_on_outlined,
                      event.locationName,
                      'Tap to see on map',
                      onTap: () async {
                        if (event.lat != 0 && event.lng != 0) {
                          final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${event.lat},${event.lng}');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'About this event',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Organizer',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: event.creatorAvatarUrl.isNotEmpty
                              ? NetworkImage(event.creatorAvatarUrl)
                              : null,
                          child: event.creatorAvatarUrl.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.creatorName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Community Member',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${event.attendeeCount} people',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    event.eventDate.isBefore(DateTime.now()) ? 'attended' : 'are attending',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: ElevatedButton(
                  onPressed: event.eventDate.isBefore(DateTime.now())
                      ? null
                      : () {
                          viewModel.toggleRSVP(event.id, !event.isUserAttending);
                        },
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    event.eventDate.isBefore(DateTime.now())
                        ? 'Event Ended'
                        : (event.isUserAttending ? 'Attending' : 'RSVP Now'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  void _showDeleteConfirmation(BuildContext context, EventsViewModel viewModel, String eventId) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final error = await viewModel.deleteEvent(eventId);
              if (error == null) {
                if (context.mounted) {
                  ToastService.showSuccess(context, 'Event deleted successfully');
                }
                // The Obx in EventDetailScreen will handle the pop back to list
              } else {
                if (context.mounted) {
                  ToastService.showError(context, error);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
