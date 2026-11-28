import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A button that must be held down to confirm, so an SOS is never sent by an
/// accidental tap. Screen-reader users get a long-press action instead, since
/// holding is not possible with assistive touch.
class HoldToConfirmButton extends StatefulWidget {
  const HoldToConfirmButton({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.holdDuration = const Duration(seconds: 2),
    this.enabled = true,
  });

  final String label;
  final VoidCallback onConfirmed;
  final Duration holdDuration;
  final bool enabled;

  @override
  State<HoldToConfirmButton> createState() => _HoldToConfirmButtonState();
}

class _HoldToConfirmButtonState extends State<HoldToConfirmButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.holdDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) _confirm();
          });
  }

  void _confirm() {
    if (_fired || !widget.enabled) return;
    _fired = true;
    HapticFeedback.heavyImpact();
    widget.onConfirmed();
  }

  void _start() {
    if (!widget.enabled) return;
    _fired = false;
    HapticFeedback.selectionClick();
    _controller.forward(from: 0);
  }

  void _cancel() {
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const base = Color(0xFFC62828);
    return Semantics(
      button: true,
      label: widget.label,
      enabled: widget.enabled,
      onLongPress: widget.enabled ? _confirm : null,
      excludeSemantics: true,
      // A Listener reacts at once; a GestureDetector waits to see if the touch
      // is a tap, which would delay the start of the hold.
      child: Listener(
        onPointerDown: (_) => _start(),
        onPointerUp: (_) => _cancel(),
        onPointerCancel: (_) => _cancel(),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 64,
                width: double.infinity,
                color: widget.enabled ? base : base.withValues(alpha: 0.4),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _controller.value,
                        child: Container(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                    ),
                    Text(
                      widget.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
