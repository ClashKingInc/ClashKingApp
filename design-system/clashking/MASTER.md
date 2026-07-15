# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** ClashKing
**Platform:** Flutter (iOS + Android), native mobile app — not web
**Category:** Gaming / stats companion (Clash of Clans)
**Updated:** 2026-07-03 — rewritten to match the actual shipped app (see `lib/core/app/my_app.dart`); the previous auto-generated version described an unrelated web/CSS design system and should be disregarded.

---

## Global Rules

### Color Palette

Both themes are fully and symmetrically defined in `lib/core/app/my_app.dart` via `ColorScheme.fromSeed()`. This app supports light and dark mode (`ThemeMode.system` by default) — always design both, never assume one.

| Role | Dark | Light |
|------|------|-------|
| Seed | `#0B0B0C` | `#FFFFFF` |
| Primary | `#D90709` (red) | `#BF0000` (darker red) |
| Secondary | `#026CC2` (blue) | `#035293` (darker blue) |
| Tertiary | Grey | `#757575` |
| Surface | `#0B0B0C` | `#FFFFFF` |
| Scaffold background | `#030304` | `#F4F4F4` |

**Color Notes:** Red/blue Material palette, not the app's real visual signature — the more evocative colors are the per-stat accents used in headers/chips (war-star gold `0xFFE8A524`, capital purple `0xFF8D63D9`, builder-base blue `0xFF2A9FD6`, donation green, etc.). These should be centralized in `lib/common/theme/app_tokens.dart` (`StatColors`) rather than redefined per file.

### Typography

- **Font:** Roboto (system font, hardcoded string `'Roboto'` in `ThemeData`) — **not** a Google Fonts dependency.
- **Type scale:** Standard Material `TextTheme`, all weights `FontWeight.w500`:
  - Title: 24 / 20 / 18
  - Body: 16 / 14 / 12
  - Label: 12 / 10 / 8
- No display/headline variants defined — hero-header titles reuse `titleLarge` with manual weight overrides (`FontWeight.w800`) rather than a dedicated display style. Consider adding one if more hero-style screens are built.

### Radius Scale

Centralized in the shared Flutter package as `CKRadius` and exposed in the app
compatibility layer as `AppRadius`:

| Token | Value | Usage |
|-------|-------|-------|
| Button/input radius | `12px` | `ElevatedButtonTheme`, `InputDecorationTheme` |
| Chip/small-glass radius | `16px` | Chips, stat tiles, small glass elements |
| Tile radius | `20px` | Medium tiles smaller than section-level cards |
| Card/panel radius | `28px` | `CardTheme`, hero header stats panels (`NativeLiquidGlassBar`) |
| Pill radius | `999px` | Filter chips, badges, segmented controls |

### Spacing

Use `CKSpacing` for shared primitives and new reusable work. Existing app
screens still contain inline spacing values; when touching them, migrate toward
the common `4/8/12/16/24/32` scale instead of adding new values.

---

## Component Specs (Flutter, not CSS)

### Cards / Panels
```
CardTheme(
  elevation: 0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
  side: BorderSide(color: colorScheme.outlineVariant, width: ~1, alpha: 0.32),
  surfaceTintColor: Colors.transparent,
)
```
Shadows are minimal by design (elevation 0) — depth comes from the border + subtle background alpha, not drop shadows.

### Buttons
```
ElevatedButtonTheme(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  elevation: 5,
)
InputDecorationTheme(
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
)
```

### Hero / Glass panel system
`lib/common/widgets/native_liquid_glass.dart` — `NativeLiquidGlassBar`: renders true native Liquid Glass on iOS; Android falls back to a translucent card (`surfaceColor` alpha-blended, soft shadow, blur). Used for header stats panels, floating action buttons, segmented controls, tab bars. This is the app's actual visual signature — prefer it over flat `Card`/`Container` for any new floating surface.

### Chips / stat tiles
`lib/common/widgets/header_widgets.dart`'s `MetricChip`/`MetricChipGrid` is the reference implementation: icon-in-circle (26px) + label/value column (wrapped in `Flexible` to avoid overflow at narrow widths), tinted background when a stat color is supplied, neutral `surfaceContainerHighest` otherwise. `lib/common/widgets/buttons/chip.dart` (`ImageChip`/`IconChip`/`CustomChip`) and `lib/common/widgets/shapes/stat_tile.dart` are being unified to the same visual family (radius 16, `outlineVariant` border) as smaller siblings of `MetricChip` for use in dense grids (6-8 per row) — see the app's ongoing design-system-cleanup plan.

---

## Style Guidelines

**Style:** Material 3 + native iOS Liquid Glass (glassmorphism), applied through a "hero header" pattern.

**Pattern:** Detail screens (clan, player, legend, CWL, war, war-history, clan-capital, join-leave) use a fixed-height `Stack` with a `CachedNetworkImage` backdrop + dark scrim, an identity row (badge/crest + name/tag), and a floating glass stats panel (`MetricChipGrid`) — not a flat `AppBar`.

**Navigation model:** Bottom/side tab navigation for top-level sections (Dashboard, Clan, Players, War/CWL, Settings), hero-header detail screens reached by drilling in. No landing-page or nav-CTA concepts apply — this is a native app, not a marketing site.

---

## Anti-Patterns (Do NOT Use)

- ❌ **Emojis as icons** — use vector icons (Material Icons / `lucide_icons_flutter`, already a dependency). Live violation found in `clan_join_leave_stats.dart` (medal emojis) — fix, don't repeat.
- ❌ **Hardcoded non-theme-aware colors** (`Colors.white`/`Colors.black` with manual alpha for borders/fills) instead of `colorScheme.outlineVariant`/`surfaceContainerHighest` — breaks dark/light parity when the palette changes.
- ❌ **Icon-only buttons without a `tooltip:`** — several `IconButton`s in the app currently lack one; always add for accessibility.
- ❌ **Ignoring `MediaQuery.disableAnimations`/reduced-motion** — currently unhandled anywhere in the app; don't add more animations that ignore it.
- ❌ **Web-only concepts** — this is a native mobile app: no `cursor:pointer`, no hover-driven interaction, no CSS breakpoints (375/768/1024/1440), no horizontal-scroll concerns in the web sense. Design for touch, safe areas, and both portrait/landscape instead.
- ❌ **Duplicating stat colors** — reuse `StatColors` (once centralized) instead of re-declaring hex literals per file.

---

## Pre-Delivery Checklist (mobile-specific)

- [ ] No emojis used as icons (use `lucide_icons_flutter` / Material Icons)
- [ ] Icon-only `IconButton`s have a `tooltip:`
- [ ] Touch targets ≥44pt (iOS) / ≥48dp (Android)
- [ ] Dark **and** light theme both checked independently — don't assume one covers the other
- [ ] Text contrast ≥4.5:1 in both themes
- [ ] `Semantics`/screen-reader labels present on meaningful stat/list items
- [ ] Reduced-motion / `disableAnimations` respected for any new animation
- [ ] New floating surfaces use the glass/hero pattern (`NativeLiquidGlassBar`), not a flat `Card`, unless there's a specific reason to diverge
- [ ] Any new radius value fits the existing scale (12 / 16 / 28) rather than introducing a new one
- [ ] New user-facing strings go through `AppLocalizations` (see `lib/l10n/app_en.arb`), not hardcoded English
