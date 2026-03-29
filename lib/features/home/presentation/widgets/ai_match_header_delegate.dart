import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_theme.dart';
import '../../../request/domain/entities/help_request_entity.dart';
import '../../../../widgets/haptic_buttons.dart';

class AiMatchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final HelpRequestEntity request;
  final double maxExtentValue;
  final double minExtentValue;

  AiMatchHeaderDelegate({
    required this.request,
    this.maxExtentValue = 240.0,
    this.minExtentValue = 85.0,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double t = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final int matchPercentage = (request.aiRelevanceScore * 100).toInt();

    // Responsive values based on scroll (t) with rounding to prevent precision errors
    final double horizontalPadding = lerpDouble(16.0, 12.0, t)!.roundToDouble();
    final double cardPadding = lerpDouble(16.0, 12.0, t)!.roundToDouble();
    final double borderRadius = lerpDouble(24.0, 16.0, t)!.roundToDouble();
    final double titleSize = lerpDouble(22.0, 15.0, t)!.roundToDouble();
    final double opacity = (1.0 - t * 2.5).clamp(0.0, 1.0); // Description fades quickly

    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 2.0, horizontalPadding, 16.0),
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: t > 0.5 ? (t - 0.5) * 2 : 0.0), // Fade in background as it sticks
      child: AppHaptic(
        onTap: () => context.push('/request/${request.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryLight.withValues(alpha: 0.9),
                const Color(0xFF6248FF).withValues(alpha: 0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.3 * (1 - t * 0.5)),
                blurRadius: 15 * (1 - t * 0.5),
                offset: Offset(0, 5 * (1 - t * 0.5)),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Glass effect for the pill
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                   color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.1),
                   borderRadius: BorderRadius.circular(borderRadius),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (t < 0.3) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildMatchBadge(matchPercentage),
                            const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          if (t > 0.5) ...[
                             const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                             const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (t < 0.3) 
                                  const Text(
                                    'TRUE AI: TOP MATCH',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                Text(
                                  request.title,
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (t > 0.4) ...[
                            const SizedBox(width: 8),
                            _buildCompactAction(context),
                          ],
                        ],
                      ),
                      if (t < 0.2) ...[
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: opacity,
                          child: Text(
                            request.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchBadge(int percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            '$percentage% MATCH',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Action',
            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 8),
        ],
      ),
    );
  }

  @override
  double get maxExtent => maxExtentValue;

  @override
  double get minExtent => minExtentValue;

  @override
  bool shouldRebuild(covariant AiMatchHeaderDelegate oldDelegate) {
    return oldDelegate.request.id != request.id;
  }
}
