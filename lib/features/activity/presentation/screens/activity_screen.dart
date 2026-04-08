import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../models/models.dart';
import '../../../../services/supabase_service.dart';
import '../../../../components/help_request_card.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with SingleTickerProviderStateMixin {
  late Future<List<HelpRequest>> _myRequestsFuture;
  late Future<List<Map<String, dynamic>>> _myApplicationsFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _myRequestsFuture = SupabaseService().getMyHelpRequests();
    _myApplicationsFuture = SupabaseService().getMyApplications();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _myRequestsFuture = SupabaseService().getMyHelpRequests();
      _myApplicationsFuture = SupabaseService().getMyApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.7),
              elevation: 0,
              centerTitle: false,
              systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
              title: Text(
                l10n.myActivity,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          gradient: RadialGradient(
            center: const Alignment(0.8, -0.5),
            radius: 1.5,
            colors: [
              AppColors.primaryLight.withValues(alpha: isDark ? 0.08 : 0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
            stops: const [0.0, 0.7],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 8),
            
            // Custom Glassmorphic Segmented Control
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 50,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryLight.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.3),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    Tab(text: l10n.myRequests.toUpperCase()),
                    Tab(text: l10n.volunteering.toUpperCase()),
                  ],
                ),
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── My Requests tab ──────────────────────────────────────
                  FutureBuilder<List<HelpRequest>>(
                    future: _myRequestsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator.adaptive());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                            _ActivityPlaceholder(
                              icon: Icons.assignment_rounded,
                              title: l10n.noActiveRequests,
                              subtitle: l10n.noRequestsLately,
                            ),
                          ],
                        );
                      }

                      final requests = snapshot.data!;
                      return RefreshIndicator(
                        onRefresh: () async => _refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 32),
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: HelpRequestCard(request: requests[index]),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  // ── Volunteering tab ─────────────────────────────────────
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _myApplicationsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator.adaptive());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                            _ActivityPlaceholder(
                              icon: Icons.volunteer_activism_rounded,
                              title: l10n.notVolunteeringYet,
                              subtitle: l10n.offerHelpToSee,
                            ),
                          ],
                        );
                      }

                      final applications = snapshot.data!;
                      return RefreshIndicator(
                        onRefresh: () async => _refresh(),
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 32),
                          itemCount: applications.length,
                          itemBuilder: (context, index) {
                            final item = applications[index];
                            final requestData = item['help_requests'];
                            if (requestData == null) return const SizedBox.shrink();

                            final request = HelpRequest.fromJson(requestData as Map<String, dynamic>);
                            final statusStr = (item['status'] as String?) ?? 'pending';
                            final appliedAt = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();

                            final status = ApplicationStatus.values.firstWhere(
                              (s) => s.name == statusStr,
                              orElse: () => ApplicationStatus.pending,
                            );

                            return _VolunteeringCard(
                              request: request,
                              status: status,
                              appliedAt: appliedAt,
                              onTap: () => context.push('/request/${request.id}'),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Premium Volunteering card — shows the request with the user's application status
// ──────────────────────────────────────────────────────────────────────────────
class _VolunteeringCard extends StatelessWidget {
  final HelpRequest request;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final VoidCallback onTap;

  const _VolunteeringCard({
    required this.request,
    required this.status,
    required this.appliedAt,
    required this.onTap,
  });

  Color get _statusColor {
    switch (status) {
      case ApplicationStatus.accepted:
         // Matches UI 'success' green
        return const Color(0xFF10B981);
      case ApplicationStatus.rejected:
        return Colors.grey;
      case ApplicationStatus.pending:
        // Match UI 'warning/pending' orange
        return const Color(0xFFF59E0B);
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case ApplicationStatus.accepted:
        return Icons.check_circle_rounded;
      case ApplicationStatus.rejected:
        return Icons.sentiment_neutral_outlined;
      case ApplicationStatus.pending:
        return Icons.access_time_filled_rounded;
    }
  }

  String _getStatusLabel(ApplicationStatus status, AppLocalizations l10n) {
    switch (status) {
      case ApplicationStatus.accepted:
        return l10n.accepted;
      case ApplicationStatus.rejected:
        return l10n.notSelected;
      case ApplicationStatus.pending:
        return l10n.awaitingReview;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppHaptic(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withValues(alpha: isDark ? 0.05 : 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Status chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, size: 14, color: _statusColor),
                        const SizedBox(width: 6),
                        Text(
                          _getStatusLabel(status, l10n).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.appliedAt(timeago.format(appliedAt)),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                request.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                request.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Location & category
              Row(
                children: [
                  if (!request.locationName.toLowerCase().contains('current location')) ...[
                    Icon(Icons.location_on_rounded, size: 14, color: AppColors.primaryLight.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        request.locationName,
                        style: TextStyle(
                          fontSize: 12, 
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), 
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.near_me_rounded, size: 14, color: AppColors.primaryLight.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      'Nearby',
                      style: TextStyle(
                        fontSize: 12, 
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5), 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                  ],

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryLight.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      request.category.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Divider
              Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
              const SizedBox(height: 16),
              // Requester
              Row(
                children: [
                  request.requesterAvatarUrl.isNotEmpty &&
                          (request.requesterAvatarUrl.startsWith('http://') || request.requesterAvatarUrl.startsWith('https://'))
                      ? CachedNetworkImage(
                          imageUrl: request.requesterAvatarUrl,
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: 12,
                            backgroundImage: imageProvider,
                          ),
                          errorWidget: (context, url, error) => CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey[200],
                            child: Icon(Icons.person_rounded, size: 14, color: Colors.grey[400]),
                          ),
                        )
                      : CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.person_rounded, size: 14, color: Colors.grey[400]),
                        ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.postedBy(request.requesterName),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
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

// ──────────────────────────────────────────────────────────────────────────────
class _ActivityPlaceholder extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ActivityPlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : Colors.black87,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
