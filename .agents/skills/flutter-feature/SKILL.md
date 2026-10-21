---
name: flutter-feature
description: Guide for creating new features in CivicNet adhering to Feature-First Clean Architecture, state separation, and GoRouter integration.
---

# Feature-First Scaffolding Guide for CivicNet

Follow this workflow whenever creating a new feature module in `lib/features/<feature_name>/`.

---

## 1. Directory Structure

Each feature must be self-contained in its own directory under `lib/features/`:

```
lib/features/<feature_name>/
├── models/           # Data models (JSON serialization, Equatable/immutable)
├── viewmodels/       # Business logic, state notifiers, or change notifiers
├── views/            # UI screens and sub-widgets (stateless/presentation)
└── widgets/          # Feature-specific private widgets
```

---

## 2. Architectural Rules

1. **Isolation**: Never import private files from `lib/features/<another_feature>/`.
2. **Promotion Rule**: If a widget or utility is needed by 2 or more features, move it to `lib/components/` or `lib/core/`.
3. **State Management**:
   - UI views must remain dumb / presentation-focused.
   - Business logic, network calls, and async state belong in `ViewModel`.
   - Dispose all subscriptions, stream listeners, and animation controllers in `dispose()`.
4. **Services**:
   - Features access backend or device services via singleton providers (e.g., `SupabaseService.instance`, `AIService.instance`).

---

## 3. Navigation Integration (GoRouter)

When adding a new feature screen:
1. Declare route name and path constants in `lib/core/navigation/` or within the feature's view.
2. Register the `GoRoute` in the centralized router.
3. Support parameter passing and deep links gracefully.
