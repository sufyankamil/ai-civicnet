import 'package:flutter/painting.dart';

/// A national-day greeting shown on the home screen for users who picked that
/// country.
///
/// The GCC entries are mirrored in
/// `supabase/functions/send-holiday-notification/holidays.ts`, which sends the
/// matching push notifications; a test keeps the two lists in sync. Only
/// fixed-date holidays belong here.
class SeasonalGreeting {
  const SeasonalGreeting({
    required this.id,
    required this.countryCode,
    required this.month,
    required this.day,
    required this.flag,
    required this.title,
    required this.message,
    required this.colors,
  });

  /// Stable id, also used for the per-year "dismissed" preference.
  final String id;
  final String countryCode;
  final int month;
  final int day;
  final String flag;

  /// English headline, without the flag.
  final String title;

  /// Greeting in the country's own language.
  final String message;

  /// Banner background gradient.
  final List<Color> colors;
}

const _lightRed = Color(0xFFFFE3E3);
const _lightGreen = Color(0xFFE2F3E8);
const _lightMaroon = Color(0xFFF4E1E8);
const _white = Color(0xFFFFFFFF);

const seasonalGreetings = <SeasonalGreeting>[
  SeasonalGreeting(
    id: 'independence_day',
    countryCode: 'IN',
    month: 8,
    day: 15,
    flag: '🇮🇳',
    title: 'Happy Independence Day!',
    message: 'स्वतंत्रता दिवस की शुभकामनाएँ',
    colors: [Color(0xFFFF9933), _white, Color(0xFF138808)],
  ),
  SeasonalGreeting(
    id: 'uae_flag_day',
    countryCode: 'AE',
    month: 11,
    day: 3,
    flag: '🇦🇪',
    title: 'Happy UAE Flag Day!',
    message: 'عاش العلم، عاشت الإمارات',
    colors: [_lightRed, _white, _lightGreen],
  ),
  SeasonalGreeting(
    id: 'uae_national_day',
    countryCode: 'AE',
    month: 12,
    day: 2,
    flag: '🇦🇪',
    title: 'Happy UAE National Day!',
    message: 'كل عام والإمارات بخير',
    colors: [_lightRed, _white, _lightGreen],
  ),
  SeasonalGreeting(
    id: 'saudi_founding_day',
    countryCode: 'SA',
    month: 2,
    day: 22,
    flag: '🇸🇦',
    title: 'Happy Saudi Founding Day!',
    message: 'يوم التأسيس، كل عام والمملكة بخير',
    colors: [_lightGreen, _white, _lightGreen],
  ),
  SeasonalGreeting(
    id: 'saudi_national_day',
    countryCode: 'SA',
    month: 9,
    day: 23,
    flag: '🇸🇦',
    title: 'Happy Saudi National Day!',
    message: 'اليوم الوطني السعودي، كل عام والمملكة بخير',
    colors: [_lightGreen, _white, _lightGreen],
  ),
  SeasonalGreeting(
    id: 'qatar_national_day',
    countryCode: 'QA',
    month: 12,
    day: 18,
    flag: '🇶🇦',
    title: 'Happy Qatar National Day!',
    message: 'اليوم الوطني لدولة قطر، كل عام وقطر بخير',
    colors: [_lightMaroon, _white, _lightMaroon],
  ),
  SeasonalGreeting(
    id: 'kuwait_national_day',
    countryCode: 'KW',
    month: 2,
    day: 25,
    flag: '🇰🇼',
    title: 'Happy Kuwait National Day!',
    message: 'اليوم الوطني الكويتي، كل عام والكويت بخير',
    colors: [_lightGreen, _white, _lightRed],
  ),
  SeasonalGreeting(
    id: 'kuwait_liberation_day',
    countryCode: 'KW',
    month: 2,
    day: 26,
    flag: '🇰🇼',
    title: 'Happy Kuwait Liberation Day!',
    message: 'يوم التحرير، كل عام والكويت بخير',
    colors: [_lightGreen, _white, _lightRed],
  ),
  SeasonalGreeting(
    id: 'bahrain_national_day',
    countryCode: 'BH',
    month: 12,
    day: 16,
    flag: '🇧🇭',
    title: 'Happy Bahrain National Day!',
    message: 'اليوم الوطني البحريني، كل عام والبحرين بخير',
    colors: [_lightRed, _white, _lightRed],
  ),
  SeasonalGreeting(
    id: 'oman_national_day',
    countryCode: 'OM',
    month: 11,
    day: 18,
    flag: '🇴🇲',
    title: 'Happy Oman National Day!',
    message: 'العيد الوطني العماني، كل عام وسلطنة عُمان بخير',
    colors: [_lightRed, _white, _lightGreen],
  ),
];

/// Greetings that fall on [date], for any country.
List<SeasonalGreeting> seasonalGreetingsOn(DateTime date) => [
  for (final g in seasonalGreetings)
    if (g.month == date.month && g.day == date.day) g,
];

/// The greeting for [countryCode] on [date], if there is one.
SeasonalGreeting? seasonalGreetingFor(String? countryCode, DateTime date) {
  if (countryCode == null || countryCode.isEmpty) return null;
  final code = countryCode.toUpperCase();
  for (final g in seasonalGreetingsOn(date)) {
    if (g.countryCode == code) return g;
  }
  return null;
}

/// SharedPreferences key remembering that the user dismissed [greeting] this
/// [year]. India keeps its original key so earlier dismissals still count.
String seasonalGreetingDismissKey(SeasonalGreeting greeting, int year) =>
    'seasonal_greeting_${greeting.id}_${year}_dismissed';
