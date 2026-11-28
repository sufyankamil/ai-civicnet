import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/emergency_numbers.dart';
import '../../domain/sos_failure.dart';
import '../viewmodels/sos_viewmodel.dart';
import '../widgets/hold_to_confirm_button.dart';

/// The region used for the emergency number, from the device settings.
String? deviceCountryCode() =>
    WidgetsBinding.instance.platformDispatcher.locale.countryCode;

String sosErrorText(AppLocalizations l10n, SosFailureType type) =>
    switch (type) {
      SosFailureType.rateLimited => l10n.sosErrorRateLimited,
      SosFailureType.dailyLimit => l10n.sosErrorDailyLimit,
      SosFailureType.alreadyActive => l10n.sosErrorAlreadyActive,
      SosFailureType.notSignedIn => l10n.sosErrorNotSignedIn,
      SosFailureType.locationUnavailable => l10n.sosErrorLocation,
      SosFailureType.network => l10n.sosErrorNetwork,
    };

class SosSheet extends StatefulWidget {
  const SosSheet({super.key, this.countryCode, this.onStarted});

  /// Overrides the device region (used in tests).
  final String? countryCode;
  final VoidCallback? onStarted;

  @override
  State<SosSheet> createState() => _SosSheetState();
}

class _SosSheetState extends State<SosSheet> {
  final _note = TextEditingController();
  late final SosViewModel _vm = Get.find<SosViewModel>();

  @override
  void initState() {
    super.initState();
    if (widget.countryCode == null) _vm.refreshEmergencyNumber();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// A fixed region (tests) wins; otherwise the number follows the location.
  /// Always reads the observable so an Obx around it is valid either way.
  String get _numberToShow {
    final live = _vm.emergencyNumber.value;
    return widget.countryCode != null
        ? emergencyNumberFor(widget.countryCode)
        : live;
  }

  Future<void> _send() async {
    final note = _note.text.trim();
    await _vm.start(note: note.isEmpty ? null : note);
    if (_vm.isActive) widget.onStarted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.sosSheetTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Text(l10n.sosCallFirst),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.call_rounded),
              label: Obx(() => Text(l10n.sosCallNumber(_numberToShow))),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                foregroundColor: Colors.red[800],
                side: BorderSide(color: Colors.red.shade800),
              ),
              onPressed: () =>
                  launchUrl(Uri(scheme: 'tel', path: _numberToShow)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.sosDisclaimer,
            style: TextStyle(fontSize: 12, color: secondary),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _note,
            maxLength: 140,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.sosNoteLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => HoldToConfirmButton(
              label: _vm.isSending.value ? l10n.sosSending : l10n.sosHoldLabel,
              enabled: !_vm.isSending.value,
              onConfirmed: () {
                HapticFeedback.heavyImpact();
                _send();
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.sosHoldHint,
            style: TextStyle(fontSize: 12, color: secondary),
          ),
          Obx(() {
            final type = _vm.error.value;
            if (type == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                sosErrorText(l10n, type),
                style: TextStyle(
                  color: Colors.red[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
