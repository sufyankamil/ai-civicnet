import 'package:flutter/material.dart';
import 'parallax_card.dart';
import 'package:civic_net/features/profile/models/user.dart';
import 'package:civic_net/theme/app_theme.dart';
import 'package:civic_net/services/pdf_service.dart';

class ImpactDashboard extends StatelessWidget {
  final User user;
  final bool isDark;
  final ScrollController scrollController;

  static const int _exportThreshold = 50;

  const ImpactDashboard({
    super.key,
    required this.user,
    required this.isDark,
    required this.scrollController,
  });

  Widget _buildExportButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLocked = user.neighborsImpacted < _exportThreshold;
    final accentColor = isLocked 
        ? (isDark ? Colors.grey[600] : Colors.grey[400]) 
        : AppColors.primaryLight;

    return IconButton(
      onPressed: () {
        if (isLocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Unlock your official certificate at $_exportThreshold Neighbors Helped! (Current: ${user.neighborsImpacted})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.primaryLight,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(20),
            ),
          );
        } else {
          PdfService.generateVolunteerCertificate(user);
        }
      },
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: accentColor!.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isLocked ? Icons.lock_rounded : Icons.picture_as_pdf_rounded,
          size: 18,
          color: accentColor,
        ),
      ),
      tooltip: isLocked ? 'Locked: Help 50 neighbors' : 'Export Volunteer Certificate',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Using calculated properties from the User model
    final hoursSaved = user.hoursSaved;
    final neighborsImpacted = user.neighborsImpacted;
    final progress = user.levelProgress;
    final pointsToNext = user.pointsToNextRank;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_graph_rounded, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(
                'Community Impact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              _buildExportButton(context),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildImpactStat(
                context,
                'Neighbors Impacted',
                neighborsImpacted.toString(),
                Icons.people_alt_rounded,
                Colors.blue,
              ),
              _buildImpactStat(
                context,
                'Hours Saved',
                '${hoursSaved}h',
                Icons.timer_rounded,
                Colors.orange,
              ),
              _buildImpactStat(
                context,
                'Trust Score',
                '${(user.rating * 20).toInt()}%',
                Icons.verified_user_rounded,
                Colors.green,
                onTap: () => _showTrustBreakdown(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level Progress',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey[700],
                ),
              ),
              Text(
                '$pointsToNext pts to next rank',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutExpo,
                builder: (context, value, child) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4A90E2), Color(0xFF7B61FF)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryLight.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Glowing Tip
                      if (value > 0.01)
                        Positioned(
                          left: (MediaQuery.of(context).size.width - 80) * value - 4,
                          child: Container(
                            width: 8,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryLight,
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress * 100),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutExpo,
            builder: (context, value, child) {
              return Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${value.toInt()}% Complete',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight.withValues(alpha: 0.8),
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: onTap != null 
                ? Border.all(color: color.withValues(alpha: 0.3), width: 1)
                : null,
            ),
            child: ParallaxCard(
              scrollController: scrollController,
              parallaxSpeed: 0.3,
              child: Icon(icon, color: color, size: 18),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
              letterSpacing: 0.5,
              decoration: onTap != null ? TextDecoration.underline : null,
              decorationColor: color.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrustBreakdown(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Trust Score Details',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBreakdownRow('Reliability', 0.85, Colors.blue),
            const SizedBox(height: 16),
            _buildBreakdownRow('Communication', 0.90, Colors.purple),
            const SizedBox(height: 16),
            _buildBreakdownRow('Speed', 0.75, Colors.orange),
            const SizedBox(height: 24),
            Text(
              'Based on your last 10 community interactions.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.grey[800],
              ),
            ),
            Text(
              '${(score * 100).toInt()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: score,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 4,
        ),
      ],
    );
  }
}
