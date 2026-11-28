import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/emergency_numbers.dart';
import '../viewmodels/sos_viewmodel.dart';
import 'sos_sheet.dart';

/// The content of the running-SOS screen, separate so it can be tested alone.
class SosWaitingScreenBody extends StatefulWidget {
  const SosWaitingScreenBody({super.key, this.countryCode});

  final String? countryCode;

  @override
  State<SosWaitingScreenBody> createState() => _SosWaitingScreenBodyState();
}

class _SosWaitingScreenBodyState extends State<SosWaitingScreenBody> {
  late final SosViewModel _vm = Get.find<SosViewModel>();
  Timer? _timer;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    if (widget.countryCode == null) _vm.refreshEmergencyNumber();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _ticks++;
      // Helpers are alerted a moment after the SOS is created, so look again.
      if (_ticks % 10 == 0 && _vm.isActive) _vm.reload();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status = _vm.status.value;
      return _vm.isActive && status != null
          ? _active(context, status.id)
          : _ended(context);
    });
  }

  Widget _active(BuildContext context, int id) {
    final l10n = AppLocalizations.of(context)!;
    final live = _vm.emergencyNumber.value;
    final number = widget.countryCode != null
        ? emergencyNumberFor(widget.countryCode)
        : live;
    final count = _vm.status.value?.alertCount;
    final minutes = _vm.remaining.inMinutes;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(Icons.sos_rounded, size: 72, color: Colors.red[700]),
        const SizedBox(height: 12),
        Text(
          l10n.sosActiveTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          count == null ? l10n.sosAlerting : l10n.sosAlertedCount(count),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.sosMinutesLeft(minutes),
          textAlign: TextAlign.center,
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          icon: const Icon(Icons.call_rounded),
          label: Text(l10n.sosCallNumber(number)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            foregroundColor: Colors.red[800],
            side: BorderSide(color: Colors.red.shade800),
          ),
          onPressed: () => launchUrl(Uri(scheme: 'tel', path: number)),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => context.push('/request/$id'),
          child: Text(l10n.sosSeeHelpers),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: _vm.endSos,
          child: Text(l10n.sosImSafe),
        ),
        Obx(() {
          final type = _vm.error.value;
          if (type == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              sosErrorText(l10n, type),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _ended(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(Icons.check_circle_rounded, size: 72, color: Colors.green[700]),
        const SizedBox(height: 12),
        Text(
          l10n.sosEndedTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(l10n.sosEndedBody, textAlign: TextAlign.center),
        const SizedBox(height: 28),
        FilledButton(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
          child: Text(l10n.sosDone),
        ),
      ],
    );
  }
}
