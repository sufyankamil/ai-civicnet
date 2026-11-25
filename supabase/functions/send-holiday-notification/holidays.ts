// Fixed-date national holidays that get a greeting push. Pure data and date
// logic, free of Deno/Supabase imports so it can be unit tested with Node.
//
// The same list is mirrored in the app (lib/features/home/models/
// seasonal_greeting.dart) for the home banner; a Flutter test keeps the two in
// sync. India's Independence Day is not listed here: it keeps its own cron job.
//
// Only fixed Gregorian dates belong here. Eid and other holidays that follow
// the Hijri calendar move every year and need a different mechanism.

export interface Holiday {
  eventId: string
  countryCode: string
  month: number // 1-12
  day: number // 1-31
  title: string // English
  body: string // Arabic
}

// Each country's own time zone, so "today" means today for the people there.
export const COUNTRY_TIME_ZONES: Record<string, string> = {
  AE: 'Asia/Dubai',
  OM: 'Asia/Muscat',
  SA: 'Asia/Riyadh',
  KW: 'Asia/Kuwait',
  QA: 'Asia/Qatar',
  BH: 'Asia/Bahrain',
}

export const HOLIDAYS: Holiday[] = [
  {
    eventId: 'uae_flag_day',
    countryCode: 'AE',
    month: 11,
    day: 3,
    title: 'Happy UAE Flag Day! 🇦🇪',
    body: 'عاش العلم، عاشت الإمارات',
  },
  {
    eventId: 'uae_national_day',
    countryCode: 'AE',
    month: 12,
    day: 2,
    title: 'Happy UAE National Day! 🇦🇪',
    body: 'كل عام والإمارات بخير',
  },
  {
    eventId: 'saudi_founding_day',
    countryCode: 'SA',
    month: 2,
    day: 22,
    title: 'Happy Saudi Founding Day! 🇸🇦',
    body: 'يوم التأسيس، كل عام والمملكة بخير',
  },
  {
    eventId: 'saudi_national_day',
    countryCode: 'SA',
    month: 9,
    day: 23,
    title: 'Happy Saudi National Day! 🇸🇦',
    body: 'اليوم الوطني السعودي، كل عام والمملكة بخير',
  },
  {
    eventId: 'qatar_national_day',
    countryCode: 'QA',
    month: 12,
    day: 18,
    title: 'Happy Qatar National Day! 🇶🇦',
    body: 'اليوم الوطني لدولة قطر، كل عام وقطر بخير',
  },
  {
    eventId: 'kuwait_national_day',
    countryCode: 'KW',
    month: 2,
    day: 25,
    title: 'Happy Kuwait National Day! 🇰🇼',
    body: 'اليوم الوطني الكويتي، كل عام والكويت بخير',
  },
  {
    eventId: 'kuwait_liberation_day',
    countryCode: 'KW',
    month: 2,
    day: 26,
    title: 'Happy Kuwait Liberation Day! 🇰🇼',
    body: 'يوم التحرير، كل عام والكويت بخير',
  },
  {
    eventId: 'bahrain_national_day',
    countryCode: 'BH',
    month: 12,
    day: 16,
    title: 'Happy Bahrain National Day! 🇧🇭',
    body: 'اليوم الوطني البحريني، كل عام والبحرين بخير',
  },
  {
    eventId: 'oman_national_day',
    countryCode: 'OM',
    month: 11,
    day: 18,
    title: 'Happy Oman National Day! 🇴🇲',
    body: 'العيد الوطني العماني، كل عام وسلطنة عُمان بخير',
  },
]

/** The calendar month and day of [now] in the given IANA time zone. */
export function monthDayInZone(now: Date, timeZone: string): { month: number; day: number } {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    month: 'numeric',
    day: 'numeric',
  }).formatToParts(now)
  const get = (type: string) => Number(parts.find((p) => p.type === type)?.value)
  return { month: get('month'), day: get('day') }
}

/** Holidays that fall today (in their own country's time zone) for [countryCodes]. */
export function holidaysToday(now: Date, countryCodes: string[]): Holiday[] {
  const wanted = new Set(countryCodes.map((c) => c.toUpperCase()))
  return HOLIDAYS.filter((h) => {
    if (!wanted.has(h.countryCode)) return false
    const zone = COUNTRY_TIME_ZONES[h.countryCode]
    if (!zone) return false
    const today = monthDayInZone(now, zone)
    return today.month === h.month && today.day === h.day
  })
}
