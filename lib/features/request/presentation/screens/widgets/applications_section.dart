import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:shimmer/shimmer.dart';
import '../../../../../models/models.dart' as legacy;
import '../../../../../widgets/haptic_buttons.dart';
import '../../../../../theme/app_theme.dart';
import '../../../domain/entities/help_request_entity.dart';
import '../../../../../l10n/app_localizations.dart';
import 'premium_chip.dart';

class ApplicationsSection extends StatelessWidget {
  final HelpRequestEntity request;
  final List<legacy.RequestApplication> applications;
  final bool isLoading;
  final Function(String appId, legacy.ApplicationStatus status) onUpdateStatus;
  final Function(String userId, String userName) onStartChat;

  const ApplicationsSection({
    super.key,
    required this.request,
    required this.applications,
    required this.isLoading,
    required this.onUpdateStatus,
    required this.onStartChat,
  });

  Widget _buildApplicationShimmer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, legacy.RequestApplication app) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final statusColor = app.status == legacy.ApplicationStatus.accepted
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981)) // Modern Success Green
        : app.status == legacy.ApplicationStatus.rejected
            ? (isDark ? Colors.grey[400]! : Colors.grey[600]!)
            : (isDark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B)); // Modern Warning Amber

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
              PremiumChip(
                label: app.status.name.toUpperCase(),
                color: statusColor,
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
                  child: AppHaptic(
                    onTap: () => onUpdateStatus(app.id, legacy.ApplicationStatus.rejected),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.15)),
                      ),
                      child: const Center(
                        child: Text(
                          'Decline',
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppHaptic(
                    onTap: () => onUpdateStatus(app.id, legacy.ApplicationStatus.accepted),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.greenAccent.shade400, Colors.greenAccent.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Accept',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else if (app.status == legacy.ApplicationStatus.accepted) ...[
            const SizedBox(height: 12),
            AppHaptic(
              onTap: () => onStartChat(app.applicantId, app.applicantName),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.group_outlined, color: AppColors.primaryLight, size: 22),
            const SizedBox(width: 8),
            Text(
              'Applications (${applications.length})'.toUpperCase(),
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
        if (isLoading)
          Column(
            children: List.generate(2, (index) => _buildApplicationShimmer(context)),
          )
        else if (applications.isEmpty)
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
          ...applications.map((app) => _buildApplicationCard(context, app)),
      ],
    );
  }
}
