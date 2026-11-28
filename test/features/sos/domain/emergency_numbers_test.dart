import 'package:civic_net/features/sos/domain/emergency_numbers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gives the national number for the user\'s region', () {
    expect(emergencyNumberFor('IN'), '112');
    expect(emergencyNumberFor('AE'), '999');
    expect(emergencyNumberFor('SA'), '911');
    expect(emergencyNumberFor('GB'), '999');
    expect(emergencyNumberFor('US'), '911');
    expect(emergencyNumberFor('AU'), '000');
  });

  test('ignores letter case', () {
    expect(emergencyNumberFor('ae'), '999');
  });

  test('falls back to 112 for unknown or missing regions', () {
    expect(emergencyNumberFor(null), '112');
    expect(emergencyNumberFor(''), '112');
    expect(emergencyNumberFor('ZZ'), '112');
  });
}
