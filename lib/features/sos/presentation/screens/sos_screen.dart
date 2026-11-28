import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../viewmodels/sos_viewmodel.dart';
import 'sos_sheet.dart';
import 'sos_waiting_screen.dart';

/// The one SOS page (`/sos`). Shows the alert form, and switches to the running
/// SOS as soon as one starts. If an SOS is already running when it opens, it
/// shows that instead. After it ends, the "ended" page stays until the user
/// leaves, so closing and reopening never shows a stale result.
class SosScreen extends StatefulWidget {
  const SosScreen({super.key, this.countryCode});

  /// Overrides the device region (used in tests).
  final String? countryCode;

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  late final SosViewModel _vm = Get.find<SosViewModel>();
  late bool _running = _vm.isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sosTooltip),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (_vm.isActive) _running = true;
          // Reading the status makes this rebuild when it changes.
          _vm.status.value;
          if (_running) {
            return SosWaitingScreenBody(countryCode: widget.countryCode);
          }
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SosSheet(countryCode: widget.countryCode),
          );
        }),
      ),
    );
  }
}
