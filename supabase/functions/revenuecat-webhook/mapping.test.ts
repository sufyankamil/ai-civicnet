import assert from 'node:assert/strict'
import { test } from 'node:test'
import { mapEvent } from './mapping.ts'

// Run with: node --test supabase/functions/revenuecat-webhook/mapping.test.ts
// (or `deno test`, which also understands node:test).

const USER = '2d619a19-b9d9-45ae-a871-aa40ea36d867'
const NOW = Date.UTC(2026, 11, 1)
const WEEK = 7 * 24 * 60 * 60 * 1000

const base = {
  app_user_id: USER,
  event_timestamp_ms: NOW,
  expiration_at_ms: NOW + WEEK,
  entitlement_ids: ['pro'],
  store: 'APP_STORE',
}

test('TEST events are ignored', () => {
  assert.deepEqual(mapEvent({ ...base, type: 'TEST' }), { action: 'ignore', reason: 'test' })
})

test('anonymous RevenueCat ids are ignored', () => {
  const result = mapEvent({ ...base, type: 'INITIAL_PURCHASE', app_user_id: '$RCAnonymousID:abc' })
  assert.deepEqual(result, { action: 'ignore', reason: 'anonymous_user' })
})

test('events for other entitlements are ignored', () => {
  const result = mapEvent({ ...base, type: 'RENEWAL', entitlement_ids: ['other'] })
  assert.deepEqual(result, { action: 'ignore', reason: 'other_entitlement' })
})

test('events without a timestamp are ignored', () => {
  const result = mapEvent({ ...base, type: 'RENEWAL', event_timestamp_ms: undefined })
  assert.deepEqual(result, { action: 'ignore', reason: 'missing_timestamp' })
})

test('unhandled event types are ignored', () => {
  const result = mapEvent({ ...base, type: 'SUBSCRIBER_ALIAS' })
  assert.deepEqual(result, { action: 'ignore', reason: 'unhandled_type' })
})

test('INITIAL_PURCHASE in a trial period grants Pro as trialing', () => {
  const result = mapEvent({ ...base, type: 'INITIAL_PURCHASE', period_type: 'TRIAL' })
  assert.equal(result.action, 'upsert')
  if (result.action !== 'upsert') return
  assert.equal(result.update.user_id, USER)
  assert.equal(result.update.entitlement, 'pro')
  assert.equal(result.update.status, 'trialing')
  assert.equal(result.update.trial_ends_at, new Date(NOW + WEEK).toISOString())
  assert.equal(result.update.current_period_end, new Date(NOW + WEEK).toISOString())
  assert.equal(result.update.source, 'app_store')
  assert.equal(result.update.last_event_ms, NOW)
})

test('RENEWAL in a normal period grants Pro as active with no trial end', () => {
  const result = mapEvent({ ...base, type: 'RENEWAL', period_type: 'NORMAL' })
  assert.equal(result.action, 'upsert')
  if (result.action !== 'upsert') return
  assert.equal(result.update.status, 'active')
  assert.equal(result.update.trial_ends_at, null)
})

test('events without entitlement_ids are treated as Pro', () => {
  const result = mapEvent({ ...base, type: 'RENEWAL', entitlement_ids: null })
  assert.equal(result.action, 'upsert')
})

test('BILLING_ISSUE keeps Pro but marks past_due', () => {
  const result = mapEvent({ ...base, type: 'BILLING_ISSUE' })
  assert.equal(result.action, 'upsert')
  if (result.action !== 'upsert') return
  assert.equal(result.update.entitlement, 'pro')
  assert.equal(result.update.status, 'past_due')
})

test('EXPIRATION drops back to free', () => {
  const result = mapEvent({ ...base, type: 'EXPIRATION' })
  assert.equal(result.action, 'upsert')
  if (result.action !== 'upsert') return
  assert.equal(result.update.entitlement, 'free')
  assert.equal(result.update.status, 'expired')
  assert.equal(result.update.trial_ends_at, null)
})

test('CANCELLATION while still entitled is ignored (access runs to expiry)', () => {
  const result = mapEvent({ ...base, type: 'CANCELLATION' })
  assert.deepEqual(result, { action: 'ignore', reason: 'entitled_until_expiry' })
})

test('CANCELLATION with an expiry already in the past (refund) ends access', () => {
  const result = mapEvent({ ...base, type: 'CANCELLATION', expiration_at_ms: NOW - 1000 })
  assert.equal(result.action, 'upsert')
  if (result.action !== 'upsert') return
  assert.equal(result.update.entitlement, 'free')
  assert.equal(result.update.status, 'expired')
})
