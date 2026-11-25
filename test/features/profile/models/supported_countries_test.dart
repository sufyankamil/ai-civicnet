import 'package:civic_net/features/profile/models/supported_countries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final codes = supportedCountries.map((c) => c.code).toList();

  test('keeps the original countries', () {
    expect(codes, containsAll(['IN', 'US', 'GB', 'CA', 'AU']));
  });

  test('offers every GCC country', () {
    expect(codes, containsAll(['AE', 'SA', 'QA', 'KW', 'BH', 'OM']));
  });

  test('uses the right display names for the GCC countries', () {
    String name(String code) =>
        supportedCountries.firstWhere((c) => c.code == code).name;

    expect(name('AE'), 'United Arab Emirates');
    expect(name('SA'), 'Saudi Arabia');
    expect(name('QA'), 'Qatar');
    expect(name('KW'), 'Kuwait');
    expect(name('BH'), 'Bahrain');
    expect(name('OM'), 'Oman');
  });

  test('codes match the database constraint and are unique', () {
    final format = RegExp(r'^[A-Z]{2}$'); // profiles_country_code_format
    expect(codes.every(format.hasMatch), isTrue);
    expect(codes.toSet().length, codes.length);
  });

  test('names are present and unique', () {
    final names = supportedCountries.map((c) => c.name).toList();
    expect(names.every((n) => n.trim().isNotEmpty), isTrue);
    expect(names.toSet().length, names.length);
  });

  test('dropdown items mirror the list, in order', () {
    final items = countryDropdownItems();

    expect(items.map((i) => i.value).toList(), codes);
  });
}
