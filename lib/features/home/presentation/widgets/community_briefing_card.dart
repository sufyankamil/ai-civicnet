import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../theme/app_theme.dart';

class CommunityBriefingCard extends StatefulWidget {
  final String briefing;
  final bool isLoading;
  final VoidCallback onRefresh;

  const CommunityBriefingCard({
    super.key,
    required this.briefing,
    this.isLoading = false,
    required this.onRefresh,
  });

  @override
  State<CommunityBriefingCard> createState() => _CommunityBriefingCardState();
}

class _CommunityBriefingCardState extends State<CommunityBriefingCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glowAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF1E293B).withValues(alpha: 0.98), const Color(0xFF0F172A).withValues(alpha: 0.98)]
                : [Colors.white.withValues(alpha: 0.98), const Color(0xFFF1F5F9).withValues(alpha: 0.98)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            width: 1.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            onTap: () {
              // Only toggle if not loading
              if (!widget.isLoading) {
                setState(() => _isExpanded = !_isExpanded);
              }
            },
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: widget.isLoading 
                  ? _buildShimmer(isDark)
                  : _buildContent(context, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    if (widget.briefing.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryLight.withValues(alpha: 0.2),
                          blurRadius: _glowAnimation.value,
                          spreadRadius: _glowAnimation.value / 2,
                        ),
                      ],
                    ),
                    child: child,
                  );
                },
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLight, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DAILY BRIEFING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    Text(
                      'AI Scribe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              // Improved hit target for refresh button
              Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: widget.onRefresh,
                  tooltip: 'Refresh Briefing',
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.grey),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          widget.briefing.contains(' neighborhood is bustling') // Detection for local fallback
              ? _buildBriefingFallback(isDark)
              : _isExpanded 
                  ? _buildBriefingText(isDark)
                  : _buildBriefingPreview(isDark),
          const SizedBox(height: 8),
          Center(
            child: Icon(
              _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
              color: Colors.grey.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBriefingFallback(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.briefing,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: widget.onRefresh,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Try Refreshing AI Scribe'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.1),
            foregroundColor: AppColors.primaryLight,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildBriefingPreview(bool isDark) {
    if (widget.briefing.isEmpty) return const SizedBox.shrink();
    
    final firstParagraph = widget.briefing.split('\n\n').first;
    return Text(
      firstParagraph,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        height: 1.5,
        color: isDark ? Colors.white70 : Colors.black87,
        fontFamily: 'Georgia', // Magazine feel
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildBriefingText(bool isDark) {
    final paragraphs = widget.briefing.trim().split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((p) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          p,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.grey[200]!,
      highlightColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 80, height: 10, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(width: 120, height: 14, color: Colors.white),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 60, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
