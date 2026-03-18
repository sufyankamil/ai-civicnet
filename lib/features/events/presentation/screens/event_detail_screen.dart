import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/toast_service.dart';
import '../viewmodels/events_viewmodel.dart';
import '../../models/event_comment.dart';
import '../../models/event.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

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
                            AppLocalizations.of(context)!.communityEvent,
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
                      style: TextStyle(
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
                      AppLocalizations.of(context)!.tapToSeeOnMap,
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
                      AppLocalizations.of(context)!.aboutThisEvent,
                      style: TextStyle(
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
                      AppLocalizations.of(context)!.organizer,
                      style: TextStyle(
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
                              AppLocalizations.of(context)!.communityMember,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    _buildCommentsSection(context, viewModel, event),
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
                    AppLocalizations.of(context)!.membersCount(event.attendeeCount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    event.eventDate.isBefore(DateTime.now())
                        ? AppLocalizations.of(context)!.peopleAttended
                        : AppLocalizations.of(context)!.peopleAttending,
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
                        ? AppLocalizations.of(context)!.eventEndedLabel
                        : (event.isUserAttending
                            ? AppLocalizations.of(context)!.attendingLabel
                            : AppLocalizations.of(context)!.rsvpNow),
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

  Widget _buildCommentsSection(BuildContext context, EventsViewModel viewModel, Event event) {
    // Fetch comments for the current event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchComments(event.id);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.comments,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Obx(() => Text(
              AppLocalizations.of(context)!.itemsCount(viewModel.comments.length),
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            )),
          ],
        ),
        const SizedBox(height: 20),

        // Comment Input
        if (event.isUserAttending)
          _buildCommentInput(context, viewModel, event.id)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: Colors.orange[300]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.onlyAttendingCanChat,
                    style: TextStyle(color: Colors.orange[700], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Comments List
        Obx(() {
          if (viewModel.isCommentsLoading && viewModel.comments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          }

          if (viewModel.comments.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.noCommentsBeFirst,
                      style: TextStyle(color: Colors.grey[400], fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.comments.length,
            padding: const EdgeInsets.only(top: 12),
            itemBuilder: (context, index) {
              final comment = viewModel.comments[index];
              return _buildCommentTile(context, viewModel, event, comment);
            },
          );
        }),
      ],
    );
  }

  Widget _buildCommentInput(BuildContext context, EventsViewModel viewModel, String eventId, {String? parentId, bool isReply = false}) {
    final TextEditingController controller = TextEditingController();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: isReply
                    ? AppLocalizations.of(context)!.writeReply
                    : AppLocalizations.of(context)!.askSomething,
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                fillColor: Colors.transparent,
                filled: true,
              ),
              style: const TextStyle(fontSize: 14),
              maxLines: null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).primaryColor,
              child: IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    viewModel.postComment(eventId, controller.text.trim(), parentId: parentId);
                    controller.clear();
                    if (isReply) Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(BuildContext context, EventsViewModel viewModel, Event event, EventComment comment, {bool isReply = false}) {
    final bool isHost = event.creatorId == SupabaseService().currentUserId;
    final bool isMyComment = comment.userId == SupabaseService().currentUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: isReply ? 12 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
                ),
                child: CircleAvatar(
                  radius: isReply ? 14 : 18,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: comment.userAvatarUrl.isNotEmpty
                      ? NetworkImage(comment.userAvatarUrl)
                      : null,
                  child: comment.userAvatarUrl.isEmpty ? Icon(Icons.person, size: isReply ? 16 : 20, color: Colors.grey[400]) : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          comment.userName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isReply ? 13 : 14,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (comment.userId == event.creatorId) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.host,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text(
                          _formatTimeAgo(context, comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: TextStyle(
                        fontSize: isReply ? 13 : 14,
                        height: 1.5,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (!isReply && isHost)
                          GestureDetector(
                            onTap: () => _showReplySheet(context, viewModel, event.id, comment),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 16, bottom: 4, top: 4),
                                child: Text(
                                  AppLocalizations.of(context)!.reply,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ),
                          ),
                        if (isMyComment)
                          GestureDetector(
                            onTap: () => viewModel.deleteComment(event.id, comment.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  AppLocalizations.of(context)!.delete,
                                  style: TextStyle(
                                    color: Colors.red[300],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (comment.replies.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 18),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey.withValues(alpha: 0.15), width: 1.5),
              ),
            ),
            padding: const EdgeInsets.only(left: 26),
            child: Column(
              children: comment.replies.map((reply) => _buildCommentTile(context, viewModel, event, reply, isReply: true)).toList(),
            ),
          ),
      ],
    );
  }

  void _showReplySheet(BuildContext context, EventsViewModel viewModel, String eventId, EventComment parentComment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.replyingTo,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Text(
                  parentComment.userName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCommentInput(context, viewModel, eventId, parentId: parentComment.id, isReply: true),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).languageCode;
    return timeago.format(date, locale: locale);
  }

  void _showDeleteConfirmation(BuildContext context, EventsViewModel viewModel, String eventId) {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: Text(AppLocalizations.of(context)!.deleteEvent),
        content: Text(AppLocalizations.of(context)!.deleteEventConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
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
                  ToastService.showSuccess(context, AppLocalizations.of(context)!.eventDeletedSuccess);
                }
                // The Obx in EventDetailScreen will handle the pop back to list
              } else {
                if (context.mounted) {
                  ToastService.showError(context, error);
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}
