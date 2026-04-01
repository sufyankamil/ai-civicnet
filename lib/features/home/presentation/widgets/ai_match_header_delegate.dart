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
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: t > 0.5 ? (t - 0.5) * 2 : 0.0),
      child: AppHaptic(
        onTap: () => context.push('/request/${request.id}'),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryLight.withValues(alpha: 0.8),
                const Color(0xFF6248FF).withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.2 * (1 - t * 0.5)),
                blurRadius: 20 * (1 - t * 0.5),
                offset: Offset(0, 10 * (1 - t * 0.5)),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Glass highlight
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                   color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.05),
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
                            const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        children: [
                          if (t > 0.5) ...[
                             const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
                             const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (t < 0.3) 
                                  const Text(
                                    'PREMIUM AI MATCH',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                Text(
                                  request.title,
                                  style: TextStyle(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
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
                              color: Colors.white.withValues(alpha: 0.9),
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
