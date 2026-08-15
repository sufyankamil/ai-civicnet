import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/supabase_service.dart';
import '../../../../widgets/haptic_buttons.dart';

class HomeAppBar extends StatelessWidget {
  final bool showRegionalUpdateReminder;
  final VoidCallback? onRegionalUpdateReminderTap;
  final bool showStoreUpdateReminder;
  final VoidCallback? onStoreUpdateReminderTap;

  const HomeAppBar({
    super.key,
    this.showRegionalUpdateReminder = false,
    this.onRegionalUpdateReminderTap,
    this.showStoreUpdateReminder = false,
    this.onStoreUpdateReminderTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 108,
      floating: false,
      pinned: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      forceMaterialTransparency: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Purple radial glow anchored to the header / profile side
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.85, -0.2),
                    radius: 1.05,
                    colors: [
                      AppColors.primaryLight.withValues(alpha: isDark ? 0.28 : 0.22),
                      AppColors.primaryLight.withValues(alpha: isDark ? 0.10 : 0.10),
                      AppColors.primaryLight.withValues(alpha: isDark ? 0.03 : 0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.35, 0.65, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildHeaderCompact(context, l10n),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCompact(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder(
              future: SupabaseService().getCurrentUserProfile(),
              builder: (context, snapshot) {
                final name = snapshot.data?.name ?? 'Friend';
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Text(
                  'Hey, $name!',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
            Text(l10n.appTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.7)),
            Text(
              l10n.findMatches,
              style: TextStyle(
                fontSize: 12,
                color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                letterSpacing: 0.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderIconButton(context, Icons.history_rounded, () => context.push('/activity')),
            if (showRegionalUpdateReminder) ...[
              const SizedBox(width: 8),
              _HeaderReminder(
                icon: Icons.public_rounded,
                message: 'Add your country for regional updates',
                onTap: onRegionalUpdateReminderTap,
              ),
            ],
            if (showStoreUpdateReminder) ...[
              const SizedBox(width: 8),
              _HeaderReminder(
                icon: Icons.system_update_rounded,
                message: 'Update CivicNet',
                onTap: onStoreUpdateReminderTap,
              ),
            ],
            const SizedBox(width: 12),
            _buildProfileAvatar(context),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderIconButton(BuildContext context, IconData icon, VoidCallback onTap, {bool isClose = false}) {
     return AppHaptic(
       onTap: onTap,
       child: Container(
         padding: const EdgeInsets.all(10),
         decoration: BoxDecoration(
           color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black).withValues(alpha: isClose ? 0.1 : 0.05),
           shape: BoxShape.circle,
         ),
         child: Icon(
           icon, 
           size: isClose ? 18 : 22, 
           color: isClose 
               ? (Theme.of(context).brightness == Brightness.dark ? Colors.grey[400] : Colors.grey[700]) 
               : Colors.grey[600]
         ),
       ),
     );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return FutureBuilder(
      future: SupabaseService().getCurrentUserProfile(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final hasAvatar = user?.avatarUrl != null && user!.avatarUrl.isNotEmpty;
        return AppHaptic(
          onTap: () => context.go('/profile'),
          child: Hero(
            tag: 'profile-avatar',
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(gradient: AppColors.auraGradient, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[200],
                backgroundImage: hasAvatar ? CachedNetworkImageProvider(user.avatarUrl) : null,
                child: hasAvatar ? null : const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeaderReminder extends StatefulWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final String message;

  const _HeaderReminder({
    required this.icon,
    required this.message,
    this.onTap,
  });

  @override
  State<_HeaderReminder> createState() => _HeaderReminderState();
}

class _HeaderReminderState extends State<_HeaderReminder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1.08).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: AppHaptic(
        onTap: widget.onTap ?? () {},
        child: Tooltip(
          message: widget.message,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
