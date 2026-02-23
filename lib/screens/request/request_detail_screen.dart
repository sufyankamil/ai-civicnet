import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/models.dart';

import '../../services/supabase_service.dart';
import 'package:community_net/services/logger_service.dart';
import '../../theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../components/helper_card.dart';
import '../../components/primary_button.dart';
import '../../components/rating_dialog.dart'; 
import '../../services/toast_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  late Future<HelpRequest?> _requestFuture;
  HelpRequest? _request; // To store the fetched request object
  ApplicationStatus? _applicationStatus;
  bool _isCheckingStatus = true;
  bool _isApplying = false;
  List<RequestApplication> _applications = [];
  bool _isLoadingApplications = false;
  bool _hasFetchedApplications = false;
  bool _hasRated = false; // Track if user has rated for this request


  @override
  void initState() {
    super.initState();
    _requestFuture = SupabaseService().getHelpRequest(widget.requestId);
    _checkApplicationStatus();
  }

  Future<void> _loadApplications(String requesterId) async {
    if (SupabaseService().currentUserId != requesterId) {
      logger.d('DEBUG: Current user is not requester. Skipping load.');
      return;
    }
    if (_isLoadingApplications) return;

    logger.d('DEBUG: Loading applications for request ${widget.requestId}...');
    setState(() => _isLoadingApplications = true);
    try {
      final apps = await SupabaseService().getApplicationsForRequest(widget.requestId);
      logger.d('DEBUG: Loaded ${apps.length} applications.');
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
      final status = await SupabaseService().getApplicationStatus(widget.requestId);
      final request = await SupabaseService().getHelpRequest(widget.requestId);
      final hasRated = await SupabaseService().hasUserRated(widget.requestId);
      
      if (mounted) {
        setState(() {
          _applicationStatus = status;
          _request = request; // Set _request
          _hasRated = hasRated; // Set _hasRated
          _isCheckingStatus = false;
        });
      }
    } catch (e) {
      logger.e('Error checking application status or fetching request/rating: $e');
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
      context.push('/chat-detail?id=$conversationId&name=$encodedName&uid=$userId');
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error starting chat: $e');
      }
    } finally {
      if (mounted) setState(() => _isStartingChat = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<HelpRequest?>(
        future: _requestFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Request not found or error: ${snapshot.error}'));
          }

          final request = snapshot.data!;
          
          if (SupabaseService().currentUserId == request.requesterId && !_hasFetchedApplications && !_isLoadingApplications) {
             Future.microtask(() => _loadApplications(request.requesterId));
          }


          return CustomScrollView(
            slivers: [
              // ... existing SliverAppBar ...
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        'https://maps.googleapis.com/maps/api/staticmap?center=${request.lat},${request.lng}&zoom=15&size=600x400&markers=color:red%7C${request.lat},${request.lng}&key=${dotenv.env["GOOGLE_MAPS_API_KEY"]}', 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.3),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
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
                      // ... existing request details ...
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryLight.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              request.category.toString().split('.').last.toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            request.distance,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              request.title,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                              ),
                            ),
                          ),
                          if (SupabaseService().currentUserId == request.requesterId)
                            PopupMenuButton<RequestStatus>(
                              initialValue: request.status,
                              onSelected: (status) => _updateHelpRequestStatus(status),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _statusColor(request.status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _statusColor(request.status)),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      request.status.toString().split('.').last.toUpperCase(),
                                      style: TextStyle(
                                        color: _statusColor(request.status),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down, color: _statusColor(request.status), size: 16),
                                  ],
                                ),
                              ),
                              itemBuilder: (context) => RequestStatus.values.map((s) => PopupMenuItem(
                                value: s,
                                child: Text(s.toString().split('.').last.toUpperCase()),
                              )).toList(),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(request.status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _statusColor(request.status)),
                              ),
                              child: Text(
                                request.status.toString().split('.').last.toUpperCase(),
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
                      
                      // Points Banner for Helper
                      if (request.status == RequestStatus.completed && 
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
                              const Icon(Icons.stars, color: Colors.orange, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Task Completed!',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.green[800]),
                                    ),
                                    Text(
                                      'You earned 15 points for helping out.',
                                      style: GoogleFonts.poppins(color: Colors.green[800], fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),
                      // Requester info
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(request.requesterAvatarUrl),
                            radius: 20,
                            onBackgroundImageError: (_, __) {},
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.requesterName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Requester',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                          const Spacer(),
                          if (SupabaseService().currentUserId != request.requesterId)
                            IconButton(
                              icon: _isStartingChat 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
                                  : const Icon(Icons.chat_bubble_outline, color: AppColors.primaryLight),
                              onPressed: () => _startChat(request),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      Text(
                        'Description',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        request.description,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Helpers section
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.secondaryLight, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Community Helpers',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nearby members who might be able to help.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<Helper>>(
                        future: SupabaseService().getPotentialHelpers(request),
                        builder: (context, snapshot) {
                          // ... existing helper builder ...
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator.adaptive());
                          }
                          if (snapshot.error != null) {
                            return Text('Error loading helpers: ${snapshot.error}');
                          }
                          final helpers = snapshot.data ?? [];
                          
                          if (helpers.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.people_outline, size: 48, color: Colors.grey),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No helpers available yet',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Be the first to join the community!',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            children: helpers.map((helper) => HelperCard(
                              helper: helper,
                              onTap: () {
                                ToastService.showSuccess(context, 'Viewing ${helper.user.name}\'s profile');
                              },
                            )).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Apply button / Status for non-requester
                      if (SupabaseService().currentUserId != request.requesterId) ...[
                        // ... existing application status UI ...
                          if (_applicationStatus != null)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _applicationStatus == ApplicationStatus.accepted 
                                      ? Colors.green.withValues(alpha: 0.1) 
                                      : Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _applicationStatus == ApplicationStatus.accepted 
                                        ? Colors.green 
                                        : Colors.orange,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _applicationStatus == ApplicationStatus.accepted 
                                              ? Icons.check_circle 
                                              : Icons.access_time_filled,
                                          color: _applicationStatus == ApplicationStatus.accepted 
                                              ? Colors.green 
                                              : Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _applicationStatus == ApplicationStatus.accepted 
                                              ? 'Application Accepted!' 
                                              : 'Interest Sent (Pending)',
                                          style: TextStyle(
                                            color: _applicationStatus == ApplicationStatus.accepted 
                                                ? Colors.green[800] 
                                                : Colors.orange[800],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_applicationStatus == ApplicationStatus.accepted) ...[
                                      const SizedBox(height: 8),
                                      const Text(
                                        'You can now communicate with the requester.',
                                        style: TextStyle(fontSize: 12, color: Colors.green),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: () => _startChat(request),
                                        icon: const Icon(Icons.chat),
                                        label: const Text('Chat with Requester'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            )
                          else
                            Opacity(
                              opacity: request.status != RequestStatus.open ? 0.5 : 1.0,
                              child: PrimaryButton(
                                text: 'I\'m Interested',
                                isLoading: _isApplying || _isCheckingStatus,
                                onPressed: request.status == RequestStatus.open
                                    ? () => _applyToRequest()
                                    : () => ToastService.showInfo(context, 'This request is no longer open for applications.'),
                              ),
                            ),
                      ] else ...[
                         // Is Requester
                        Center(
                          child: Text(
                            'This is your request',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Applications List (Only for Requester)
                      if (SupabaseService().currentUserId == request.requesterId) ...[
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'Applications (${_applications.length})',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingApplications)
                          const Center(child: CircularProgressIndicator.adaptive())
                        else if (_applications.isEmpty)
                          Text(
                            'No interest shown yet.',
                            style: TextStyle(color: Colors.grey[600]),
                          )
                        else
                          ..._applications.map((app) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: app.applicantAvatarUrl.isNotEmpty 
                                        ? NetworkImage(app.applicantAvatarUrl) 
                                        : null,
                                    child: app.applicantAvatarUrl.isEmpty 
                                        ? Text(app.applicantName.isNotEmpty ? app.applicantName[0] : '?') 
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          app.applicantName,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          app.status.toString().split('.').last.toUpperCase(),
                                          style: TextStyle(
                                            color: app.status == ApplicationStatus.accepted 
                                                ? Colors.green 
                                                : (app.status == ApplicationStatus.rejected ? Colors.red : Colors.orange),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Chat button if accepted
                                  if (app.status == ApplicationStatus.accepted)
                                     IconButton(
                                      icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryLight),
                                      onPressed: () => _startChatWithUser(app.applicantId, app.applicantName),
                                    ),

                                  if (app.status == ApplicationStatus.pending) ...[
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                                      onPressed: () => _updateStatus(app.id, ApplicationStatus.accepted),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                      onPressed: () => _updateStatus(app.id, ApplicationStatus.rejected),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )),
                        const SizedBox(height: 32), 
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          if (_request == null) return const SizedBox.shrink();

          final currentUserId = SupabaseService().currentUserId;
          final isOwner = _request!.requesterId == currentUserId;
          final isHelper = _request!.helperId == currentUserId;

          if (_request!.status == RequestStatus.completed) {
            if (_hasRated) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.green.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Request Completed', style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            } 
            
            // Show Rate Button if involved
            if (isOwner || isHelper) {
                return Container(
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
                );
            }
          }
          return const SizedBox.shrink();
        }
      ),
    );
  }

  bool _isStartingChat = false;

  Future<void> _startChat(HelpRequest request) async {
    if (_isStartingChat) return;
    if (SupabaseService().currentUserId == request.requesterId) {
      ToastService.showInfo(context, 'You cannot chat with yourself');
      return;
    }

    setState(() => _isStartingChat = true);
    try {
      final conversationId = await SupabaseService().createConversation(request.requesterId);
      if (mounted) {
        final encodedName = Uri.encodeComponent(request.requesterName);
        context.push('/chat-detail?id=$conversationId&name=$encodedName&uid=${request.requesterId}');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error starting chat: $e');
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
        setState(() => _applicationStatus = ApplicationStatus.pending);
        ToastService.showSuccess(context, 'Interest sent! Waiting for requester to accept.');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error applying: $e');
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }
  Future<void> _updateStatus(String appId, ApplicationStatus status) async {
    try {
      await SupabaseService().updateApplicationStatus(appId, status);
      // Refresh list
      final request = await _requestFuture;
      if (request != null) {
        await _loadApplications(request.requesterId);
      }
      if (mounted) {
        ToastService.showSuccess(context, 'Application ${status.name}!');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error updating status: $e');
      }
    }
  }
  Future<void> _updateHelpRequestStatus(RequestStatus status) async {
    if (status == RequestStatus.completed) {
      _showCompletionDialog();
      return;
    }

    try {
      await SupabaseService().updateHelpRequestStatus(widget.requestId, status);
      setState(() {
        _requestFuture = SupabaseService().getHelpRequest(widget.requestId);
      });
      if (mounted) {
        ToastService.showSuccess(context, 'Request status updated to ${status.toString().split('.').last}!');
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error updating status: $e');
      }
    }
  }

  void _showCompletionDialog() async {
    // Fetch applications to show candidates
    final applications = await SupabaseService().getApplicationsForRequest(widget.requestId);
    
    if (!mounted) return;

    if (applications.isEmpty) {
       ToastService.showInfo(context, 'No applicants to mark as helper. Wait for someone to apply.');
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
                      leading: CircleAvatar(
                        backgroundImage: app.applicantAvatarUrl.isNotEmpty ? NetworkImage(app.applicantAvatarUrl) : null,
                        child: app.applicantAvatarUrl.isEmpty ? Text(app.applicantName[0]) : null,
                      ),
                      title: Text(app.applicantName),
                      subtitle: Text('Applied ${timeago.format(app.createdAt)}'),
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

  Future<void> _confirmCompletion(RequestApplication app) async {
    // Close selection dialog
    Navigator.pop(context);

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Completion'),
        content: Text('Are you sure you want to mark this task as completed by ${app.applicantName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      logger.d('DEBUG: Completing request ${widget.requestId} with helper ${app.applicantId}');
      await SupabaseService().completeHelpRequest(widget.requestId.trim(), app.applicantId.trim());
      
      setState(() {
        _requestFuture = SupabaseService().getHelpRequest(widget.requestId);
      });
      
      if (mounted) {
        showDialog(
          context: context, 
          builder: (context) => AlertDialog(
            title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 8), Text('Success!')]),
            content: const Text('Task completed. Points have been awarded to both of you.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.showError(context, 'Error: $e');
      }
    }
  }

  void _showRatingDialog() async {
    if (_request == null) return;
    
    final currentUserId = SupabaseService().currentUserId;
    final isOwner = _request!.requesterId == currentUserId;
    
    // If I am owner, I rate the helper.
    // If I am helper, I rate the owner.
    String ratedUserId;
    String ratedUserName;
    String ratedUserAvatar;

    if (isOwner) {
       // Need to fetch helper details. 
       if (_request!.helperId == null) return;
       ratedUserId = _request!.helperId!;
       // We'd ideally need to fetch the profile to get name/avatar.
       final profile = await SupabaseService().getUserProfile(ratedUserId);
       ratedUserName = profile?.name ?? 'Helper';
       ratedUserAvatar = profile?.avatarUrl ?? '';
    } else {
       ratedUserId = _request!.requesterId;
       ratedUserName = _request!.requesterName;
       ratedUserAvatar = _request!.requesterAvatarUrl;
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
            });
            ToastService.showSuccess(context, 'Rating submitted!');
          } catch (e) {
            if (!context.mounted) return;
            ToastService.showError(context, 'Error submitting rating: $e');
          }
        },
      ),
    );
  }

  Color _statusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.open: return Colors.green;
      case RequestStatus.inProgress: return Colors.blue;
      case RequestStatus.completed: return Colors.purple;
      case RequestStatus.closed: return Colors.grey;
    }
  }
}
