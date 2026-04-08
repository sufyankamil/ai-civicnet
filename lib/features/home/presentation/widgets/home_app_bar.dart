import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../services/supabase_service.dart';
import '../../../../widgets/haptic_buttons.dart';

class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 108,
      floating: false,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _buildHeaderCompact(context, l10n),
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
