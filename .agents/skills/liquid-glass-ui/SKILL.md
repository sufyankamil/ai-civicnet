---
name: liquid-glass-ui
description: Design system guidelines, tokens, and widget recipes for CivicNet's Liquid Glass UI aesthetic.
---

# Liquid Glass UI Design System Guide

CivicNet features a bespoke "Liquid Glass" / "Premium AI Aura" aesthetic. Follow these guidelines for all UI work.

---

## 1. Color Palette & Tokens

- **Primary Violet Accent**: `#7B61FF`
- **Dark Backgrounds**: Deep slate / obsidian (`#0D0B18`, `#131124`)
- **Glass Surfaces**: Semi-transparent dark surfaces with inner satin gradients
- **High Contrast Text**: Pure white (`#FFFFFF`) for primary titles, soft lavender/muted slate for secondary labels (`#A09BB8`)

Never use arbitrary, hardcoded generic colors (plain red/blue/green). Always use tokens defined in `lib/theme/`.

---

## 2. Glassmorphism Recipe

To create a standard Liquid Glass container:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
          width: 1.5,
        ),
      ),
      child: content,
    ),
  ),
)
```

---

## 3. Micro-Animations & Haptics

- **Aura Glow**: Use subtle `BoxShadow` expansion to indicate active AI matching or high relevance.
- **Haptics**: Always call `AppHaptic.lightImpact()` or `AppHaptic.mediumImpact()` on button taps, swipe actions, and card acceptance to maintain tactile polish.
- **Hero & Slivers**: Use collapsing app bars with cross-fading titles and parallax headers for detail screens.
