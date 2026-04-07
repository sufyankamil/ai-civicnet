import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/haptic_buttons.dart';

class VpnWarningBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const VpnWarningBanner({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
              ? [Colors.orange.withValues(alpha: 0.15), Colors.orange.withValues(alpha: 0.05)]
              : [Colors.orange.withValues(alpha: 0.1), Colors.orange.withValues(alpha: 0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.vignette_rounded, // Using vignette as a proxy for VPN/Shield if no better one
              color: Colors.orange, 
              size: 20
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.vpnWarningTitle, 
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 14, 
                    color: Colors.orange
                  )
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.vpnWarningDesc, 
                  style: TextStyle(
                    fontSize: 12, 
                    height: 1.4,
                    color: isDark ? Colors.grey[300] : Colors.grey[800]
                  )
                ),
              ],
            ),
          ),
          AppHaptic(
            onTap: onDismiss,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded, 
                size: 16, 
                color: isDark ? Colors.grey[400] : Colors.grey[600]
              ),
            ),
          ),
        ],
      ),
    );
  }
}
