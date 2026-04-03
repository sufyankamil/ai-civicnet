import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/toast_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
        extendBody: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 250,
                  pinned: true,
                  systemOverlayStyle: SystemUiOverlayStyle.light,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
                  leading: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: AppHaptic(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.2), // Premium glass subtle
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    if (event.creatorId == SupabaseService().currentUserId)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: AppHaptic(
                          onTap: () => _showDeleteConfirmation(context, viewModel, event.id),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 20),
                              ),
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
                              child: const Icon(Icons.map_rounded, size: 50, color: Colors.grey),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 1.5,
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.event_available_rounded,
                                size: 80,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        // Premium Gradient overlay for smooth transition to content
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.4),
                                Colors.transparent,
                                Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                                Theme.of(context).scaffoldBackgroundColor,
                              ],
                              stops: const [0.0, 0.4, 0.8, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0.8, -0.2),
                        radius: 2.0,
                        colors: [
                          AppColors.primaryLight.withValues(alpha: isDark ? 0.05 : 0.03),
                          Theme.of(context).scaffoldBackgroundColor,
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!.communityEvent.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 28),
                          _buildPremiumInfoRow(
                            context,
                            Icons.calendar_today_rounded,
                            dateFormat.format(event.eventDate),
                            timeFormat.format(event.eventDate),
                          ),
                          const SizedBox(height: 16),
                          _buildPremiumInfoRow(
                            context,
                            Icons.location_on_rounded,
                            event.locationName,
                            (event.lat != 0 && event.lng != 0) 
                                ? AppLocalizations.of(context)!.tapToSeeOnMap 
                                : '',
                            onTap: (event.lat != 0 && event.lng != 0) 
                              ? () async {
                                  final String url;
                                  if (Theme.of(context).platform == TargetPlatform.iOS) {
                                    url = 'http://maps.apple.com/?q=${event.lat},${event.lng}';
                                  } else {
                                    url = 'https://www.google.com/maps/search/?api=1&query=${event.lat},${event.lng}';
                                  }
                                  final uri = Uri.parse(url);
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri);
                                  }
                                }
                              : null,
                          ),
                          const SizedBox(height: 40),
                          Text(
                            AppLocalizations.of(context)!.aboutThisEvent,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            event.description,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Text(
                            AppLocalizations.of(context)!.organizer,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.4 : 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.05 : 0.1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3), width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                                    backgroundImage: event.creatorAvatarUrl.isNotEmpty
                                        ? NetworkImage(event.creatorAvatarUrl)
                                        : null,
                                    child: event.creatorAvatarUrl.isEmpty
                                        ? const Icon(Icons.person_rounded, size: 28, color: AppColors.primaryLight)
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        event.creatorName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        AppLocalizations.of(context)!.communityMember,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                          _buildCommentsSection(context, viewModel, event),
                          // Extra space to prevent bottom navigation bar overlap
                          const SizedBox(height: 140), 
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Premium Floating Action Bar Bottom Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8),
                      border: Border(
                        top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                      ),
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
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              event.eventDate.isBefore(DateTime.now())
                                  ? AppLocalizations.of(context)!.peopleAttended
                                  : AppLocalizations.of(context)!.peopleAttending,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: AppHaptic(
                            onTap: event.eventDate.isBefore(DateTime.now())
                                ? () {} // disabled
                                : () {
                                    viewModel.toggleRSVP(event.id, !event.isUserAttending);
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                color: event.eventDate.isBefore(DateTime.now())
                                    ? Colors.grey.withValues(alpha: 0.1)
                                    : (event.isUserAttending
                                        ? Colors.white.withValues(alpha: isDark ? 0.1 : 0.8)
                                        : AppColors.primaryLight),
                                borderRadius: BorderRadius.circular(20),
                                border: event.isUserAttending && !event.eventDate.isBefore(DateTime.now())
                                    ? Border.all(color: AppColors.primaryLight.withValues(alpha: 0.5))
                                    : null,
                                boxShadow: !event.isUserAttending && !event.eventDate.isBefore(DateTime.now())
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primaryLight.withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                event.eventDate.isBefore(DateTime.now())
                                    ? AppLocalizations.of(context)!.eventEndedLabel.toUpperCase()
                                    : (event.isUserAttending
                                        ? AppLocalizations.of(context)!.attendingLabel.toUpperCase()
                                        : AppLocalizations.of(context)!.rsvpNow.toUpperCase()),
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1.0,
                                  color: event.eventDate.isBefore(DateTime.now())
                                      ? Colors.grey[500]
                                      : (event.isUserAttending
                                          ? AppColors.primaryLight
                                          : Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPremiumInfoRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.4 : 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.05 : 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppColors.primaryLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        ],
      ),
    );

    if (onTap != null) {
      return AppHaptic(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }

  Widget _buildCommentsSection(BuildContext context, EventsViewModel viewModel, Event event) {
    // Fetch comments for the current event
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchComments(event.id);
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.comments,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context)!.itemsCount(viewModel.comments.length),
                style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.bold),
              ),
            )),
          ],
        ),
        const SizedBox(height: 24),

        // Comment Input
        if (event.isUserAttending)
          _buildCommentInput(context, viewModel, event.id)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.lock_outline_rounded, size: 20, color: Colors.orange[400]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.onlyAttendingCanChat,
                    style: TextStyle(color: Colors.orange[400], fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Comments List
        Obx(() {
          if (viewModel.isCommentsLoading && viewModel.comments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator.adaptive()),
            );
          }

          if (viewModel.comments.isEmpty) {
            if (!event.isUserAttending) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[300]),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.noCommentsBeFirst,
                      style: TextStyle(color: Colors.grey[400], fontSize: 15, fontWeight: FontWeight.w600),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: isDark ? 0.6 : 1.0),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
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
                hintStyle: TextStyle(fontSize: 15, color: Colors.grey[400], fontWeight: FontWeight.w500),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                fillColor: Colors.transparent,
                filled: true,
              ),
              style: const TextStyle(fontSize: 15),
              maxLines: null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: AppHaptic(
              onTap: () {
                if (controller.text.trim().isNotEmpty) {
                  viewModel.postComment(eventId, controller.text.trim(), parentId: parentId);
                  controller.clear();
                  if (isReply) Navigator.pop(context);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryLight.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(top: isReply ? 16 : 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1), width: 1),
            ),
            child: CircleAvatar(
              radius: isReply ? 16 : 22,
              backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
              backgroundImage: comment.userAvatarUrl.isNotEmpty
                  ? NetworkImage(comment.userAvatarUrl)
                  : null,
              child: comment.userAvatarUrl.isEmpty ? Icon(Icons.person_rounded, size: isReply ? 18 : 24, color: Colors.grey[400]) : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isReply ? 14 : 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (comment.userId == event.creatorId) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.host.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Text(
                      _formatTimeAgo(context, comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: isReply ? 14 : 15,
                    height: 1.6,
                    color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (!isReply && isHost)
                      AppHaptic(
                        onTap: () => _showReplySheet(context, viewModel, event.id, comment),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20, bottom: 4, top: 4),
                          child: Text(
                            AppLocalizations.of(context)!.reply,
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    if (isMyComment)
                      AppHaptic(
                        onTap: () => viewModel.deleteComment(event.id, comment.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            AppLocalizations.of(context)!.delete,
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (comment.replies.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8, left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Colors.grey.withValues(alpha: 0.1), width: 2),
                      ),
                    ),
                    padding: const EdgeInsets.only(left: 20, bottom: 16),
                    child: Column(
                      children: comment.replies.map((reply) => _buildCommentTile(context, viewModel, event, reply, isReply: true)).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReplySheet(BuildContext context, EventsViewModel viewModel, String eventId, EventComment parentComment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 30,
          left: 24,
          right: 24,
          top: 30,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.reply_rounded, size: 16, color: Colors.grey[400]),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.replyingTo,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500], fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 4),
                Text(
                  parentComment.userName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
        title: Text(AppLocalizations.of(context)!.deleteEvent, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(AppLocalizations.of(context)!.deleteEventConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(
                fontWeight: FontWeight.bold,
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
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
