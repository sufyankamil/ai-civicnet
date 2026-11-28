# Design: Emergency SOS and Offers board

Status: proposal, for approval. Issues: [#108 SOS](https://github.com/sufyankamil/ai-civicnet/issues/108), [#109 Offers](https://github.com/sufyankamil/ai-civicnet/issues/109).

## Order of work

1. **SOS first** (#108), because it is the more distinctive and more urgent feature, and it builds the geo-targeted push that Offers can reuse later.
2. **Offers second** (#109).

They are separate issues and separate PRs (repo rule: one issue per change), planned together here. If you prefer both in one release, ship SOS and Offers PRs back to back; the shared groundwork below is built once.

## What exists today (checked in the repo)

- Requests live in `help_requests` (`category`, `urgency`, `lat`, `lng`, `status`). Accepting help goes through `request_applications`, then chat opens.
- Push is FCM **topics only**: every new request goes to the single `global_requests` topic via the `notify-new-request` edge function, and each user also has a `user_<id>` topic. **No device tokens are stored anywhere**, so there is no way to push "to people near this point".
- Blocking and reporting exist (`blocked_users`, `user_reports`, `profiles.report_count`).
- Items to lend are already covered by `community_assets` (location, embedding, `match_assets_v1`).
- Matching is `match_requests_v3` (vector similarity + distance + urgency).

## Shared groundwork: geo-targeted push

Needed by SOS, and later useful for notification preferences (today every user is pinged for every request).

- New table `device_tokens` (`user_id`, `token`, `platform`, `lat_rounded`, `lng_rounded`, `updated_at`). Location rounded to about 500 m. RLS: users read and write only their own rows.
- The app registers its FCM token and refreshes the rounded location on launch and when the user moves a long way.
- A new edge function, using the service role, selects tokens within a radius, excludes the sender, anyone who blocked the sender, and stale tokens (older than 30 days), then sends via FCM HTTP v1 in batches.

Alternative considered: geohash topics (subscribe to your own cell). Rejected: a condition allows only 5 topics, so covering neighbouring cells is awkward, and blocks cannot be honoured.

## SOS (#108)

### User flow
1. An SOS control sits on Home (and in the request composer's emergency category).
2. Tapping it opens a short sheet: **"Call 112 now"** first (country-aware: India 112, UAE 999/998/997, others from device region), then **"Alert nearby helpers"**.
3. The alert needs **press and hold for 2 seconds** and the user's location.
4. The app creates an SOS request and shows a waiting screen ("3 helpers alerted") with a Cancel and an "I'm safe" button.
5. A helper taps the push, sees the request, and accepts through the existing application flow. The requester confirms one helper; the exact location is revealed only to that helper. Chat opens.
6. The SOS expires after 60 minutes, or when the requester taps "I'm safe", then asks for a thank-you and rating.

### Backend
- `help_requests`: add `is_sos boolean default false`, `sos_expires_at timestamptz`.
- RPC `create_sos(lat, lng, note)`: security definer, checks the rate limit, inserts the request with `category = 'Emergency'`, `urgency = 'critical'`, returns the id. Public location in the row is rounded; the exact point is stored separately and readable only by the requester and the accepted helper.
- Edge function `notify-sos` (invoked after insert): finds helpers within 2 km (configurable), sends a high-priority push, returns the count alerted.
- Everything has RLS. SQL is a new script in `sql_scripts/` applied by hand, with a test script in `sql_scripts/tests/` in the style of `subscriptions_quota_test.sql`.

### Abuse and safety controls
- Hold to confirm; rate limit of 1 per 10 minutes and 3 per day per user; auto-expiry.
- Helpers can report a false alarm; confirmed false alarms lower karma and can suspend SOS for that user.
- Existing block and report tools apply; blocked users are never alerted.
- Clear copy everywhere that SOS is **not** a replacement for emergency services. Mention it in App Store review notes.
- SOS is **free for everyone**, never gated by Pro.

### App (Flutter)
- New `lib/features/sos/` with `data / domain / presentation / di`, following the request feature. View model unit tests first (confirm hold, rate-limit error, expiry, cancel), then widget tests for the sheet. en and hi strings.

### Open questions for the owner
1. Default radius: 2 km, or smaller for dense areas?
2. Require a completed profile or a minimum account age before SOS is allowed?
3. Legal review of the disclaimer wording for India and GCC before release.
4. Trusted contacts by SMS: v2?

## Offers board (#109)

### Scope
Offers are for **time and skills** (rides, tutoring, errands, a spare hour). Physical items stay in the existing **community assets** library. On a request, "Community helpers" can show both matching offers and matching assets, so users see one list.

### Backend
- Table `offers`: `id, owner_id, title, description, category, lat, lng, radius_m, status ('active' | 'paused' | 'expired'), embedding vector(768), created_at, expires_at`.
- RLS: signed-in users read `status = 'active'` rows; owners insert, update and delete their own.
- RPC `nearby_offers(lat, lng, radius_m, category)` and a matching RPC reusing the embedding approach of `match_assets_v1`.
- Offers expire after 30 days unless renewed, so the board does not fill with stale rows.

### App (Flutter)
- New `lib/features/offers/`. Home gets a segmented control: Requests | Offers. A "Post an offer" screen with category, description, and radius.
- Request detail: "Community helpers" is filled from matching offers; "Ask for help" on an offer starts the accept-then-chat flow.
- Report and block like other content.

### Out of scope for v1
Push alerts for matching offers, Pro limits, recurring offers.

### Open questions for the owner
1. Should offers show the helper's rating and karma on the card?
2. Maximum active offers per user (suggest 5)?

## Testing approach (both)

Tests first, as in `AGENTS.md`: view-model and service unit tests with the network mocked, widget tests for new screens, SQL test scripts for RPCs and RLS. The edge functions are reviewed by reading and tested manually against a staging project, never real users.

## Rollout

1. Merge groundwork and SOS behind a remote flag (`sos_enabled`), test with a few real devices, then enable.
2. Offers after SOS has been stable for a week.
3. Update the privacy policy (device tokens, rounded location, SOS location handling) and the App Store privacy labels before each release.
