import 'package:civic_net/features/sos/data/sos_remote_data_source.dart';
import 'package:civic_net/features/sos/domain/sos_failure.dart';
import 'package:civic_net/features/sos/domain/sos_models.dart';
import 'package:civic_net/features/sos/presentation/viewmodels/sos_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSosDataSource implements SosRemoteDataSource {
  final created = <Map<String, Object?>>[];
  final ended = <int>[];
  Object? createError;
  Object? endError;
  Object? statusError;
  int nextId = 42;
  SosStatus? statusToReturn;

  @override
  Future<int> createSos({
    required double lat,
    required double lng,
    String? note,
  }) async {
    if (createError != null) throw createError!;
    created.add({'lat': lat, 'lng': lng, 'note': note});
    return nextId;
  }

  @override
  Future<void> endSos(int id) async {
    if (endError != null) throw endError!;
    ended.add(id);
  }

  @override
  Future<SosStatus> getStatus(int id) async {
    if (statusError != null) throw statusError!;
    return statusToReturn!;
  }
}

void main() {
  late FakeSosDataSource data;
  late DateTime now;
  late SosPosition? position;
  late SosViewModel vm;

  setUp(() {
    data = FakeSosDataSource();
    now = DateTime.utc(2026, 12, 1, 12);
    position = const SosPosition(19.076012, 72.877698);
    data.statusToReturn = SosStatus(
      id: 42,
      alertCount: null,
      expiresAt: now.add(const Duration(minutes: 60)),
      closed: false,
    );
    vm = SosViewModel(
      dataSource: data,
      position: () async => position,
      now: () => now,
    );
  });

  test(
    'starting sends the exact position and note and becomes active',
    () async {
      await vm.start(note: 'stuck in lift');

      expect(data.created, [
        {'lat': 19.076012, 'lng': 72.877698, 'note': 'stuck in lift'},
      ]);
      expect(vm.status.value?.id, 42);
      expect(vm.isActive, isTrue);
      expect(vm.error.value, isNull);
      expect(vm.isSending.value, isFalse);
    },
  );

  test('without a position it does not send anything', () async {
    position = null;
    await vm.start();

    expect(data.created, isEmpty);
    expect(vm.error.value, SosFailureType.locationUnavailable);
    expect(vm.isActive, isFalse);
    expect(vm.isSending.value, isFalse);
  });

  test('a server limit is reported and nothing becomes active', () async {
    data.createError = const SosFailure(SosFailureType.rateLimited);
    await vm.start();

    expect(vm.error.value, SosFailureType.rateLimited);
    expect(vm.status.value, isNull);
  });

  test('an unexpected error becomes a network error', () async {
    data.createError = Exception('offline');
    await vm.start();

    expect(vm.error.value, SosFailureType.network);
  });

  test('a second tap while sending is ignored', () async {
    final first = vm.start();
    final second = vm.start();
    await Future.wait([first, second]);

    expect(data.created, hasLength(1));
  });

  test('still active if the status lookup fails right after sending', () async {
    data.statusError = Exception('slow');
    await vm.start();

    expect(vm.status.value?.id, 42);
    expect(vm.isActive, isTrue);
  });

  test('reload shows how many helpers were alerted', () async {
    await vm.start();
    data.statusToReturn = SosStatus(
      id: 42,
      alertCount: 5,
      expiresAt: now.add(const Duration(minutes: 55)),
      closed: false,
    );
    await vm.reload();

    expect(vm.status.value?.alertCount, 5);
  });

  test('it stops being active once it expires', () async {
    await vm.start();
    now = now.add(const Duration(minutes: 61));

    expect(vm.isActive, isFalse);
    expect(vm.remaining, Duration.zero);
  });

  test('remaining time counts down', () async {
    await vm.start();
    now = now.add(const Duration(minutes: 10));

    expect(vm.remaining, const Duration(minutes: 50));
  });

  test('ending marks the user safe', () async {
    await vm.start();
    await vm.endSos();

    expect(data.ended, [42]);
    expect(vm.isActive, isFalse);
    expect(vm.status.value?.closed, isTrue);
  });

  test('if ending fails it stays active and says so', () async {
    await vm.start();
    data.endError = Exception('offline');
    await vm.endSos();

    expect(vm.isActive, isTrue);
    expect(vm.error.value, SosFailureType.network);
  });

  group('emergency number', () {
    SosViewModel build({String? region, Future<String?> Function()? lookup}) =>
        SosViewModel(
          dataSource: data,
          position: () async => position,
          now: () => now,
          deviceRegion: () => region,
          countryLookup: lookup,
        );

    test('starts from the phone region', () {
      expect(build(region: 'AE').emergencyNumber.value, '999');
      expect(build(region: 'US').emergencyNumber.value, '911');
    });

    test('falls back to 112 with no region', () {
      expect(build(region: null).emergencyNumber.value, '112');
    });

    test('switches to the country of the location when it is known', () async {
      final model = build(region: 'IN', lookup: () async => 'AE');
      expect(model.emergencyNumber.value, '112');

      await model.refreshEmergencyNumber();

      expect(model.emergencyNumber.value, '999');
    });

    test('ignores letter case from the lookup', () async {
      final model = build(region: 'IN', lookup: () async => 'ae');
      await model.refreshEmergencyNumber();

      expect(model.emergencyNumber.value, '999');
    });

    test('keeps the phone region when there is no location', () async {
      final model = build(region: 'GB', lookup: () async => null);
      await model.refreshEmergencyNumber();

      expect(model.emergencyNumber.value, '999');
    });

    test('keeps the phone region when the lookup fails', () async {
      final model = build(
        region: 'US',
        lookup: () async => throw Exception('no network'),
      );
      await model.refreshEmergencyNumber();

      expect(model.emergencyNumber.value, '911');
    });

    test('a slow lookup does not hold things up', () async {
      final model = build(
        region: 'US',
        lookup: () =>
            Future<String?>.delayed(const Duration(seconds: 30), () => 'AE'),
      );
      final watch = Stopwatch()..start();
      await model.refreshEmergencyNumber(
        timeout: const Duration(milliseconds: 50),
      );

      expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
      expect(model.emergencyNumber.value, '911');
    });

    test('looks the country up once, not on every open', () async {
      var calls = 0;
      final model = build(
        region: 'IN',
        lookup: () async {
          calls++;
          return 'AE';
        },
      );
      await model.refreshEmergencyNumber();
      await model.refreshEmergencyNumber();

      expect(calls, 1);
    });
  });
}
