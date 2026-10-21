---
name: code-simplifier-auditor
description: Comprehensive workflow to format, analyze, simplify, and audit Dart/Flutter code in CivicNet against Clean Architecture and AGENTS.md standards.
---

# Code Simplifier & Quality Auditor Workflow

Use this skill to audit, format, and simplify code across the CivicNet repository.

---

## 1. Automated Formatting & Analysis

Run the standard Dart & Flutter verification commands:

```zsh
# Format all dart files to standard Dart conventions:
dart format .

# Check for warnings, lint violations, and errors:
flutter analyze
```

---

## 2. Simplification Checklist

When reviewing or refactoring files in `lib/`:

### A. Widget Decomposition
- **Rule of Thumb**: Any `build()` method exceeding 80 lines should be decomposed.
- **Extract Sub-widgets**: Prefer extracting `StatelessWidget` classes rather than helper functions returning `Widget` (prevents unnecessary rebuilds and improves element tree diffing).

### B. State & Lifecycle Safety
- Ensure any `TextEditingController`, `ScrollController`, `AnimationController`, or `StreamSubscription` created in a `StatefulWidget` or `ViewModel` is explicitly cleaned up in `dispose()`.

### C. Clean Architecture Isolation
- Verify that no feature under `lib/features/<A>/` imports directly from `lib/features/<B>/`.
- Promote shared logic to `lib/core/` and shared widgets to `lib/components/`.

### D. Design System ("Liquid Glass UI") Compliance
- Replace arbitrary hardcoded colors with tokens from `lib/theme/` (primary violet `#7B61FF`, slate glass backgrounds).
- Ensure interactive buttons have tactile feedback via `AppHaptic`.
