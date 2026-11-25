# AGENTS.md — CivicNet Development Guidelines & Agent Instructions

Welcome to **CivicNet** (`civic_net`). This document defines the engineering standards, architectural boundaries, coding rules, and workflows for all AI coding agents working on this codebase.

---

## 1. Project Mission & Core Overview

**CivicNet** is a futuristic, community-driven platform connecting people who need help with neighbors who can provide it.

### Core Features:
- **AI Opportunity Matching Engine**: Calculates an `AI Relevance Score` combining:
  1. **Proximity**: GPS location & distance calculation via Haversine formula.
  2. **Skillset Vector Similarity**: Google Gemini embeddings matched against requests via Supabase PostgreSQL `pgvector` RPC (`match_requests_v3`).
  3. **Urgency Weighting**: Priority boost for emergency tasks.
- **Real-Time Communication**: Supabase-powered private messaging unlocked only after helper acceptance.
- **Push Alerts**: Firebase Cloud Messaging (FCM) alerts for match updates and nearby urgent needs.
- **Design Language**: "Liquid Glass UI" / Premium AI Aura (dark-mode-first, glassmorphism, glowing micro-animations, vibrant violet accents `#7B61FF`).

---

## 2. Architecture & Directory Layout

CivicNet adheres strictly to **Feature-First Clean Architecture**:

```
lib/
├── core/             # App-wide constants, utilities, network helpers, base models
├── features/         # Feature modules (Strictly isolated)
│   ├── auth/         # Authentication, user profile, skill onboarding
│   ├── discover/     # Search, category browsing, AI match carousels
│   ├── events/       # Community events, RSVP, comment streams
│   ├── home/         # Action feed, urgent matching, map integration
│   └── request/      # Help request creation, helper selection, resolution
├── services/         # Infrastructure & external SDK singletons
│   ├── ai_service.dart          # Google Gemini embeddings & classification
│   ├── supabase_service.dart    # Database queries, RPCs, Auth, Realtime
│   ├── notification_service.dart # Firebase FCM push notifications
│   └── location_service.dart    # GPS geolocation & geocoding
├── components/       # Global reusable UI widgets (Buttons, Cards, Dialogs)
├── theme/            # Design tokens, Liquid Glass styles, colors, typography
└── main.dart         # App entry point, env loading, service registration
```

---

## 3. Mandatory Agent Guardrails & Coding Rules

### 📋 GitHub Issues-First Workflow (MANDATORY)
- **Always Create GitHub Issue First**: Before making, updating, or adding ANY changes to the codebase, ALWAYS create a GitHub issue first using GitHub MCP/tools describing the goal, rationale, and planned changes. Never write or modify code before an issue is created.
- **Never Commit or Push Directly to `main`**: All development and modifications must occur on a working/feature branch. Do not switch to a new branch for every small change; maintain progress on the active branch, but NEVER commit or push directly to `main`.

### 🧪 Test-Driven Development (MANDATORY)
Whenever adding or updating a feature (or fixing a bug), follow the Red → Green → Refactor cycle. Tests come **before** the implementation.
1. **Red**: Write test cases first that describe the expected behavior (happy path, edge cases, error/null-location paths). Run them and confirm they fail for the right reason.
2. **Green**: Write the minimum implementation needed to make the tests pass.
3. **Refactor**: Clean up the code while keeping the tests green.

Rules:
- Never write implementation code for a feature before its tests exist.
- Bug fixes start with a failing regression test that reproduces the bug.
- Put tests under `test/`, mirroring the `lib/` structure (e.g. `lib/features/request/viewmodels/x.dart` → `test/features/request/viewmodels/x_test.dart`). Use widget tests for UI behavior.
- Business logic in ViewModels and Services must be unit tested. Mock external dependencies (Supabase, Gemini, FCM, location); tests must never hit real network services or use real secrets.
- When updating existing behavior, update the affected tests first, then change the code.
- Do not delete or weaken existing tests just to get a change passing.

### 🧠 Feature Memory Log (MANDATORY)
After completing any feature, update, or bug fix, summarize the changes and append an entry to the **Feature Log** at the bottom of this file, so future agents know what already exists and do not repeat work.
- **Before starting** any task, read the Feature Log and check whether the work (or something similar) was already done. Extend existing code instead of duplicating it.
- Add the entry in the same branch/PR as the change, newest entries first.
- Each entry has: date, short title, issue/PR link (if any), what changed, key files touched, and notes/gotchas (decisions made, things deliberately not done).
- Keep entries brief (3–6 lines). Record the *what and why*, not a full diff.

### 🛡️ Security & Environment
- **Never Hardcode Secrets**: Never expose Supabase keys, Google Maps API keys, or Gemini API keys in Dart code. Always access them via `.env` / `flutter_dotenv`.
- **Preserve `.env.example`**: If adding a new environment variable, update `.env.example` with a placeholder description.
- **Row Level Security (RLS)**: Any new Supabase table or RPC must have strict RLS policies enabled.

### 🏛️ Feature-First Clean Architecture
- **No Direct Cross-Feature Coupling**: Feature modules must never directly import internal files from another feature. If a widget or logic is shared by 2+ features, promote it to `lib/components/`, `lib/core/`, or `lib/services/`.
- **State Separation**:
  - Keep UI widgets stateless or presentation-focused.
  - Business logic and network coordination belong in ViewModels or dedicated Services.
  - Listen to reactive streams cleanly (`onAuthStateChange`, realtime channels) and ensure `dispose()` is called on controllers and subscriptions to prevent memory leaks.

### 🎨 Design System Integrity ("Liquid Glass UI")
- **Dark Mode First**: Maintain high visual contrast and futuristic glass aesthetics.
- **Color Tokens**: Use existing theme constants (`#7B61FF` primary accent, deep purple/slate dark backgrounds). Never introduce arbitrary hardcoded hexadecimal colors.
- **Typography**: Adhere to `Poppins` font family hierarchy defined in `theme/`.
- **Haptic Feedback**: Use `AppHaptic` wrapper for button taps, pull-to-refreshes, and modal dismissals to preserve the tactile experience.

### 🧪 Error Handling & Resilience
- All network or AI service calls must be wrapped in `try/catch` blocks.
- Surface errors gracefully using the in-app notification system (`Toastification` or app dialogs) rather than raw print/throw statements in production paths.
- Guard against null location data when device location permissions are denied.

---

## 4. Workflows & Command Reference

### Running the App
```zsh
# Run on currently active device/simulator:
flutter run

# Run targeting specific simulator:
flutter run -d "iPhone 16 Pro"
flutter run -d macos
flutter run -d chrome
```

### Dependency Management & Asset Generation
```zsh
# Fetch packages:
flutter pub get

# Generate app icons / splash screens (when updating assets):
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

### Testing (TDD)
```zsh
# Run all tests:
flutter test

# Run a single test file while developing (Red → Green loop):
flutter test test/path/to/feature_test.dart
```

### Static Analysis & Verification
```zsh
# Verify code health before completing tasks:
flutter analyze
```

---

## 5. Agent Verification Checklist

Before considering any task complete:
1. Confirm tests were written **before** the implementation and that `flutter test` passes.
2. Run `flutter analyze` and confirm 0 errors or warnings introduced.
3. Verify cross-platform UI responsiveness (check both iOS and Android layouts).
4. Ensure no `.env` or sensitive credentials were accidentally staged or committed.
5. Verify that newly added assets or fonts are declared in `pubspec.yaml`.
6. Append a summary entry to the Feature Log below.

---

## 6. Feature Log

Newest first. Format:

```
### YYYY-MM-DD — Title (#issue / PR link)
- What changed:
- Key files:
- Notes / gotchas:
```

### 2026-11-25 — Adapt to the iPhone Duo and other large windows (#86)
- What changed: new `AdaptiveContentFrame` wraps the error screen and the router app (on wide windows the column gets a slightly different gutter tone and a soft edge shadow so washes/tints that stop at its edge look deliberate; the splash is deliberately left full-bleed so its gradient fills any window, and its content is centred on the full screen, not the safe area). Screens can paint a full-window background behind the capped column via `AdaptiveFrameScope.setBackground` (used by `AuthBackground`; the route overlay clips to the column, so screens cannot paint into the gutters themselves). It caps content at 640 logical px and centres it on wide windows (gutters use the scaffold colour; the child's `MediaQuery` size and side insets are trimmed to match), and (Android only) keeps the allowed orientations in sync with the display: portrait only below 600 px shortest side, all four above. On iOS the same rule lives in `AppDelegate.application(_:supportedInterfaceOrientationsFor:)`, reading the window scene's own screen. `Info.plist` now declares all four orientations (iPhone and iPad), so rotation is possible when Flutter allows it.
- Key files: `lib/core/utils/adaptive_layout.dart`, `lib/widgets/adaptive_content_frame.dart`, `lib/main.dart`, `ios/Runner/Info.plist`, tests in `test/core/utils/adaptive_layout_test.dart` and `test/widgets/adaptive_content_frame_test.dart`.
- Notes / gotchas: `HomeAppBar` no longer draws its own purple glow (it was clipped to the safe area and showed as a hard-edged rectangle beside the Duo status strip; `HomeScreen` already paints the full-width wash). A small step remains on the closed screen where the pinned search header (safe-area wide) meets the wash under the strip. In one later simulator session the app stayed in a letterboxed portrait window after unfolding (not reproduced reliably; earlier runs rotated). If it recurs, re-evaluate orientations natively on scene/screen change. Do NOT decide orientation in Dart on iOS: Flutter's `display` keeps reporting the screen the app launched on, and a portrait-locked app gets a letterboxed 466x678 window on the inner screen, so a size check never unlocks (launching closed then unfolding stayed stuck in a portrait column). Onboarding page 4 is cut off in landscape (fixed height); not addressed here. The Duo outer screen has a one-sided safe-area inset for the camera strip. Content is centred in the usable area on purpose; the inset is NOT mirrored to the other side (it is a real bar, not a landscape artefact). `UIRequiresFullScreen` is left as it was (iOS 27 ignores it; removing it is the developer's call per TN3192). Modals and dialogs also sit inside the capped column. Phones keep the old portrait-only behaviour.

### 2026-11-25 — Pin Flutter 3.47.6 in the TestFlight workflow (#84)
- What changed: both Flutter setup steps in `testflight.yml` (analyze and build) now pin `flutter-version: "3.47.6"`, matching `dart.yml`.
- Key files: `.github/workflows/testflight.yml`.
- Notes / gotchas: TestFlight Upload #8 failed in `analyze` with 138 `deprecated_member_use` infos because the job used the moving `stable` channel (same cause as #73, which only fixed `dart.yml`). `app-store-release.yml` has no Flutter step. Bump the pin only together with the migration off `package:flutter/material.dart`.

### 2026-11-25 — Release workflow writes the RevenueCat iOS key into `.env`
- What changed: `testflight.yml` now adds `REVENUECAT_IOS_API_KEY` (from the GitHub secret of the same name) to `.env` in both jobs, so TestFlight and App Store builds have billing switched on.
- Key files: `.github/workflows/testflight.yml`.
- Notes / gotchas: needs the GitHub repository secret `REVENUECAT_IOS_API_KEY` (the public `appl_` SDK key). Without it the build gets an empty key and billing stays dormant. Android is not wired up yet.

### 2026-11-25 — Community Commitment banner mentions optional Pro
- What changed: the home "Community Commitment" banner text (`safetyDescription`, English and Hindi) now says requests and events are always free and that Pro is optional and only adds AI features.
- Key files: `lib/l10n/app_en.arb`, `lib/l10n/app_hi.arb`, `test/features/home/widgets/home_safety_banner_test.dart`.
- Notes / gotchas: "only adds AI features" is true today; if Pro ever gates other features (radius, request limits), update this text and the Commitment screen. The Hindi is a draft translation.

### 2026-11-25 — GCC national-day greetings: pushes and country-aware banner (#82)
- What changed: `send-holiday-notification` has a daily mode (`{"daily": true, "countryCodes": [...]}`) that finds today's holidays in each country's own time zone (data in `holidays.ts`) and pushes to `country_<CC>`; the India payload path is unchanged. Fixed-date greetings for UAE (Flag Day Nov 3, National Day Dec 2), Saudi (Founding Day Feb 22, National Day Sep 23), Qatar (Dec 18), Kuwait (Feb 25, Feb 26), Bahrain (Dec 16) and Oman (Nov 18), English title with Arabic message. The home banner is now data-driven and country-aware (India included, same dismiss key).
- Key files: `supabase/functions/send-holiday-notification/{index,holidays,holidays.test}.ts`, `supabase/holiday_notification_gcc_schedule.sql`, `lib/features/home/models/seasonal_greeting.dart`, `lib/features/home/presentation/widgets/seasonal_greeting_banner.dart`, `home_screen.dart`, tests in `test/features/home/`.
- Notes / gotchas: NOT deployed or scheduled yet. Steps: deploy the function, make sure the `HOLIDAY_NOTIFICATION_SECRET` function secret and the `holiday_notification_secret` vault secret exist, then run the GCC schedule SQL (two daily jobs, 09:00 local in UTC+4 and UTC+3). The holiday list exists twice (TypeScript for pushes, Dart for the banner); a Flutter test fails if they drift. Run the TS tests with `node --test supabase/functions/send-holiday-notification/holidays.test.ts`. Eid and other Hijri holidays and UAE Commemoration Day are deliberately not included. Dates should be checked against each country's official calendar.

### 2026-11-25 — GCC countries in the profile country dropdown (#81)
- What changed: the Edit Profile "Country / region" dropdown now also offers UAE, Saudi Arabia, Qatar, Kuwait, Bahrain and Oman. The list lives in one place (`supportedCountries`) and the dropdown is built from it.
- Key files: `lib/features/profile/models/supported_countries.dart`, `lib/features/profile/presentation/screens/edit_profile_screen.dart`, `test/features/profile/models/supported_countries_test.dart`.
- Notes / gotchas: no SQL change (`profiles.country_code` already accepts any two-letter code). Picking a country only subscribes the device to the `country_<CC>` FCM topic. National-day greetings (push cron job and the home banner) exist for India only, so GCC users get nothing yet: that needs per-country cron jobs and a country-aware home banner.

### 2026-11-25 — Subscriptions phase 3: paywall, upgrade prompts and quota hint (#80)
- What changed: new `/subscription` paywall (plans from the RevenueCat offering, trial price line, Restore, auto-renew disclosure, Terms/Privacy, Pro status with manage link; buy button pinned at the bottom). When the free AI quota runs out, the assistant shows a "See Pro plans" button, support chat offers an "Upgrade to Pro" chip, and the voice sheet opens an upgrade sheet; the home briefing still falls back silently. "CivicNet Pro" entry in Settings, and an "N of 10 free AI actions left" hint above the assistant input, backed by a read-only `get_ai_quota_status` RPC.
- Key files: `lib/features/subscription/` (`PaywallViewModel`, `PaywallScreen`), `lib/services/ai_quota_service.dart`, `lib/components/upgrade_prompt.dart`, `lib/components/ai_quota_hint.dart`, `lib/core/utils/paywall_launcher.dart`, `sql_scripts/subscriptions_quota_status.sql`, strings in `app_en.arb` / `app_hi.arb`, tests in `test/features/subscription`, `test/components`, `test/services/ai_quota_service_test.dart`, shared `test/helpers/fake_billing_client.dart`.
- Notes / gotchas: `get_ai_quota_status` is NOT applied yet (apply it by hand after `subscriptions_schema.sql`); until then the hint stays hidden. Plan titles and prices come from the store, so the paywall shows "Couldn't load the plans" until the RevenueCat offering resolves (needs the App Store products to be available). Support-chat and assistant quota messages are still hardcoded English like the rest of those view models. Pro-only feature limits (radius, active requests, assets) were deliberately left out. Needs a full rebuild, not a hot restart, because `purchases_flutter` is a native plugin.

### 2026-11-25 — Subscriptions phase 2: RevenueCat billing and entitlement sync (#78)
- What changed: new `SubscriptionService` (`purchases_flutter`) tracks Pro/trial state, syncs the RevenueCat user id with the Supabase user id on sign-in/out, and exposes plans, purchase and restore. It stays dormant until `REVENUECAT_IOS_API_KEY` / `REVENUECAT_ANDROID_API_KEY` are set. New `revenuecat-webhook` edge function maps RevenueCat events onto `subscriptions` via `apply_subscription_event` (ignores stale/duplicate events, anonymous users and other entitlements).
- Key files: `lib/services/subscription_service.dart`, `lib/services/startup_service.dart`, `supabase/functions/revenuecat-webhook/` (`mapping.ts` + `mapping.test.ts`), `sql_scripts/subscriptions_revenuecat.sql`, `test/services/subscription_service_test.dart`.
- Notes / gotchas: NOT deployed or configured yet. Needs App Store Connect / Play Console subscriptions (7-day intro offer, store-managed so it is once per account), a RevenueCat project with a `pro` entitlement, `supabase secrets set REVENUECAT_WEBHOOK_SECRET=...`, applying the SQL, deploying the function, and a RevenueCat webhook with header `Authorization: Bearer <secret>`. iOS also needs the In-App Purchase capability in Xcode. A normal CANCELLATION is ignored on purpose (access runs to EXPIRATION). Run the webhook tests with `node --test supabase/functions/revenuecat-webhook/mapping.test.ts`. Paywall UI and feature gates are phase 3.

### 2026-11-25 — Subscriptions phase 1: server-side AI proxy and quota (#74)
- What changed: all Gemini calls now go through the new `ai-proxy` Supabase edge function (JWT-verified, key kept as a function secret). Metered features (assistant chat, voice task, briefing, support chat) spend a monthly free quota via `consume_ai_quota`; embeddings, categorization and the assistant's search-query step stay unmetered so matching keeps working. `AiService` throws `AiQuotaExceededException` on HTTP 402 and rethrows it past its local fallbacks; callers show a friendly message (home briefing falls back to the local briefing).
- Key files: `lib/services/ai_gateway.dart`, `lib/services/ai_service.dart`, `supabase/functions/ai-proxy/`, `sql_scripts/subscriptions_schema.sql`, `sql_scripts/tests/subscriptions_quota_test.sql`, tests in `test/services/`.
- Notes / gotchas: SQL and the function are NOT deployed yet: apply the SQL by hand, run the SQL test on a dev DB, `supabase secrets set GEMINI_API_KEY=...`, deploy `ai-proxy`, ship the app, then rotate the old Gemini key (it is in older builds). The release workflow no longer writes `GEMINI_API_KEY` into `.env`; an old app build still needs the key until it is updated. No refund when Gemini fails after quota is spent, and the home briefing still spends 1 quota per day when it auto-loads (revisit with the paywall UI in phase 3). Billing (RevenueCat), paywall UI and feature gates are phases 2-3.

### 2026-11-25 — Pin Flutter version in CI (#73)
- What changed: `.github/workflows/dart.yml` now pins Flutter 3.47.6 instead of the moving `stable` channel.
- Key files: `.github/workflows/dart.yml`.
- Notes / gotchas: newer stable deprecates `package:flutter/material.dart` (use `material_ui`), which made `flutter analyze` fail with 129 infos. Migrating off the deprecated imports is a separate task; bump the pin only together with that migration.

### 2026-11-25 — Add CLAUDE.md codebase guide (#71)
- What changed: new `CLAUDE.md` documenting commands, startup flow, structure, services, routing, state management (GetX), AI matching, backend (SQL scripts, edge functions, Cloudflare proxy), CI, and gotchas.
- Key files: `CLAUDE.md`.
- Notes / gotchas: docs only. Records that `.env` is bundled as a Flutter asset (keys ship in the app) and that README/ARCHITECTURE disagree with the code on state management and `.env`; neither was changed here.
