import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../widgets/haptic_buttons.dart';

/// Round red SOS button on the Home screen, the mirror of the Aura orb. It only
/// opens the SOS page (`/sos`); nothing is sent until the user holds the
/// confirm button there. Home never imports the SOS feature, only its route.
class SosFloatingButton extends StatelessWidget {
  const SosFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l10n.sosTooltip,
      excludeSemantics: true,
      child: Tooltip(
        message: l10n.sosTooltip,
        child: AppHaptic(
          onTap: () => context.push('/sos'),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red[700],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
