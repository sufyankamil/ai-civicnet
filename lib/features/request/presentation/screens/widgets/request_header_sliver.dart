import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/help_request_entity.dart';
import '../../../../../theme/app_theme.dart';

class RequestHeaderSliver extends StatelessWidget {
  final HelpRequestEntity request;
  final String? currentUserId;
  final VoidCallback onReport;
  final VoidCallback onDelete;

  const RequestHeaderSliver({
    super.key,
    required this.request,
    required this.currentUserId,
    required this.onReport,
    required this.onDelete,
  });

  Widget _buildGlassIconButton(BuildContext context, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color bgColor = isDark 
        ? Colors.black.withValues(alpha: 0.4) 
        : Colors.white.withValues(alpha: 0.85);
    
    final Color iconColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: IconButton(
            icon: Icon(icon, color: iconColor, size: 20),
            onPressed: onTap,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: _buildGlassIconButton(context, Icons.arrow_back_rounded, () => context.pop()),
      actions: [
        if (currentUserId != null && currentUserId != request.requesterId)
          _buildGlassIconButton(context, Icons.flag_outlined, onReport),
        if (currentUserId != null && currentUserId == request.requesterId)
          _buildGlassIconButton(context, Icons.delete_outline_rounded, onDelete),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: AppColors.primaryDark,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.25,
                    child: Image.network(
                      'https://maps.googleapis.com/maps/api/staticmap?center=${request.lat},${request.lng}&zoom=13&size=600x400&style=feature:all|element:labels|visibility:off&style=feature:road|element:geometry|color:0x444444&style=feature:water|element:geometry|color:0x111111&key=${dotenv.env["GOOGLE_MAPS_API_KEY"]}',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: AppColors.primaryDark),
                    ),
                  ),
                  // Premium Location Pulse
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 1.5),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Container(
                        padding: EdgeInsets.all(12 * value),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.auraGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryLight.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 32),
                    ),
                    onEnd: () {},
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
