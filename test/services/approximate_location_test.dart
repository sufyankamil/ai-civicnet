import 'package:civic_net/services/approximate_location.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  final calls = <String>[];
  late LocationPermission permission;
  late DeviceLocation? lastKnown;
  late Object? freshError;
  late DeviceLocation? fresh;

  setUp(() {
    calls.clear();
    permission = LocationPermission.whileInUse;
    lastKnown = null;
    fresh = null;
    freshError = null;
  });

  Future<DeviceLocation?> run() => approximateDeviceLocation(
    checkPermission: () async {
      calls.add('permission');
      return permission;
    },
    lastKnown: () async {
      calls.add('lastKnown');
      return lastKnown;
    },
    freshFix: (timeout) async {
      calls.add('freshFix');
      if (freshError != null) throw freshError!;
      return fresh;
    },
  );

  test('never asks for a position without permission', () async {
    permission = LocationPermission.denied;
    expect(await run(), isNull);
    permission = LocationPermission.deniedForever;
    expect(await run(), isNull);

    expect(calls.where((c) => c != 'permission'), isEmpty);
  });

  test('uses the last known position when there is one', () async {
    lastKnown = const DeviceLocation(19.07, 72.87);
    final result = await run();

    expect(result?.lat, 19.07);
    expect(calls, ['permission', 'lastKnown']);
  });

  test('takes one low-accuracy fix when nothing is known yet', () async {
    fresh = const DeviceLocation(19.08, 72.88);
    final result = await run();

    expect(result?.lng, 72.88);
    expect(calls, ['permission', 'lastKnown', 'freshFix']);
  });

  test('works with "always" permission too', () async {
    permission = LocationPermission.always;
    fresh = const DeviceLocation(1, 2);

    expect((await run())?.lat, 1);
  });

  test('a failed or timed-out fix is just null', () async {
    freshError = Exception('timeout');
    expect(await run(), isNull);
  });

  test('no last known position and no fix is null', () async {
    expect(await run(), isNull);
  });

  test(
    'an error reading the last known position still tries a fresh fix',
    () async {
      fresh = const DeviceLocation(5, 6);
      final result = await approximateDeviceLocation(
        checkPermission: () async => LocationPermission.whileInUse,
        lastKnown: () async => throw UnsupportedError('web'),
        freshFix: (_) async => fresh,
      );

      expect(result?.lat, 5);
    },
  );
}
