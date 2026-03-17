import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/models.dart';
import '../../../../components/event_card.dart';
import '../viewmodels/events_viewmodel.dart';

class EventsListScreen extends StatelessWidget {
  const EventsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final EventsViewModel viewModel = Get.find<EventsViewModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                            l10n.eventsTitle,
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
                            l10n.localEventsUpdates,
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
                  ],
                ),
              ),
    
              // Tab Bar
              TabBar(
                tabs: [
                  Tab(text: l10n.upcoming),
                  Tab(text: l10n.past),
                ],
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
              ),
    
              // Events List
              Expanded(
                child: TabBarView(
                  children: [
                    _buildEventsList(context, viewModel, viewModel.upcomingEvents, l10n, true),
                    _buildEventsList(context, viewModel, viewModel.pastEvents, l10n, false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, EventsViewModel viewModel, List<Event> events, AppLocalizations l10n, bool upcoming) {
    return RefreshIndicator(
      onRefresh: viewModel.fetchEvents,
      child: Obx(() {
        final currentEvents = upcoming ? viewModel.upcomingEvents : viewModel.pastEvents;

        if (viewModel.isLoading && currentEvents.isEmpty) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        if (currentEvents.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      upcoming ? Icons.event_note_rounded : Icons.history_rounded, 
                      size: 80, 
                      color: Colors.grey[300]
                    ),
                    const SizedBox(height: 20),
                    Text(
                      upcoming ? l10n.noUpcomingEvents : l10n.noPastEvents,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (upcoming)
                      Text(
                        l10n.firstToOrganize,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (upcoming)
                      FilledButton.icon(
                        onPressed: () => context.push('/create-event'),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.postAnEvent),
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
          padding: const EdgeInsets.all(16),
          itemCount: currentEvents.length,
          itemBuilder: (context, index) {
            final event = currentEvents[index];
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
    );
  }
}
