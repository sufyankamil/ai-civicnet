import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../models/models.dart';
import '../../../../services/supabase_service.dart';
import '../../../../components/help_request_card.dart';
import '../../../../theme/app_theme.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late Future<List<HelpRequest>> _myRequestsFuture;
  late Future<List<Map<String, dynamic>>> _myApplicationsFuture;

  @override
  void initState() {
    super.initState();
    _myRequestsFuture = SupabaseService().getMyHelpRequests();
    _myApplicationsFuture = SupabaseService().getMyApplications();
  }

  void _refresh() {
    setState(() {
      _myRequestsFuture = SupabaseService().getMyHelpRequests();
      _myApplicationsFuture = SupabaseService().getMyApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.myActivity, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          bottom: TabBar(
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).primaryColor,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.myRequests),
              Tab(text: AppLocalizations.of(context)!.volunteering),
            ],
          ),
        ),
        body: TabBarView(
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
                  return _ActivityPlaceholder(
                    icon: Icons.assignment_rounded,
                    title: AppLocalizations.of(context)!.noActiveRequests,
                    subtitle: AppLocalizations.of(context)!.noRequestsLately,
                  );
                }

                final requests = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      return HelpRequestCard(request: requests[index]);
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
                  return _ActivityPlaceholder(
                    icon: Icons.volunteer_activism_rounded,
                    title: AppLocalizations.of(context)!.notVolunteeringYet,
                    subtitle: AppLocalizations.of(context)!.offerHelpToSee,
                  );
                }

                final applications = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: () async => _refresh(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
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
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Volunteering card — shows the request with the user's application status chip
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
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.grey;
      case ApplicationStatus.pending:
        return Colors.orange;
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case ApplicationStatus.accepted:
        return Icons.check_circle;
      case ApplicationStatus.rejected:
        return Icons.sentiment_neutral_outlined;
      case ApplicationStatus.pending:
        return Icons.access_time_filled;
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon, size: 13, color: _statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _getStatusLabel(status, l10n),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.appliedAt(timeago.format(appliedAt)),
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                request.title,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Location & category
              Row(
                children: [
                  Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      request.locationName,
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.category.toString().split('.').last,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Requester
              Row(
                children: [
                  request.requesterAvatarUrl.isNotEmpty &&
                          (request.requesterAvatarUrl.startsWith('http://') || request.requesterAvatarUrl.startsWith('https://'))
                      ? CachedNetworkImage(
                          imageUrl: request.requesterAvatarUrl,
                          imageBuilder: (context, imageProvider) => CircleAvatar(
                            radius: 10,
                            backgroundImage: imageProvider,
                          ),
                          errorWidget: (context, url, error) => const CircleAvatar(
                            radius: 10,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, size: 12, color: Colors.white),
                          ),
                        )
                      : const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, size: 12, color: Colors.white),
                        ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.postedBy(request.requesterName),
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
