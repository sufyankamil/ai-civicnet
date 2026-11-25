import assert from 'node:assert/strict'
import { test } from 'node:test'
import { COUNTRY_TIME_ZONES, HOLIDAYS, holidaysToday, monthDayInZone } from './holidays.ts'

// Run with: node --test supabase/functions/send-holiday-notification/holidays.test.ts

const at = (iso: string) => new Date(iso)

test('monthDayInZone uses the country time zone, not UTC', () => {
  // 21:00 UTC on Dec 1 is already 01:00 on Dec 2 in the UAE (UTC+4).
  assert.deepEqual(monthDayInZone(at('2026-12-01T21:00:00Z'), 'Asia/Dubai'), { month: 12, day: 2 })
  // ...but still 00:00 on Dec 2 in Saudi Arabia (UTC+3) only at 21:00 UTC.
  assert.deepEqual(monthDayInZone(at('2026-12-01T20:59:00Z'), 'Asia/Riyadh'), { month: 12, day: 1 })
})

test('UAE National Day is found on Dec 2 for the UAE', () => {
  const found = holidaysToday(at('2026-12-02T05:00:00Z'), ['AE'])
  assert.deepEqual(found.map((h) => h.eventId), ['uae_national_day'])
})

test('UAE Flag Day is Nov 3', () => {
  const found = holidaysToday(at('2026-11-03T05:00:00Z'), ['AE'])
  assert.deepEqual(found.map((h) => h.eventId), ['uae_flag_day'])
})

test('a holiday is only returned for the country that owns it', () => {
  assert.deepEqual(holidaysToday(at('2026-12-02T05:00:00Z'), ['SA', 'KW', 'QA', 'BH']), [])
})

test('only the requested countries are considered', () => {
  assert.deepEqual(holidaysToday(at('2026-12-02T05:00:00Z'), []), [])
})

test('Saudi Arabia has Founding Day and National Day', () => {
  assert.deepEqual(
    holidaysToday(at('2026-02-22T06:00:00Z'), ['SA']).map((h) => h.eventId),
    ['saudi_founding_day'],
  )
  assert.deepEqual(
    holidaysToday(at('2026-09-23T06:00:00Z'), ['SA']).map((h) => h.eventId),
    ['saudi_national_day'],
  )
})

test('Kuwait has National Day on Feb 25 and Liberation Day on Feb 26', () => {
  assert.deepEqual(
    holidaysToday(at('2026-02-25T06:00:00Z'), ['KW']).map((h) => h.eventId),
    ['kuwait_national_day'],
  )
  assert.deepEqual(
    holidaysToday(at('2026-02-26T06:00:00Z'), ['KW']).map((h) => h.eventId),
    ['kuwait_liberation_day'],
  )
})

test('Qatar, Bahrain and Oman national days', () => {
  assert.deepEqual(holidaysToday(at('2026-12-18T06:00:00Z'), ['QA']).map((h) => h.eventId), ['qatar_national_day'])
  assert.deepEqual(holidaysToday(at('2026-12-16T06:00:00Z'), ['BH']).map((h) => h.eventId), ['bahrain_national_day'])
  assert.deepEqual(holidaysToday(at('2026-11-18T05:00:00Z'), ['OM']).map((h) => h.eventId), ['oman_national_day'])
})

test('an ordinary day has no holidays', () => {
  assert.deepEqual(holidaysToday(at('2026-06-10T05:00:00Z'), Object.keys(COUNTRY_TIME_ZONES)), [])
})

test('the data is well formed', () => {
  const ids = HOLIDAYS.map((h) => h.eventId)
  assert.equal(new Set(ids).size, ids.length, 'event ids are unique')

  for (const h of HOLIDAYS) {
    assert.match(h.countryCode, /^[A-Z]{2}$/)
    assert.ok(COUNTRY_TIME_ZONES[h.countryCode], `${h.eventId} has a time zone`)
    assert.ok(h.month >= 1 && h.month <= 12, `${h.eventId} month`)
    // Use a leap year so Feb 29 would still be accepted if ever added.
    const date = new Date(Date.UTC(2024, h.month - 1, h.day))
    assert.equal(date.getUTCMonth(), h.month - 1, `${h.eventId} is a real calendar day`)
    assert.ok(h.title.trim().length > 0, `${h.eventId} title`)
    assert.match(h.body, /[؀-ۿ]/, `${h.eventId} body is Arabic`)
  }
})

test('covers every GCC country', () => {
  const countries = new Set(HOLIDAYS.map((h) => h.countryCode))
  for (const code of ['AE', 'SA', 'QA', 'KW', 'BH', 'OM']) assert.ok(countries.has(code), code)
})
