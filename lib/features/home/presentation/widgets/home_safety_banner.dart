import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/haptic_buttons.dart';

class HomeSafetyBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const HomeSafetyBanner({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentLight.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_rounded, color: AppColors.accentLight, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.communityCommitment, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accentLight)),
                const SizedBox(height: 4),
                Text(l10n.safetyDescription, style: const TextStyle(fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          _buildHeaderIconButton(context, Icons.close_rounded, onDismiss, isClose: true),
        ],
      ),
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
}
