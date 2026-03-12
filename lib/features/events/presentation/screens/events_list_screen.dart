import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../components/event_card.dart';
import '../viewmodels/events_viewmodel.dart';
import '../../../../services/supabase_service.dart';

class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final EventsViewModel viewModel = Get.find<EventsViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Community Noticeboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Local events and updates',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                     onPressed: () => context.push('/activity'),
                     icon: const Icon(Icons.notifications_none_rounded, color: Colors.grey),
                   ),
                   FutureBuilder(
                     future: SupabaseService().getCurrentUserProfile(),
                     builder: (context, snapshot) {
                       final user = snapshot.data;
                       final hasAvatar = user?.avatarUrl != null && user!.avatarUrl.isNotEmpty;
                       
                       return InkWell(
                         onTap: () => context.push('/profile'), 
                         borderRadius: BorderRadius.circular(20),
                         child: Padding(
                           padding: const EdgeInsets.all(4.0),
                           child: CircleAvatar(
                             radius: 20,
                             backgroundColor: Colors.grey,
                             backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl) : null,
                             child: hasAvatar ? null : const Icon(Icons.person, color: Colors.white),
                           ),
                         ),
                       );
                     }
                   ),
                ],
              ),
            ),

            // Events List
            Expanded(
              child: RefreshIndicator(
                onRefresh: viewModel.fetchEvents,
                child: Obx(() {
                  if (viewModel.isLoading && viewModel.events.isEmpty) {
                    return const Center(child: CircularProgressIndicator.adaptive());
                  }

                  if (viewModel.events.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_note_rounded, size: 80, color: Colors.grey[300]),
                              const SizedBox(height: 20),
                              Text(
                                'No Events Yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Be the first to organize a local gathering!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                onPressed: () => context.push('/create-event'),
                                icon: const Icon(Icons.add),
                                label: const Text('Post an Event'),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: viewModel.events.length,
                    itemBuilder: (context, index) {
                      final event = viewModel.events[index];
                      return EventCard(
                        event: event,
                        onTap: () {
                          context.push('/event/${event.id}');
                        },
                        onRSVP: () {
                          viewModel.toggleRSVP(event.id, !event.isUserAttending);
                        },
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
