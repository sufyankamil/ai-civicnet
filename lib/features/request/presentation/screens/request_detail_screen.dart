import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';

import '../../../../models/models.dart' as legacy;
import '../../domain/entities/help_request_entity.dart';
import '../../domain/entities/request_enums.dart';
import '../viewmodels/request_viewmodel.dart';
import '../../../../services/supabase_service.dart';
import '../../../../services/logger_service.dart';
import '../../../../theme/app_theme.dart';
import '../../../../components/app_loader.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../components/helper_card.dart';
import '../../../../components/primary_button.dart';
import '../../../../components/rating_dialog.dart';
import '../../../../services/toast_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../components/report_dialog.dart';
import '../../../../components/success_animation.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final RequestViewModel _viewModel = Get.find<RequestViewModel>();
  legacy.ApplicationStatus? _applicationStatus;
  bool _isCheckingStatus = true;
  bool _isApplying = false;
  List<legacy.RequestApplication> _applications = [];
  bool _isLoadingApplications = false;
  bool _hasFetchedApplications = false;
  bool _hasRated = false;
  int _ratingGiven = 0; // tracks the star value submitted

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _viewModel.fetchHelpRequest(widget.requestId);
    _checkApplicationStatus();
  }


  Future<void> _loadApplications(String requesterId) async {
    if (SupabaseService().currentUserId != requesterId) {
      return;
    }
    if (_isLoadingApplications) return;

    setState(() => _isLoadingApplications = true);
    try {
      final apps = await SupabaseService().getApplicationsForRequest(
        widget.requestId,
      );
      if (mounted) {
        setState(() {
          _applications = apps;
          _hasFetchedApplications = true;
        });
      }
    } catch (e) {
      logger.e('DEBUG: Error loading applications: $e');
    } finally {
      if (mounted) setState(() => _isLoadingApplications = false);
    }
  }

  Future<void> _checkApplicationStatus() async {
    if (SupabaseService().currentUserId == null) return;

    try {
      final status = await SupabaseService().getApplicationStatus(
        widget.requestId,
      );
      final rating = await SupabaseService().hasUserRated(widget.requestId);

      if (mounted) {
        setState(() {
          _applicationStatus = status;
          if (rating != null) {
            _hasRated = true;
            _ratingGiven = rating;
          } else {
            _hasRated = false;
            _ratingGiven = 0;
          }
          _isCheckingStatus = false;
        });
      }
    } catch (e) {
      logger.e('Error checking application status or fetching rating: $e');
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  Future<void> _startChatWithUser(String userId, String userName) async {
    if (_isStartingChat) return;
    setState(() => _isStartingChat = true);

    try {
      final conversationId = await SupabaseService().createConversation(userId);
      if (!mounted) return;

      final encodedName = Uri.encodeComponent(userName);
      context.push(
        '/chat-detail?id=$conversationId&name=$encodedName&uid=$userId',
      );
    } catch (e) {
      if (mounted) {
        logger.e('Error starting chat', error: e);
        ToastService.showError(
          context,
          'Unable to start chat. Please try again later.',
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (_viewModel.isLoading && _viewModel.currentRequest == null) {
          return const AppLoader();
        }

        final request = _viewModel.currentRequest;

        if (request == null) {
          return const Center(
            child: Text('Request not found or error loading'),
          );
        }

        if (SupabaseService().currentUserId == request.requesterId &&
            !_hasFetchedApplications &&
            !_isLoadingApplications) {
          Future.microtask(() => _loadApplications(request.requesterId));
        }

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              leading: Container(
                margin: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              actions: [
                if (SupabaseService().currentUserId != null &&
                    _viewModel.currentRequest != null &&
                    SupabaseService().currentUserId !=
                        _viewModel.currentRequest!.requesterId)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.flag_outlined, color: Colors.white),
                      onPressed: () => _showReportRequestDialog(),
                    ),
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.primaryDark,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 0.1,
                            child: Image.network(
                              'https://maps.googleapis.com/maps/api/staticmap?center=${request.lat},${request.lng}&zoom=12&size=600x400&style=feature:all|element:labels|visibility:off&key=${dotenv.env["GOOGLE_MAPS_API_KEY"]}',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: AppColors.primaryDark),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: AppColors.secondaryLight,
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.approximateLocation,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getLocalizedCategory(request.category.name),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondaryLight,
                            ),
                          ),
                        ),
                        if (request.distance.isNotEmpty &&
                            request.distance.toLowerCase() != 'unknown') ...[
                          const SizedBox(width: 8),
                          Text(
                            request.distance,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            request.title,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        if (SupabaseService().currentUserId ==
                            request.requesterId)
                          PopupMenuButton<RequestStatusEnum>(
                            initialValue: request.status,
                            onSelected: (status) =>
                                _updateHelpRequestStatus(status),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(
                                  request.status,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _statusColor(request.status),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    request.status
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase(),
                                    style: TextStyle(
                                      color: _statusColor(request.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: _statusColor(request.status),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                            itemBuilder: (context) => RequestStatusEnum.values
                                .map(
                                  (s) => PopupMenuItem(
                                    value: s,
                                    child: Text(
                                      s
                                          .toString()
                                          .split('.')
                                          .last
                                          .toUpperCase(),
                                    ),
                                  ),
                                )
                                .toList(),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                request.status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _statusColor(request.status),
                              ),
                            ),
                            child: Text(
                              request.status
                                  .toString()
                                  .split('.')
                                  .last
                                  .toUpperCase(),
                              style: TextStyle(
                                color: _statusColor(request.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (request.status == RequestStatusEnum.completed &&
                        request.helperId == SupabaseService().currentUserId)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.orange,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Task Completed!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  Text(
                                    'You earned 15 points for helping out.',
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          child: Hero(
                            tag: 'avatar-${request.id}',
                            child: request.requesterAvatarUrl.isNotEmpty &&
                                    (request.requesterAvatarUrl.startsWith('http://') || request.requesterAvatarUrl.startsWith('https://'))
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
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.requesterName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              AppLocalizations.of(context)!.requester,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        if (SupabaseService().currentUserId !=
                            request.requesterId)
                          IconButton(
                            icon: _isStartingChat
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator.adaptive(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.chat_bubble_outline,
                                    color: AppColors.primaryLight,
                                  ),
                            onPressed: () => _startChat(request),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    Text(
                      AppLocalizations.of(context)!.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.secondaryLight,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.communityHelpers,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                            if (_viewModel.potentialHelpers.length > 3)
                              TextButton(
                                onPressed: () => _showAllHelpersBottomSheet(
                                  context,
                                  _viewModel.potentialHelpers,
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(AppLocalizations.of(context)!.viewAll),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.nearbyMembersHelp,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_viewModel.isLoadingHelpers)
                          const AppLoader()
                        else if (_viewModel.potentialHelpers.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.people_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.of(context)!.noHelpersYet,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context)!.beTheFirstHelper,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: _viewModel.potentialHelpers
                                .take(3)
                                .map(
                                  (helper) => HelperCard(
                                    helper: helper,
                                    onTap: () {
                                      context.push(
                                        '/profile/${helper.user.id}',
                                      );
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (SupabaseService().currentUserId !=
                        request.requesterId) ...[
                      if (_applicationStatus != null)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _applicationStatus ==
                                      legacy.ApplicationStatus.accepted
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : _applicationStatus ==
                                        legacy.ApplicationStatus.rejected
                                  ? Colors.grey.withValues(alpha: 0.12)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color:
                                    _applicationStatus ==
                                        legacy.ApplicationStatus.accepted
                                    ? Colors.green
                                    : _applicationStatus ==
                                          legacy.ApplicationStatus.rejected
                                    ? Colors.grey
                                    : Colors.orange,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _applicationStatus ==
                                              legacy.ApplicationStatus.accepted
                                          ? Icons.check_circle
                                          : _applicationStatus ==
                                                legacy
                                                    .ApplicationStatus
                                                    .rejected
                                          ? Icons.sentiment_neutral_outlined
                                          : Icons.access_time_filled,
                                      color:
                                          _applicationStatus ==
                                              legacy.ApplicationStatus.accepted
                                          ? Colors.green
                                          : _applicationStatus ==
                                                legacy
                                                    .ApplicationStatus
                                                    .rejected
                                          ? Colors.grey
                                          : Colors.orange,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getLocalizedApplicationStatus(_applicationStatus!.name),
                                      style: TextStyle(
                                        color:
                                            _applicationStatus ==
                                                legacy
                                                    .ApplicationStatus
                                                    .accepted
                                            ? Colors.green[800]
                                            : _applicationStatus ==
                                                  legacy
                                                      .ApplicationStatus
                                                      .rejected
                                            ? Colors.grey[700]
                                            : Colors.orange[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                if (_applicationStatus ==
                                    legacy.ApplicationStatus.accepted) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!.communicateWithRequester,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () => _startChat(request),
                                    icon: const Icon(Icons.chat),
                                    label: Text(AppLocalizations.of(context)!.chatWithRequester),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ] else if (_applicationStatus ==
                                    legacy.ApplicationStatus.rejected) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'The requester has chosen someone else.\nKeep looking — there are more requests!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      else
                        Opacity(
                          opacity: request.status != RequestStatusEnum.open
                              ? 0.5
                              : 1.0,
                          child: PrimaryButton(
                            text: AppLocalizations.of(context)!.imInterested,
                            isLoading: _isApplying || _isCheckingStatus,
                            onPressed: request.status == RequestStatusEnum.open
                                ? () => _applyToRequest()
                                : () => ToastService.showInfo(
                                    context,
                                    AppLocalizations.of(context)!.requestNoLongerOpen,
                                  ),
                          ),
                        ),
                    ] else ...[
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.yourRequest,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    if (SupabaseService().currentUserId ==
                        request.requesterId) ...[
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Applications (${_applications.length})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingApplications)
                        const AppLoader()
                      else if (_applications.isEmpty)
                        Text(
                          AppLocalizations.of(context)!.interestShown,
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      else
                        ..._applications.map(
                          (app) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.grey,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.applicantName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          app.status ==
                                                  legacy
                                                      .ApplicationStatus
                                                      .accepted
                                              ? 'Accepted'
                                              : app.status ==
                                                    legacy
                                                        .ApplicationStatus
                                                        .rejected
                                              ? 'Not Selected'
                                              : 'Awaiting Review',
                                          style: TextStyle(
                                            color:
                                                app.status ==
                                                    legacy
                                                        .ApplicationStatus
                                                        .accepted
                                                ? Colors.green
                                                : app.status ==
                                                      legacy
                                                          .ApplicationStatus
                                                          .rejected
                                                ? Colors.grey
                                                : Colors.orange,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (app.status ==
                                      legacy.ApplicationStatus.accepted)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                        color: AppColors.primaryLight,
                                      ),
                                      onPressed: () => _startChatWithUser(
                                        app.applicantId,
                                        app.applicantName,
                                      ),
                                    ),

                                  if (app.status ==
                                      legacy.ApplicationStatus.pending) ...[
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => _updateStatus(
                                        app.id,
                                        legacy.ApplicationStatus.accepted,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _updateStatus(
                                        app.id,
                                        legacy.ApplicationStatus.rejected,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
      bottomNavigationBar: Obx(() {
        final request = _viewModel.currentRequest;
        if (request == null) return const SizedBox.shrink();

        final currentUserId = SupabaseService().currentUserId;
        final isOwner = request.requesterId == currentUserId;
        final isHelper = request.helperId == currentUserId;

        if (request.status == RequestStatusEnum.completed) {
          if (_hasRated) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: Colors.amber.withValues(alpha: 0.08),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You rated',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Show filled/empty stars based on submitted rating
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < _ratingGiven ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($_ratingGiven/5)',
                      style: TextStyle(
                        color: Colors.amber[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (isOwner || isHelper) {
            return SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _showRatingDialog,
                  icon: const Icon(Icons.star),
                  label: const Text('Rate User'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink();
      }),
    );
  }

  bool _isStartingChat = false;

  Future<void> _startChat(HelpRequestEntity request) async {
    if (_isStartingChat) return;
    if (SupabaseService().currentUserId == request.requesterId) {
      ToastService.showInfo(context, 'You cannot chat with yourself');
      return;
    }

    setState(() => _isStartingChat = true);
    try {
      final conversationId = await SupabaseService().createConversation(
        request.requesterId,
      );
      if (mounted) {
        final encodedName = Uri.encodeComponent(request.requesterName);
        context.push(
          '/chat-detail?id=$conversationId&name=$encodedName&uid=${request.requesterId}',
        );
      }
    } catch (e) {
      if (mounted) {
        logger.e('Error starting chat', error: e);
        ToastService.showError(context, 'Unable to start chat with this user.');
      }
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  Future<void> _applyToRequest() async {
    setState(() => _isApplying = true);
    try {
      await SupabaseService().applyToRequest(widget.requestId);
      if (mounted) {
        setState(() => _applicationStatus = legacy.ApplicationStatus.pending);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SuccessAnimation(size: 120),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Interest Sent!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Waiting for requester to accept. You\'ll be notified once they respond.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Got it',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        logger.e('Error applying to request', error: e);
        ToastService.showError(
          context,
          'Failed to apply. Please try again later.',
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _updateStatus(
    String appId,
    legacy.ApplicationStatus status,
  ) async {
    try {
      await SupabaseService().updateApplicationStatus(appId, status);
      await _viewModel.fetchHelpRequest(widget.requestId);

      final request = _viewModel.currentRequest;
      if (request != null) {
        await _loadApplications(request.requesterId);
      }
      if (mounted) {
        ToastService.showSuccess(context, 'Application ${status.name}!');
      }
    } catch (e) {
      if (mounted) {
        logger.e('Error updating status', error: e);
        ToastService.showError(
          context,
          'Failed to update status. Please check your connection.',
        );
      }
    }
  }

  Future<void> _updateHelpRequestStatus(RequestStatusEnum status) async {
    if (status == RequestStatusEnum.completed) {
      _showCompletionDialog();
      return;
    }

    final error = await _viewModel.updateRequestStatus(
      widget.requestId,
      status,
    );
    if (mounted) {
      if (error == null) {
        ToastService.showSuccess(
          context,
          'Request status updated to ${status.toString().split('.').last}!',
        );
        _viewModel.fetchHelpRequest(widget.requestId);
      } else {
        ToastService.showError(context, error);
      }
    }
  }

  void _showCompletionDialog() async {
    final applications = await SupabaseService().getApplicationsForRequest(
      widget.requestId,
    );

    if (!mounted) return;

    if (applications.isEmpty) {
      ToastService.showInfo(
        context,
        'No applicants to mark as helper. Wait for someone to apply.',
      );
      return;
    }

    // NOTE: showAdaptiveDialog / AlertDialog.adaptive cannot be used here because
    // CupertinoAlertDialog does not support unconstrained list content (causes layout crash).
    // We use a plain AlertDialog with a TextButton cancel for iOS compat.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select the user who helped you.'),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final app = applications[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(app.applicantName),
                      subtitle: Text(
                        'Applied ${timeago.format(app.createdAt)}',
                      ),
                      onTap: () => _confirmCompletion(app),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCompletion(legacy.RequestApplication app) async {
    Navigator.pop(context);

    bool confirm =
        await showAdaptiveDialog(
          context: context,
          builder: (context) => AlertDialog.adaptive(
            title: const Text('Confirm Completion'),
            content: Text(
              'Are you sure you want to mark this task as completed by ${app.applicantName}?',
            ),
            actions: [
              if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ] else ...[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      await SupabaseService().completeHelpRequest(
        widget.requestId.trim(),
        app.applicantId.trim(),
      );
      await _viewModel.fetchHelpRequest(widget.requestId);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SuccessAnimation(size: 120),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Task Completed!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Points have been awarded to both of you. Thank you for making our community better!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: 'Amazing',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        logger.e('Error updating request status', error: e);
        ToastService.showError(context, 'Action failed. Please try again.');
      }
    }
  }

  void _showRatingDialog() async {
    final request = _viewModel.currentRequest;
    if (request == null) return;

    final currentUserId = SupabaseService().currentUserId;
    final isOwner = request.requesterId == currentUserId;

    String ratedUserId;
    String ratedUserName;
    String ratedUserAvatar;

    if (isOwner) {
      if (request.helperId == null) return;
      ratedUserId = request.helperId!;
      final profile = await SupabaseService().getUserProfile(ratedUserId);
      ratedUserName = profile?.name ?? 'Helper';
      ratedUserAvatar = profile?.avatarUrl ?? '';
    } else {
      ratedUserId = request.requesterId;
      ratedUserName = request.requesterName;
      ratedUserAvatar = request.requesterAvatarUrl;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        ratedUserName: ratedUserName,
        ratedUserAvatar: ratedUserAvatar,
        onRate: (rating) async {
          try {
            await SupabaseService().rateUser(
              requestId: widget.requestId,
              ratedUserId: ratedUserId,
              rating: rating,
            );

            if (!context.mounted) return;
            setState(() {
              _hasRated = true;
              _ratingGiven = rating;
            });
            ToastService.showSuccess(context, 'Rating submitted!');
          } catch (e) {
            if (!context.mounted) return;
            logger.e('Error submitting rating', error: e);
            ToastService.showError(
              context,
              'Failed to submit rating. Please try again later.',
            );
          }
        },
      ),
    );
  }

  Color _statusColor(RequestStatusEnum status) {
    switch (status) {
      case RequestStatusEnum.open:
        return Colors.green;
      case RequestStatusEnum.inProgress:
        return Colors.blue;
      case RequestStatusEnum.completed:
        return Colors.purple;
      case RequestStatusEnum.closed:
        return Colors.grey;
    }
  }

  void _showAllHelpersBottomSheet(
    BuildContext context,
    List<legacy.Helper> helpers,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.secondaryLight,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Community Helpers',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: helpers.length,
                  itemBuilder: (context, index) {
                    final helper = helpers[index];
                    return HelperCard(
                      helper: helper,
                      onTap: () {
                        Navigator.pop(context); // close bottom sheet
                        context.push('/profile/${helper.user.id}');
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReportRequestDialog() {
    final request = _viewModel.currentRequest;
    if (request == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => ReportDialog(
        title: 'Report Request',
        onReport: (reason) async {
          try {
            await SupabaseService().reportUser(request.requesterId, 'Request "${request.title}": $reason');
            if (!mounted) return;
            
            // ignore: use_build_context_synchronously
            ToastService.showSuccess(context, 'User reported and blocked. Thank you for helping keep the community safe.');
            
            // Wait a brief moment for toast to start showing, then close
            await Future.delayed(const Duration(milliseconds: 300));
            if (!mounted) return;
            
            // ignore: use_build_context_synchronously
            Navigator.of(dialogContext).pop(); // Close dialog
            // ignore: use_build_context_synchronously
            context.pop(); // Go back from details
          } catch (e) {
            if (!mounted) return;
            // ignore: use_build_context_synchronously
            ToastService.showError(context, 'Failed to submit report. Please try again.');
          }
        },
      ),
    );
  }

  String _getLocalizedCategory(String category) {
    final l10n = AppLocalizations.of(context)!;
    switch (category.toLowerCase()) {
      case 'emergency': return l10n.categoryEmergency;
      case 'tech support': return l10n.categoryTechSupport;
      case 'household': return l10n.categoryHousehold;
      case 'education': return l10n.categoryEducation;
      case 'general': return l10n.categoryGeneral;
      default: return category;
    }
  }

  String _getLocalizedApplicationStatus(String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status.toLowerCase()) {
      case 'accepted': return l10n.applicationAccepted;
      case 'not selected': return l10n.notSelected;
      case 'applied': return l10n.interestSent;
      default: return status;
    }
  }
}
