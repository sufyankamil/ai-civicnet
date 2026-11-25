import 'dart:io';

import 'package:civic_net/features/home/models/seasonal_greeting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('seasonalGreetingFor', () {
    test('finds the UAE National Day greeting for the UAE', () {
      final greeting = seasonalGreetingFor('AE', DateTime(2026, 12, 2));
      expect(greeting?.id, 'uae_national_day');
    });

    test('finds UAE Flag Day on Nov 3', () {
      expect(
        seasonalGreetingFor('AE', DateTime(2026, 11, 3))?.id,
        'uae_flag_day',
      );
    });

    test('keeps India Independence Day', () {
      final greeting = seasonalGreetingFor('IN', DateTime(2026, 8, 15));
      expect(greeting?.id, 'independence_day');
      expect(greeting?.flag, '🇮🇳');
    });

    test('covers every GCC country on its holiday', () {
      expect(
        seasonalGreetingFor('SA', DateTime(2026, 9, 23))?.id,
        'saudi_national_day',
      );
      expect(
        seasonalGreetingFor('SA', DateTime(2026, 2, 22))?.id,
        'saudi_founding_day',
      );
      expect(
        seasonalGreetingFor('QA', DateTime(2026, 12, 18))?.id,
        'qatar_national_day',
      );
      expect(
        seasonalGreetingFor('KW', DateTime(2026, 2, 25))?.id,
        'kuwait_national_day',
      );
      expect(
        seasonalGreetingFor('KW', DateTime(2026, 2, 26))?.id,
        'kuwait_liberation_day',
      );
      expect(
        seasonalGreetingFor('BH', DateTime(2026, 12, 16))?.id,
        'bahrain_national_day',
      );
      expect(
        seasonalGreetingFor('OM', DateTime(2026, 11, 18))?.id,
        'oman_national_day',
      );
    });

    test('is not case sensitive', () {
      expect(
        seasonalGreetingFor('ae', DateTime(2026, 12, 2))?.id,
        'uae_national_day',
      );
    });

    test('returns nothing for another country on that day', () {
      expect(seasonalGreetingFor('SA', DateTime(2026, 12, 2)), isNull);
      expect(seasonalGreetingFor('IN', DateTime(2026, 12, 2)), isNull);
    });

    test('returns nothing without a country', () {
      expect(seasonalGreetingFor(null, DateTime(2026, 12, 2)), isNull);
      expect(seasonalGreetingFor('', DateTime(2026, 12, 2)), isNull);
    });

    test('returns nothing on an ordinary day', () {
      expect(seasonalGreetingFor('AE', DateTime(2026, 6, 10)), isNull);
    });
  });

  group('seasonalGreetingsOn', () {
    test('lists the greetings that fall on a date', () {
      expect(seasonalGreetingsOn(DateTime(2026, 12, 2)).map((g) => g.id), [
        'uae_national_day',
      ]);
    });

    test('is empty on an ordinary day', () {
      expect(seasonalGreetingsOn(DateTime(2026, 6, 10)), isEmpty);
    });
  });

  group('dismissKey', () {
    test('keeps the original India key so existing dismissals still apply', () {
      final india = seasonalGreetingFor('IN', DateTime(2026, 8, 15))!;
      expect(
        seasonalGreetingDismissKey(india, 2026),
        'seasonal_greeting_independence_day_2026_dismissed',
      );
    });

    test('is per greeting and per year', () {
      final uae = seasonalGreetingFor('AE', DateTime(2026, 12, 2))!;
      expect(
        seasonalGreetingDismissKey(uae, 2026),
        'seasonal_greeting_uae_national_day_2026_dismissed',
      );
      expect(
        seasonalGreetingDismissKey(uae, 2027),
        isNot(seasonalGreetingDismissKey(uae, 2026)),
      );
    });
  });

  group('data', () {
    test('every greeting is complete and ids are unique', () {
      final ids = seasonalGreetings.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);

      for (final g in seasonalGreetings) {
        expect(g.countryCode, matches(RegExp(r'^[A-Z]{2}$')), reason: g.id);
        expect(
          DateTime(2024, g.month, g.day).day,
          g.day,
          reason: '${g.id} is a real day',
        );
        expect(g.flag, isNotEmpty, reason: g.id);
        expect(g.title.trim(), isNotEmpty, reason: g.id);
        expect(g.message.trim(), isNotEmpty, reason: g.id);
        expect(g.colors, isNotEmpty, reason: g.id);
      }
    });

    test('the GCC greetings match the push notification data exactly', () {
      // supabase/functions/send-holiday-notification/holidays.ts is the source
      // for the scheduled pushes. The banner must show the same days and words.
      final ts = File(
        'supabase/functions/send-holiday-notification/holidays.ts',
      ).readAsStringSync();

      final entry = RegExp(
        r"eventId: '(\w+)',\s*countryCode: '(\w+)',\s*month: (\d+),\s*day: (\d+),\s*title: '([^']*)',\s*body: '([^']*)'",
      );
      final pushed = {
        for (final m in entry.allMatches(ts))
          m.group(1)!: (
            m.group(2)!,
            int.parse(m.group(3)!),
            int.parse(m.group(4)!),
            m.group(5)!,
            m.group(6)!,
          ),
      };
      final inApp = {
        for (final g in seasonalGreetings.where((g) => g.countryCode != 'IN'))
          // The push title carries the flag; the banner shows it separately.
          g.id: (
            g.countryCode,
            g.month,
            g.day,
            '${g.title} ${g.flag}',
            g.message,
          ),
      };

      expect(pushed, isNotEmpty);
      expect(inApp, pushed);
    });
  });
}
