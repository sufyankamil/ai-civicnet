import 'package:civic_net/services/device_token_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeBackend implements DeviceTokenBackend {
  final registered = <Map<String, Object?>>[];
  final unregistered = <String>[];
  Object? registerError;

  @override
  Future<void> register({
    required String token,
    required String platform,
    double? lat,
    double? lng,
  }) async {
    if (registerError != null) throw registerError!;
    registered.add({
      'token': token,
      'platform': platform,
      'lat': lat,
      'lng': lng,
    });
  }

  @override
  Future<void> unregister(String token) async => unregistered.add(token);
}

const mumbai = DeviceLocation(19.0760, 72.8777);
// About 300 m north of [mumbai].
const nearby = DeviceLocation(19.0787, 72.8777);
// About 2.2 km north of [mumbai].
const farAway = DeviceLocation(19.0960, 72.8777);

void main() {
  late FakeBackend backend;
  late DateTime now;
  late DeviceLocation? location;
  late DeviceTokenService service;

  setUp(() {
    backend = FakeBackend();
    now = DateTime.utc(2026, 12, 1, 9);
    location = mumbai;
    service = DeviceTokenService(
      backend: backend,
      platform: 'ios',
      location: () async => location,
      now: () => now,
    );
  });

  test(
    'registers the token with platform and location when signed in',
    () async {
      await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);

      expect(backend.registered, [
        {
          'token': 'token-aaaaaaaaaaaaaaaaaaaa',
          'platform': 'ios',
          'lat': 19.0760,
          'lng': 72.8777,
        },
      ]);
    },
  );

  test('does nothing when signed out or without a token', () async {
    await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: false);
    await service.sync(token: null, signedIn: true);
    await service.sync(token: '', signedIn: true);

    expect(backend.registered, isEmpty);
  });

  test('still registers when no location is available', () async {
    location = null;
    await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);

    expect(backend.registered.single['lat'], isNull);
    expect(backend.registered.single['lng'], isNull);
  });

  test(
    'skips a repeat within 6 hours when the user has not moved far',
    () async {
      await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);
      now = now.add(const Duration(hours: 5));
      location = nearby;
      await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);

      expect(backend.registered, hasLength(1));
    },
  );

  test('registers again after moving more than 500 m', () async {
    await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);
    now = now.add(const Duration(minutes: 10));
    location = farAway;
    await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);

    expect(backend.registered, hasLength(2));
    expect(backend.registered.last['lat'], 19.0960);
  });

  test('registers again after 6 hours', () async {
    await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);
    now = now.add(const Duration(hours: 6, minutes: 1));
    await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);

    expect(backend.registered, hasLength(2));
  });

  test('registers a refreshed token right away', () async {
    await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);
    await service.sync(token: 'token-bbbbbbbbbbbbbbbbbbbb', signedIn: true);

    expect(backend.registered.map((r) => r['token']), [
      'token-aaaaaaaaaaaaaaaaaaaa',
      'token-bbbbbbbbbbbbbbbbbbbb',
    ]);
  });

  test('a backend failure never throws and is retried next time', () async {
    backend.registerError = Exception('offline');
    await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);
    expect(backend.registered, isEmpty);

    backend.registerError = null;
    await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);
    expect(backend.registered, hasLength(1));
  });

  test('signing out removes the token so it stops getting pushes', () async {
    await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);
    await service.onSignedOut();

    expect(backend.unregistered, ['token-aaaaaaaaaaaaaaaaaaaa']);

    await service.sync(token: 'token-aaaaaaaaaaaaaaaaaaaa', signedIn: true);
    expect(backend.registered, hasLength(2));
  });

  test('signing out without a registered token does nothing', () async {
    await service.onSignedOut();
    expect(backend.unregistered, isEmpty);
  });
}
