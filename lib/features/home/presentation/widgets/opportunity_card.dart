import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../theme/app_theme.dart';
import '../../../request/domain/entities/help_request_entity.dart';
import '../../../../widgets/haptic_buttons.dart';

class OpportunityCard extends StatefulWidget {
  final HelpRequestEntity request;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const OpportunityCard({
    super.key, 
    required this.request,
    this.width,
    this.margin,
  });

  @override
  State<OpportunityCard> createState() => _OpportunityCardState();
}

class _OpportunityCardState extends State<OpportunityCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final int matchPercentage = (widget.request.aiRelevanceScore * 100).toInt();

    return Padding(
      padding: widget.margin ?? const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: AppHaptic(
        onTap: () => context.push('/request/${widget.request.id}'),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              clipBehavior: Clip.none, // Allow aura to bleed out naturally
              children: [
                // 1. Animated Aura Background (Glow)
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),

                // 2. Animated Iridescent Border
                Container(
                  width: widget.width,
                  padding: const EdgeInsets.all(1.5), // Border width
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: SweepGradient(
                      center: Alignment.center,
                      startAngle: 0.0,
                      endAngle: 3.14 * 2,
                      transform: GradientRotation(_rotationAnimation.value * 3.14 * 2),
                      colors: const [
                        AppColors.primaryLight,
                        Color(0xFF6248FF),
                        Color(0xFF8E7CFF),
                        AppColors.primaryLight,
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22.5),
                    child: Stack(
                      children: [
                        // 3. Glass Surface
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark 
                                  ? Colors.black.withValues(alpha: 0.7) 
                                  : Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(22.5),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withValues(alpha: 0.15),
                                  Colors.white.withValues(alpha: 0.05),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min, // For Discover carousel
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildMatchBadge(context, matchPercentage),
                                    const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'TRUE AI: TOP MATCH',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.request.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1, // Fixed line count for carousel consistency
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.request.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                                  ),
                                  maxLines: 1, // Fixed line count for carousel consistency
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(1.5),
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [AppColors.primaryLight, Color(0xFF6248FF)],
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundImage: widget.request.requesterAvatarUrl.isNotEmpty 
                                            ? NetworkImage(widget.request.requesterAvatarUrl) 
                                            : null,
                                        child: widget.request.requesterAvatarUrl.isEmpty 
                                            ? const Icon(Icons.person, size: 12) 
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.request.requesterName,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Row(
                                        children: [
                                          Text(
                                            'Action',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        // 4. Subtle Shimmer Effect Overlay
                        Positioned.fill(
                          child: FractionalTranslation(
                            translation: Offset(_controller.value * 2 - 1, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.0),
                                    Colors.white.withValues(alpha: 0.05),
                                    Colors.white.withValues(alpha: 0.0),
                                  ],
                                  stops: const [0.3, 0.5, 0.7],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMatchBadge(BuildContext context, int percentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            '$percentage% MATCH',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
