import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:get/get.dart';

import '../../data/sos_error_mapper.dart';
import '../../data/sos_remote_data_source.dart';
import '../../data/sos_country_lookup.dart';
import '../../domain/emergency_numbers.dart';
import '../../domain/sos_failure.dart';
import '../../domain/sos_models.dart';

class SosViewModel extends GetxController {
  SosViewModel({
    required SosRemoteDataSource dataSource,
    required Future<SosPosition?> Function() position,
    DateTime Function()? now,
    String? Function()? deviceRegion,
    Future<String?> Function()? countryLookup,
  }) : _dataSource = dataSource,
       _position = position,
       _now = now ?? DateTime.now,
       _deviceRegion =
           deviceRegion ??
           (() => PlatformDispatcher.instance.locale.countryCode),
       _countryLookup = countryLookup ?? countryFromLastKnownLocation {
    emergencyNumber.value = emergencyNumberFor(_deviceRegion());
  }

  /// How long an SOS lasts, matching the server (`sos_expires_at`).
  static const Duration lifetime = Duration(minutes: 60);

  final SosRemoteDataSource _dataSource;
  final Future<SosPosition?> Function() _position;
  final String? Function() _deviceRegion;
  final Future<String?> Function() _countryLookup;
  bool _countryChecked = false;
  final DateTime Function() _now;

  final status = Rxn<SosStatus>();
  final isSending = false.obs;
  final error = Rxn<SosFailureType>();

  /// The number the Call button dials. Starts from the phone's region and
  /// switches to the country of the user's location once that is known.
  final emergencyNumber = '112'.obs;

  bool get isActive {
    final s = status.value;
    return s != null && !s.closed && _now().isBefore(s.expiresAt);
  }

  Duration get remaining {
    final s = status.value;
    if (s == null || !isActive) return Duration.zero;
    return s.expiresAt.difference(_now());
  }

  /// Looks up the country of the device's last known location, once, and uses
  /// its emergency number. Any failure or delay keeps the phone-region number.
  Future<void> refreshEmergencyNumber({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (_countryChecked) return;
    _countryChecked = true;
    try {
      final country = await _countryLookup().timeout(timeout);
      if (country != null && country.isNotEmpty) {
        emergencyNumber.value = emergencyNumberFor(country);
      }
    } catch (_) {
      // Keep the number from the phone's region.
    }
  }

  Future<void> start({String? note}) async {
    if (isSending.value || isActive) return;
    isSending.value = true;
    error.value = null;
    try {
      final here = await _position();
      if (here == null) {
        error.value = SosFailureType.locationUnavailable;
        return;
      }
      final id = await _dataSource.createSos(
        lat: here.lat,
        lng: here.lng,
        note: note,
      );
      try {
        status.value = await _dataSource.getStatus(id);
      } catch (_) {
        // The SOS exists; the details can be read on the next refresh.
        status.value = SosStatus(
          id: id,
          alertCount: null,
          expiresAt: _now().add(lifetime),
          closed: false,
        );
      }
    } catch (e) {
      error.value = mapSosError(e).type;
    } finally {
      isSending.value = false;
    }
  }

  /// Re-reads the SOS, for example to show how many helpers were alerted.
  Future<void> reload() async {
    final s = status.value;
    if (s == null) return;
    try {
      status.value = await _dataSource.getStatus(s.id);
    } catch (_) {
      // Keep showing what we have.
    }
  }

  /// The user is safe, or cancels the alert.
  Future<void> endSos() async {
    final s = status.value;
    if (s == null) return;
    error.value = null;
    try {
      await _dataSource.endSos(s.id);
      status.value = s.copyWith(closed: true);
    } catch (e) {
      error.value = mapSosError(e).type;
    }
  }
}
