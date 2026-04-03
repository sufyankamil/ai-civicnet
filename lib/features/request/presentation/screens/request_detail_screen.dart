import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../../widgets/haptic_buttons.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/help_request_entity.dart';
import '../../domain/entities/request_enums.dart';
import '../viewmodels/request_viewmodel.dart';
import 'package:get/get.dart';

import '../../../../models/models.dart' as legacy;
import '../../../../theme/app_theme.dart';
import '../../../../components/app_loader.dart';
import '../../../../services/logger_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../features/assets/presentation/viewmodels/assets_viewmodel.dart';
import '../../../../features/assets/widgets/asset_card.dart';
import '../../../../features/assets/models/asset.dart' as asset_models;
import '../../../../components/helper_card.dart';
import '../../../../components/primary_button.dart';
import '../../../../components/rating_dialog.dart';
import '../../../../services/toast_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../components/report_dialog.dart';
import '../../../../services/supabase_service.dart';
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
  List<asset_models.CommunityAsset> _matchedAssets = [];
  bool _isLoadingAssets = false;
  bool _isStartingChat = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _viewModel.fetchHelpRequest(widget.requestId);
    _checkApplicationStatus();
    
    // Fetch matching tools/assets using the new AssetsViewModel
    if (_viewModel.currentRequest != null) {
      if (mounted) setState(() => _isLoadingAssets = true);
      try {
        final assets = await Get.find<AssetsViewModel>().getMatchForRequest(_viewModel.currentRequest!);
        if (mounted) {
          setState(() {
            _matchedAssets = assets;
            _isLoadingAssets = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingAssets = false);
      }
    }
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

  Future<void> _startChatWithUser(String userId, String userName, {String? initialMessage}) async {
    if (_isStartingChat) return;
    setState(() => _isStartingChat = true);

    try {
      final conversationId = await SupabaseService().createConversation(userId);
      if (!mounted) return;

      final encodedName = Uri.encodeComponent(userName);
      String url = '/chat-detail?id=$conversationId&name=$encodedName&uid=$userId';
      
      if (initialMessage != null && initialMessage.isNotEmpty) {
        final encodedMsg = Uri.encodeComponent(initialMessage);
        url += '&msg=$encodedMsg';
      }

      context.push(url);
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
              expandedHeight: 220,
              pinned: true,
              stretch: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              leading: _buildGlassIconButton(Icons.arrow_back_rounded, () => context.pop()),
              actions: [
                if (SupabaseService().currentUserId != null &&
                    _viewModel.currentRequest != null &&
                    SupabaseService().currentUserId !=
                        _viewModel.currentRequest!.requesterId)
                  _buildGlassIconButton(Icons.flag_outlined, () => _showReportRequestDialog()),
                if (SupabaseService().currentUserId != null &&
                    _viewModel.currentRequest != null &&
                    SupabaseService().currentUserId ==
                        _viewModel.currentRequest!.requesterId)
                  _buildGlassIconButton(Icons.delete_outline_rounded, () => _showDeleteConfirmationDialog()),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: AppColors.primaryDark,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Opacity(
                            opacity: 0.25,
                            child: Image.network(
                              'https://maps.googleapis.com/maps/api/staticmap?center=${request.lat},${request.lng}&zoom=13&size=600x400&style=feature:all|element:labels|visibility:off&style=feature:road|element:geometry|color:0x444444&style=feature:water|element:geometry|color:0x111111&key=${dotenv.env["GOOGLE_MAPS_API_KEY"]}',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: AppColors.primaryDark),
                            ),
                          ),
                          // Premium Location Pulse
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 1.0, end: 1.5),
                            duration: const Duration(seconds: 2),
                            curve: Curves.easeInOut,
                            builder: (context, value, child) {
                              return Container(
                                padding: EdgeInsets.all(12 * value),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: child,
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: AppColors.auraGradient,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 32),
                            ),
                            onEnd: () {},
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
                            Colors.black.withValues(alpha: 0.6),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _buildPremiumChip(
                                    _getLocalizedCategory(request.category.name),
                                    _getCategoryColor(request.category.name),
                                  ),
                                  if (request.distance.isNotEmpty && request.distance.toLowerCase() != 'unknown') ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      request.distance,
                                      style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                request.title,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildStatusIndicator(request),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildApplicationStatusBanner(request),
                    const SizedBox(height: 16),
                    _buildUserSection(request),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),

                    Text(
                      AppLocalizations.of(context)!.description.toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.5,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      request.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildHelpersSection(),
                    const SizedBox(height: 24),
                    _buildSuggestedTools(),
                    const SizedBox(height: 32),

                    if (SupabaseService().currentUserId != request.requesterId) ...[
                      if (_applicationStatus == null)
                        PrimaryButton(
                          text: AppLocalizations.of(context)!.imInterested,
                          isLoading: _isApplying || _isCheckingStatus,
                          onPressed: request.status == RequestStatusEnum.open
                              ? () => _applyToRequest()
                              : () => ToastService.showInfo(
                                  context,
                                  AppLocalizations.of(context)!.requestNoLongerOpen,
                                ),
                        ),
                    ] else ...[
                      _buildRequesterActions(request),
                    ],
                    
                    if (SupabaseService().currentUserId == request.requesterId) ...[
                      const SizedBox(height: 32),
                      const Divider(),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Icon(Icons.group_outlined, color: AppColors.primaryLight, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Applications (${_applications.length})'.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              letterSpacing: 1.0,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isLoadingApplications)
                        const AppLoader()
                      else if (_applications.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.interestShown,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ),
                        )
                      else
                        ..._applications.map((app) => _buildApplicationCard(app, request)),
                    ],
                    const SizedBox(height: 48),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  border: const Border(top: BorderSide(color: Colors.amber, width: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR RATING', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.amber, letterSpacing: 1.0)),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(i < _ratingGiven ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text('$_ratingGiven / 5', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.amber)),
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
                  border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                ),
                child: PrimaryButton(
                  text: 'SUBMIT RATING',
                  onPressed: _showRatingDialog,
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink();
      }),
    );
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

  void _showDeleteConfirmationDialog() {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Delete Request'),
        content: const Text(
          'Are you sure you want to delete this request? This action cannot be undone.',
        ),
        actions: [
          adaptiveAction(
            context: context,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          adaptiveAction(
            context: context,
            onPressed: () {
              Navigator.pop(context);
              _deleteRequest();
            },
            isDestructiveAction: true,
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget adaptiveAction({
    required BuildContext context,
    required VoidCallback onPressed,
    required Widget child,
    bool isDestructiveAction = false,
  }) {
    final ThemeData theme = Theme.of(context);
    switch (theme.platform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return TextButton(
          onPressed: onPressed,
          style: isDestructiveAction
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
          child: child,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return CupertinoDialogAction(
          onPressed: onPressed,
          isDestructiveAction: isDestructiveAction,
          child: child,
        );
    }
  }

  Future<void> _deleteRequest() async {
    final error = await _viewModel.deleteRequest(widget.requestId);
    if (!mounted) return;

    if (error == null) {
      context.pop();
      ToastService.showSuccess(context, 'Request deleted successfully');
    } else {
      ToastService.showError(context, error);
    }
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

  Widget _buildUserSection(HelpRequestEntity request) {
    return Row(
      children: [
        Hero(
          tag: 'avatar-${request.id}',
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.3)),
            ),
            child: request.requesterAvatarUrl.isNotEmpty && (request.requesterAvatarUrl.startsWith('http'))
                ? CachedNetworkImage(
                    imageUrl: request.requesterAvatarUrl,
                    imageBuilder: (context, imageProvider) => CircleAvatar(radius: 20, backgroundImage: imageProvider),
                    errorWidget: (context, url, error) => const CircleAvatar(radius: 20, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
                  )
                : const CircleAvatar(radius: 20, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.requesterName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(AppLocalizations.of(context)!.requester, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          ],
        ),
        const Spacer(),
        if (SupabaseService().currentUserId != request.requesterId)
          AppHaptic(
            onTap: () => _startChat(request),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: _isStartingChat
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                  : const Icon(Icons.chat_bubble_rounded, color: AppColors.primaryLight, size: 18),
            ),
          ),
      ],
    );
  }

  Widget _buildHelpersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.communityHelpers.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0, color: Colors.grey[500]),
                ),
              ],
            ),
            if (_viewModel.potentialHelpers.length > 3)
              TextButton(
                onPressed: () => _showAllHelpersBottomSheet(context, _viewModel.potentialHelpers),
                child: Text(AppLocalizations.of(context)!.viewAll, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.nearbyMembersHelp,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (_viewModel.isLoadingHelpers)
          const AppLoader()
        else if (_viewModel.potentialHelpers.isEmpty)
          _buildEmptyHelpers()
        else
          ..._viewModel.potentialHelpers.take(3).map((helper) => HelperCard(
                helper: helper,
                onTap: () => context.push('/profile/${helper.user.id}'),
              )),
      ],
    );
  }

  Widget _buildEmptyHelpers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.people_alt_rounded, size: 40, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noHelpersYet,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Be the first to help out in your community!',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTools() {
    if (_isLoadingAssets) return const AppLoader();
    if (_matchedAssets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.construction_rounded, color: Colors.blueAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'SUGGESTED TOOLS'.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0, color: Colors.grey[500]),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _matchedAssets.length,
            itemBuilder: (context, index) {
              final asset = _matchedAssets[index];
              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                child: AssetCard(
                  asset: asset,
                  onTap: () => _showAssetDetails(asset),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRequesterActions(HelpRequestEntity request) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primaryLight.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded, color: AppColors.primaryLight, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Manage Your Request',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: -0.2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Keep an eye on applications from neighbors who want to help.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassIconButton(IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 20),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(HelpRequestEntity request) {
    final status = request.status;
    final color = _statusColor(status);
    final isOwner = SupabaseService().currentUserId == request.requesterId;

    if (isOwner) {
      return PopupMenuButton<RequestStatusEnum>(
        initialValue: status,
        onSelected: (s) => _updateHelpRequestStatus(s),
        child: _buildStatusChipContent(status, color, true),
        itemBuilder: (context) => RequestStatusEnum.values
            .map(
              (s) => PopupMenuItem(
                value: s,
                child: Text(
                  s.toString().split('.').last.toUpperCase(),
                  style: TextStyle(color: _statusColor(s), fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            )
            .toList(),
      );
    }

    return _buildStatusChipContent(status, color, false);
  }

  Widget _buildStatusChipContent(RequestStatusEnum status, Color color, bool isInteractive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            status.toString().split('.').last.toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          if (isInteractive) ...[
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, color: color, size: 16),
          ],
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    if (category == 'Emergency') return Colors.redAccent;
    if (category == 'Household') return Colors.orangeAccent;
    if (category == 'Tech Support') return Colors.blueAccent;
    if (category == 'Food') return Colors.greenAccent;
    return AppColors.secondaryLight;
  }

  Widget _buildApplicationStatusBanner(HelpRequestEntity request) {
    if (_applicationStatus == null) return const SizedBox.shrink();

    final Color color;
    final IconData icon;

    switch (_applicationStatus!) {
      case legacy.ApplicationStatus.accepted:
        color = Colors.greenAccent;
        icon = Icons.check_circle_rounded;
        break;
      case legacy.ApplicationStatus.rejected:
        color = Colors.grey;
        icon = Icons.info_outline_rounded;
        break;
      case legacy.ApplicationStatus.pending:
        color = Colors.orangeAccent;
        icon = Icons.pending_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getLocalizedApplicationStatus(_applicationStatus!.name).toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  _applicationStatus == legacy.ApplicationStatus.accepted
                      ? AppLocalizations.of(context)!.communicateWithRequester
                      : _applicationStatus == legacy.ApplicationStatus.rejected
                          ? 'The requester chose someone else for this task.'
                          : 'Your interest has been noted. Please wait for a response.',
                  style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.8), height: 1.3),
                ),
              ],
            ),
          ),
          if (_applicationStatus == legacy.ApplicationStatus.accepted)
            AppHaptic(
              onTap: () => _startChat(request),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const Text('CHAT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(legacy.RequestApplication app, HelpRequestEntity request) {
    final statusColor = app.status == legacy.ApplicationStatus.accepted
        ? Colors.greenAccent
        : app.status == legacy.ApplicationStatus.rejected
            ? Colors.grey
            : Colors.orangeAccent;

    return Container(
      key: ValueKey(app.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: statusColor.withValues(alpha: 0.1),
                child: Icon(Icons.person_rounded, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(app.applicantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      'Applied ${timeago.format(app.createdAt)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildPremiumChip(
                app.status.name.toUpperCase(),
                statusColor,
              ),
            ],
          ),
          if (app.status == legacy.ApplicationStatus.pending) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => _updateStatus(app.id, legacy.ApplicationStatus.rejected),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(app.id, legacy.ApplicationStatus.accepted),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.withValues(alpha: 0.1),
                      foregroundColor: Colors.greenAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else if (app.status == legacy.ApplicationStatus.accepted) ...[
            const SizedBox(height: 12),
            AppHaptic(
              onTap: () => _startChatWithUser(app.applicantId, app.applicantName),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_rounded, color: AppColors.primaryLight, size: 16),
                    SizedBox(width: 8),
                    Text('Message Applicant', style: TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _startChat(HelpRequestEntity request) {
    _startChatWithUser(request.requesterId, request.requesterName);
  }

  void _showAssetDetails(asset_models.CommunityAsset asset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Image / Header
              Stack(
                children: [
                  if (asset.imageUrl != null)
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(asset.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(gradient: AppColors.auraGradient),
                      child: const Icon(Icons.construction_rounded, color: Colors.white, size: 64),
                    ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton.filled(
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.3),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildPremiumChip(asset.category.name, AppColors.secondaryLight),
                        const Spacer(),
                        if (asset.similarity != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${(asset.similarity! * 100).toInt()}% MATCH',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      asset.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      asset.description,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.info_outline_rounded, color: AppColors.primaryLight, size: 20),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Coordinate with the neighbor to bring this tool.',
                              style: TextStyle(
                                fontSize: 13, 
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'I CAN BRING THIS',
                      onPressed: () {
                        Navigator.pop(context);
                        final requestTitle = _viewModel.currentRequest?.title ?? 'my request';
                        final msg = 'Hi, I saw your "${asset.title}" and can bring it to help with "$requestTitle".';
                        _startChatWithUser(asset.ownerId, asset.ownerName ?? 'Neighbor', initialMessage: msg);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

