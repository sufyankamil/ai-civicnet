import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A flat wrapper to add light haptic feedback to ANY widget.
/// Best used for custom list tiles or icons that don't use standard buttons.
class AppHaptic extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const AppHaptic({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap == null ? null : () {
        HapticFeedback.lightImpact();
        onTap!();
      },
      borderRadius: borderRadius,
      child: child,
    );
  }
}

/// Centralized haptic-enabled ElevatedButton
class AppElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const AppElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed == null ? null : () {
        HapticFeedback.lightImpact();
        onPressed!();
      },
      style: style,
      child: child,
    );
  }
}

/// Centralized haptic-enabled IconButton
class AppIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final String? tooltip;
  final Color? color;

  const AppIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed == null ? null : () {
        HapticFeedback.lightImpact();
        onPressed!();
      },
      icon: icon,
      tooltip: tooltip,
      color: color,
    );
  }
}

/// Centralized haptic-enabled TextButton
class AppTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const AppTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed == null ? null : () {
        HapticFeedback.lightImpact();
        onPressed!();
      },
      style: style,
      child: child,
    );
  }
}

/// Centralized haptic-enabled FloatingActionButton
class AppFloatingActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final Color? backgroundColor;

  const AppFloatingActionButton.extended({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed == null ? null : () {
        HapticFeedback.lightImpact();
        onPressed!();
      },
      icon: icon,
      label: label,
      backgroundColor: backgroundColor,
    );
  }
}
