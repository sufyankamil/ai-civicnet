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

### Static Analysis & Verification
```zsh
# Verify code health before completing tasks:
flutter analyze
```

---

## 5. Agent Verification Checklist

Before considering any task complete:
1. Run `flutter analyze` and confirm 0 errors or warnings introduced.
2. Verify cross-platform UI responsiveness (check both iOS and Android layouts).
3. Ensure no `.env` or sensitive credentials were accidentally staged or committed.
4. Verify that newly added assets or fonts are declared in `pubspec.yaml`.
