// Pure mapping from a RevenueCat webhook event to a `subscriptions` row update.
// Kept free of Deno/Supabase imports so it can be unit tested with plain Node.

export const PRO_ENTITLEMENT = 'pro'

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export interface RevenueCatEvent {
  type?: string
  app_user_id?: string
  period_type?: string
  expiration_at_ms?: number | null
  event_timestamp_ms?: number
  entitlement_ids?: string[] | null
  store?: string
}

export interface SubscriptionUpdate {
  user_id: string
  entitlement: 'free' | 'pro'
  status: 'trialing' | 'active' | 'past_due' | 'expired'
  trial_ends_at: string | null
  current_period_end: string | null
  source: string
  last_event_ms: number
}

export type MappingResult =
  | { action: 'ignore'; reason: string }
  | { action: 'upsert'; update: SubscriptionUpdate }

// Events that start or extend paid access.
const GRANT_TYPES = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'PRODUCT_CHANGE',
  'UNCANCELLATION',
  'NON_RENEWING_PURCHASE',
])

function iso(ms: number | null | undefined): string | null {
  return typeof ms === 'number' ? new Date(ms).toISOString() : null
}

export function mapEvent(event: RevenueCatEvent): MappingResult {
  if (event.type === 'TEST') return { action: 'ignore', reason: 'test' }

  const userId = event.app_user_id
  if (typeof userId !== 'string' || !UUID_RE.test(userId)) {
    return { action: 'ignore', reason: 'anonymous_user' }
  }

  // entitlement_ids is absent on some event types; treat that as Pro.
  if (Array.isArray(event.entitlement_ids) && !event.entitlement_ids.includes(PRO_ENTITLEMENT)) {
    return { action: 'ignore', reason: 'other_entitlement' }
  }

  const eventMs = event.event_timestamp_ms
  if (typeof eventMs !== 'number') return { action: 'ignore', reason: 'missing_timestamp' }

  const type = event.type ?? ''
  const source = (event.store ?? 'revenuecat').toLowerCase()
  const expiresAt = iso(event.expiration_at_ms)
  const common = { user_id: userId, source, last_event_ms: eventMs }

  if (GRANT_TYPES.has(type)) {
    const isTrial = event.period_type === 'TRIAL'
    return {
      action: 'upsert',
      update: {
        ...common,
        entitlement: 'pro',
        status: isTrial ? 'trialing' : 'active',
        trial_ends_at: isTrial ? expiresAt : null,
        current_period_end: expiresAt,
      },
    }
  }

  if (type === 'BILLING_ISSUE') {
    // Keep access during the store's grace period; the quota function still
    // requires current_period_end to be in the future.
    return {
      action: 'upsert',
      update: {
        ...common,
        entitlement: 'pro',
        status: 'past_due',
        trial_ends_at: null,
        current_period_end: expiresAt,
      },
    }
  }

  const expired: MappingResult = {
    action: 'upsert',
    update: {
      ...common,
      entitlement: 'free',
      status: 'expired',
      trial_ends_at: null,
      current_period_end: expiresAt,
    },
  }

  if (type === 'EXPIRATION') return expired

  if (type === 'CANCELLATION') {
    // A normal cancellation only turns off auto-renew: the user keeps access
    // until the period ends (EXPIRATION arrives then). A refund sends an
    // expiration that is already in the past, which ends access immediately.
    const alreadyExpired =
      typeof event.expiration_at_ms === 'number' && event.expiration_at_ms <= eventMs
    return alreadyExpired ? expired : { action: 'ignore', reason: 'entitled_until_expiry' }
  }

  return { action: 'ignore', reason: 'unhandled_type' }
}
