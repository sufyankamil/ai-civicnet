import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../domain/entities/request_enums.dart';
import '../viewmodels/request_viewmodel.dart';
import 'package:get/get.dart';

import '../../../../models/models.dart' as legacy;
import '../../../../services/logger_service.dart';
import '../../../../features/assets/presentation/viewmodels/assets_viewmodel.dart';
import '../../../../features/assets/models/asset.dart' as asset_models;
import '../../../../components/primary_button.dart';
import '../../../../components/rating_dialog.dart';
import '../../../../services/toast_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../components/report_dialog.dart';
import '../../../../services/supabase_service.dart';
import '../../../../components/success_animation.dart';
import 'widgets/request_components.dart';

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
  int _ratingGiven = 0;
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
    if (SupabaseService().currentUserId != requesterId) return;
    if (_isLoadingApplications) return;

    setState(() => _isLoadingApplications = true);
    try {
      final apps = await SupabaseService().getApplicationsForRequest(widget.requestId);
      if (mounted) {
        setState(() {
          _applications = apps;
          _hasFetchedApplications = true;
        });
      }
    } catch (e) {
      logger.e('Error loading applications: $e');
    } finally {
      if (mounted) setState(() => _isLoadingApplications = false);
    }
  }

  Future<void> _checkApplicationStatus() async {
    if (SupabaseService().currentUserId == null) return;
    try {
      final status = await SupabaseService().getApplicationStatus(widget.requestId);
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
      logger.e('Error checking status: $e');
      if (mounted) setState(() => _isCheckingStatus = false);
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
        url += '&msg=${Uri.encodeComponent(initialMessage)}';
      }
      context.push(url);
    } catch (e) {
      if (mounted) ToastService.showError(context, 'Unable to start chat.');
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }

  void _showAssetDetails(asset_models.CommunityAsset asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AssetDetailSheet(
        asset: asset,
        requestTitle: _viewModel.currentRequest?.title,
        onStartChat: _startChatWithUser,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        if (_viewModel.isLoading && _viewModel.currentRequest == null) {
          return const RequestDetailSkeleton();
        }
        final request = _viewModel.currentRequest;
        if (request == null) return const Center(child: Text('Request not found'));

        if (SupabaseService().currentUserId == request.requesterId && !_hasFetchedApplications && !_isLoadingApplications) {
          Future.microtask(() => _loadApplications(request.requesterId));
        }

        return CustomScrollView(
          slivers: [
            RequestHeaderSliver(
              request: request,
              currentUserId: SupabaseService().currentUserId,
              onReport: _showReportRequestDialog,
              onDelete: _showDeleteConfirmationDialog,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    RequestInfoSection(request: request, onStatusChange: _updateHelpRequestStatus),
                    const SizedBox(height: 16),
                    StatusBannerSection(
                      applicationStatus: _applicationStatus,
                      onChat: () => _startChatWithUser(request.requesterId, request.requesterName),
                    ),
                    const SizedBox(height: 16),
                    RequesterSection(
                      request: request,
                      isStartingChat: _isStartingChat,
                      onChat: () => _startChatWithUser(request.requesterId, request.requesterName),
                    ),
                    const SizedBox(height: 24),
                    const Divider(height: 1),
                    const SizedBox(height: 24),
                    DescriptionSection(description: request.description),
                    const SizedBox(height: 32),
                    HelperManagementSection(
                      potentialHelpers: _viewModel.potentialHelpers,
                      isLoading: _viewModel.isLoadingHelpers,
                    ),
                    const SizedBox(height: 24),
                    SuggestedToolsSection(
                      matchedAssets: _matchedAssets,
                      isLoading: _isLoadingAssets,
                      onAssetTap: _showAssetDetails,
                    ),
                    const SizedBox(height: 32),
                    if (SupabaseService().currentUserId != request.requesterId) ...[
                      if (_applicationStatus == null && request.status == RequestStatusEnum.open)
                        PrimaryButton(
                          text: AppLocalizations.of(context)!.imInterested,
                          isLoading: _isApplying || _isCheckingStatus,
                          onPressed: _applyToRequest,
                        ),
                    ] else ...[
                      const OwnerActionsSection(),
                    ],
                    if (SupabaseService().currentUserId == request.requesterId)
                      ApplicationsSection(
                        request: request,
                        applications: _applications,
                        isLoading: _isLoadingApplications,
                        onUpdateStatus: _updateStatus,
                        onStartChat: _startChatWithUser,
                      ),
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
        return RequestActionBottomBar(
          request: request,
          currentUserId: SupabaseService().currentUserId,
          hasRated: _hasRated,
          ratingGiven: _ratingGiven,
          onRate: _showRatingDialog,
        );
      }),
    );
  }

  // --- Actions ---

  Future<void> _applyToRequest() async {
    setState(() => _isApplying = true);
    try {
      await SupabaseService().applyToRequest(widget.requestId);
      if (mounted) {
        setState(() => _applicationStatus = legacy.ApplicationStatus.pending);
        _showSuccessDialog('Interest Sent!', 'Waiting for requester to accept.');
      }
    } catch (e) {
      if (mounted) ToastService.showError(context, 'Failed to apply.');
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  Future<void> _updateStatus(String appId, legacy.ApplicationStatus status) async {
    try {
      await SupabaseService().updateApplicationStatus(appId, status);
      await _viewModel.fetchHelpRequest(widget.requestId);
      final request = _viewModel.currentRequest;
      if (request != null) await _loadApplications(request.requesterId);
      if (mounted) ToastService.showSuccess(context, 'Application ${status.name}!');
    } catch (e) {
      if (mounted) ToastService.showError(context, 'Failed to update status.');
    }
  }

  Future<void> _updateHelpRequestStatus(RequestStatusEnum status) async {
    if (status == RequestStatusEnum.completed) {
      _showCompletionDialog();
      return;
    }
    final error = await _viewModel.updateRequestStatus(widget.requestId, status);
    if (mounted) {
      if (error == null) {
        ToastService.showSuccess(context, 'Status updated!');
        _viewModel.fetchHelpRequest(widget.requestId);
      } else {
        ToastService.showError(context, error);
      }
    }
  }

  // --- Dialogs ---

  void _showSuccessDialog(String title, String message) {
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
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 24),
                  PrimaryButton(text: 'Got it', onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog() async {
    final applications = await SupabaseService().getApplicationsForRequest(widget.requestId);
    if (!mounted) return;
    if (applications.isEmpty) {
      ToastService.showInfo(context, 'No applicants to mark as helper.');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Completed'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(app.applicantName),
                subtitle: Text('Applied ${timeago.format(app.createdAt)}'),
                onTap: () => _confirmCompletion(app),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCompletion(legacy.RequestApplication app) async {
    Navigator.pop(context);
    bool confirm = await showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Confirm Completion'),
        content: Text('Mark as completed by ${app.applicantName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    ) ?? false;
    if (!confirm) return;

    try {
      await SupabaseService().completeHelpRequest(widget.requestId.trim(), app.applicantId.trim());
      await _viewModel.fetchHelpRequest(widget.requestId);
      if (mounted) _showSuccessDialog('Task Completed!', 'Points awarded to both!');
    } catch (e) {
      if (mounted) ToastService.showError(context, 'Action failed.');
    }
  }

  void _showRatingDialog() async {
    final request = _viewModel.currentRequest;
    if (request == null) return;
    final currentUserId = SupabaseService().currentUserId;
    final isOwner = request.requesterId == currentUserId;
    String ratedUserId = isOwner ? request.helperId! : request.requesterId;
    final profile = await SupabaseService().getUserProfile(ratedUserId);

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingDialog(
        ratedUserName: profile?.name ?? 'User',
        ratedUserAvatar: profile?.avatarUrl ?? '',
        onRate: (rating) async {
          await SupabaseService().rateUser(requestId: widget.requestId, ratedUserId: ratedUserId, rating: rating);
          if (mounted) setState(() { _hasRated = true; _ratingGiven = rating; });
        },
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showAdaptiveDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Delete Request'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.pop(context); _deleteRequest(); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _deleteRequest() async {
    final error = await _viewModel.deleteRequest(widget.requestId);
    if (!mounted) return;
    if (error == null) {
      // ignore: use_build_context_synchronously
      context.pop();
      ToastService.showSuccess(context, 'Request deleted');
    } else {
      ToastService.showError(context, error);
    }
  }

  void _showReportRequestDialog() {
    final request = _viewModel.currentRequest;
    if (request == null) return;
    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        title: 'Report Request',
        onReport: (reason) async {
          try {
            await SupabaseService().reportUser(request.requesterId, reason);
            if (mounted) {
              // ignore: use_build_context_synchronously
              ToastService.showSuccess(context, 'Reported and blocked.');
              // ignore: use_build_context_synchronously
              context.pop(); // Close dialog
              // ignore: use_build_context_synchronously
              context.pop(); // Go back
            }
          } catch (e) {
            // ignore: use_build_context_synchronously
            if (mounted) ToastService.showError(context, 'Report failed.');
          }
        },
      ),
    );
  }
}
