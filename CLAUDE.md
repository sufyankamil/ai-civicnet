# CLAUDE.md

Orientation guide for working in this repo. Rules and workflow (GitHub issue first, never commit to `main`, TDD, Feature Log, design rules) live in [AGENTS.md](AGENTS.md). Read that first and read its Feature Log before starting any task. This file maps how the app is actually built.

## What this is

CivicNet (`civic_net`, v1.1.10+51 in `pubspec.yaml`) is a Flutter app (iOS, Android, web) that connects people who need help with nearby neighbors. Backend is Supabase, AI is Google Gemini, push is Firebase. Dart SDK `^3.9.2`.

## Commands

```bash
flutter pub get
flutter run -d <device-id>      # list ids with: flutter devices
flutter analyze                 # CI runs this on every push/PR to main
flutter test                    # only test/service_health_service_test.dart exists today
dart format .
```

- Localization is generated (`generate: true`, `l10n.yaml`): edit `lib/l10n/app_en.arb` and `app_hi.arb`, then `flutter pub get` regenerates `app_localizations*.dart`.
- Config comes from `.env` (copy `.env.example`): `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `GOOGLE_MAPS_API_KEY`, optional `ENCRYPTION_KEY`. `.env` is git-ignored. `GEMINI_API_KEY` is no longer read by the app: it is an `ai-proxy` edge function secret (`supabase secrets set GEMINI_API_KEY=...`).
- `ios/Runner.xcodeproj/project.pbxproj` gets rewritten by Flutter builds. Do not commit that noise.

## Startup flow (`lib/main.dart`)

1. `main()` locks orientation to portrait, then runs `RootApp`.
2. `RootApp._initApp()` shows a splash (min 2s) while it: inits Hive, loads `.env`, opens `SharedPreferences` (global `prefsGlobal`), bumps `app_launch_count`, registers GetX bindings (`initAuthDI`, `HomeBinding`, `initRequestDI`, `initMapDI`, `initChatDI`, `initEventsDI`, `initAssetsDI`, `ProfileBinding`), then checks the initial deep link (password recovery goes to `/reset-password`).
3. `StartupService().initialize()` (`lib/services/startup_service.dart`) sets up encryption, Firebase, `AiService`, Crashlytics, Supabase (with a device-info User-Agent), notifications, and the service-health monitor. It is guarded so a second call only reschedules the daily notification.
4. On failure `RootApp` shows an error screen with a retry.

`lib/core/di/injection.dart` (`initDI`) is an empty placeholder. Real DI lives in each feature's `di/` folder.

## Structure

```
lib/
├── main.dart            entry, init, root widget
├── core/                routes/app_router.dart, di/, errors/, usecases/, utils/, services/, presentation/layouts (MainScaffold), screens (NotFound)
├── features/            activity, ai_assistant, assets, auth, chat, discover, events, home, map,
│                        news, notifications, onboarding, profile, request
├── services/            singleton infrastructure (see below)
├── components/          shared widgets: cards, skeletons, dialogs, glass/glow borders, buttons
├── widgets/             app-wide wrappers: AutoLogout, Connectivity, ServiceHealth banner/wrapper, haptic buttons
├── theme/app_theme.dart light/dark ThemeData and color constants (Poppins font)
├── models/models.dart   shared models
└── l10n/                en + hi ARB files and generated localizations
```

The larger features (auth, chat, request) follow `data/ domain/ presentation/ di/`; the others are lighter (often just `presentation/`, plus `models/` and `di/`). Request, chat and auth use repository + use case layers; much of the rest talks to `SupabaseService` directly.

### Services (`lib/services/`)

All are singletons (`Foo()` factory) except where noted.

| File | Role |
|---|---|
| `supabase_service.dart` | Very large (~3,100 lines). Auth, queries, RPCs, realtime, sessions, chat keys |
| `ai_service.dart`, `ai_gateway.dart` | Gemini features (embeddings, categorization, voice-task parsing, search query, chat/support replies, community briefing). All calls go through `AiGateway` to the `ai-proxy` edge function, which enforces the monthly free AI quota; metered methods throw `AiQuotaExceededException` |
| `startup_service.dart` | One-time app initialization |
| `encryption_service.dart` | Per-conversation AES with RSA-OAEP wrapped keys (keys in secure storage). Legacy global-key decrypt kept for migration |
| `notification_service.dart`, `firebase_service.dart` | FCM, local notifications, daily check-in |
| `service_health_service.dart` | Tracks backend failures/recoveries and drives the status banner. The only unit-tested service |
| `cache_service.dart`, `storage_service.dart`, `theme_service.dart`, `toast_service.dart`, `pending_toast_service.dart`, `logger_service.dart` | Local cache, storage, theme mode, toasts, logging (`logger`) |
| `biometric_service.dart`, `rating_service.dart`, `bug_report_service.dart`, `pdf_service.dart` | Local auth, in-app review, bug reports, PDF export |

## Routing (`lib/core/routes/app_router.dart`)

`go_router`, built by `createRouter()`. `refreshListenable` follows Supabase `onAuthStateChange`.

- **Redirect rules:** logged out on `/` or `/home` goes to `/onboarding` (first time) or `/login`. Logged out on a protected tab (`/profile*`, `/chat`, `/activity`, `/discover`, `/map`, `/events`) goes to `/login`. Logged in on `/`, `/login`, `/signup` or `/onboarding` goes to `/auth-check`, which decides between the app and `/complete-profile`.
- **Shell (bottom tabs, `MainScaffold`):** `/home`, `/discover`, `/activity`, `/map`, `/chat`, `/profile`, `/events`.
- **Full-screen routes:** `/create-request`, `/request/:id`, `/chat-detail`, `/event/:id`, `/create-event`, `/profile/:id`, `/ai-assistant`, `/settings`, `/notifications`, `/my-assets`, `/asset-library`, `/support`, `/admin-panel`, and the legal/account screens.
- Adding a screen: add the route here and keep the redirect list in sync if it must be login-protected.

## State management

The code uses **GetX** (`get`, in ~44 files): `GetxController`/`Bindings`, `Get.lazyPut`, `Get.find`. `provider` is imported in only 2 files, and plain `ChangeNotifier` is used by `ServiceHealthService`, `ThemeService` and the router's refresh helper. `README.md` says Provider and `ARCHITECTURE.md` says GetX; the code is mostly GetX. Follow what the surrounding feature does. Each feature's `di/*Binding` wires data source → repository → use cases → view model.

## AI matching

`AiService` produces Gemini embeddings. `SupabaseService` calls the `match_requests_v3` RPC (see `lib/services/supabase_service.dart`, defined in `sql_scripts/ai_vector_setup.sql`) to rank requests by vector similarity, then the app combines that with distance and urgency. Thresholds are described in `ARCHITECTURE.md`.

## Backend

- **Supabase SQL:** `sql_scripts/` (core schemas, vector setup, RLS/security hardening, chat, polls, ratings, karma, points, blocking, guilds, support) and `supabase/` (admin roles, announcements, verification requests, holiday notification scheduling, `config.toml`). `sql_scripts/SECURITY_HARDENING.md` covers hardening notes. There is no numbered migration chain: scripts are applied by hand, so check which ones a database already has.
- **Edge functions (`supabase/functions/`, Deno):** `notify-new-message`, `notify-new-request`, `notify-interest`, `send-holiday-notification`.
- **`cloudflare_proxy/`:** a Cloudflare Worker that proxies requests (including websockets) to the Supabase project host, which is hard-coded in `index.js`.
- **`website/`:** static pages (terms, child safety, delete account, reset) deployed with Vercel.

## CI / release (`.github/workflows/`)

- `dart.yml`: `flutter analyze` on pushes and PRs to `main` (no tests run in CI).
- `testflight.yml`, `app-store-release.yml`: manual (`workflow_dispatch`) uploads. App Store notes come from the `whats_new` input, not from `CHANGELOG.md` automatically. `CHANGELOG.md` is only the App Store "What's New" text and is behind `pubspec.yaml` (1.1.8 vs 1.1.10).

## Gotchas

- **`.env` is bundled as a Flutter asset** (`pubspec.yaml` lists `.env` under assets), so everything in it ships inside the app binary. Treat `ENCRYPTION_KEY` as exposed to anyone with the app (Gemini calls now go through the `ai-proxy` edge function, so that key is no longer bundled; remove it from local and CI `.env` files and rotate any key that shipped before), and do not put server-side secrets there.
- **Portrait only**, set in both `main.dart` and `ios/Runner/Info.plist`.
- **Tests are thin:** one test file. New work should add tests per AGENTS.md; widget tests need Supabase/Firebase mocked because most screens depend on them.
- **Theme colors:** `lib/theme/app_theme.dart` holds the palette (primary `#7B61FF`); reuse those constants instead of new hex values.
- **Large files:** `supabase_service.dart` is huge and shared by every feature. Prefer adding focused methods to the relevant feature's data source over growing it further.
- **Flutter plugins without Swift Package Manager support** (`google_maps_flutter_ios`, `permission_handler_apple`, `printing`, `sign_in_with_apple`, `vpn_connection_detector`) print a warning on iOS builds. It is only a warning today.
- **Docs disagree in places:** `README.md` says no `.env` setup is needed, while the code requires one. Trust the code.
