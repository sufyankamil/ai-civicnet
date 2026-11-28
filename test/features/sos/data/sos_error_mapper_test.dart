import 'package:civic_net/features/sos/data/sos_error_mapper.dart';
import 'package:civic_net/features/sos/domain/sos_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  SosFailureType typeOf(Object e) => mapSosError(e).type;

  test('maps the server limit errors', () {
    expect(
      typeOf(
        const PostgrestException(message: 'sos_rate_limited', code: 'P0001'),
      ),
      SosFailureType.rateLimited,
    );
    expect(
      typeOf(
        const PostgrestException(message: 'sos_daily_limit', code: 'P0001'),
      ),
      SosFailureType.dailyLimit,
    );
    expect(
      typeOf(
        const PostgrestException(message: 'sos_already_active', code: 'P0001'),
      ),
      SosFailureType.alreadyActive,
    );
  });

  test('maps an unauthenticated call', () {
    expect(
      typeOf(
        const PostgrestException(message: 'not authenticated', code: '28000'),
      ),
      SosFailureType.notSignedIn,
    );
  });

  test('anything else is a network problem', () {
    expect(typeOf(Exception('socket closed')), SosFailureType.network);
    expect(
      typeOf(const PostgrestException(message: 'boom', code: '500')),
      SosFailureType.network,
    );
  });

  test('keeps an existing SosFailure as it is', () {
    const failure = SosFailure(SosFailureType.locationUnavailable);
    expect(identical(mapSosError(failure), failure), isTrue);
  });
}
