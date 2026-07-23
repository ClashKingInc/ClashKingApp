# ClashKing App — Design System

This is the reference for the visual language shared by every detail screen in the app (clan, CWL, capital, war, player). It exists so new screens read as part of the same app instead of each reinventing header/tab/card conventions. When building or reviewing a screen, check it against this document.

The philosophy in one line: **one flat surface with rounded rows — never a card inside a card.**

## Contents
- [Tokens](#tokens)
- [Component catalog](#component-catalog)
- [Layout patterns](#layout-patterns)
- [Recipe: building a new detail screen](#recipe-building-a-new-detail-screen)
- [Known gaps](#known-gaps)

## Tokens

### Color
Defined in `lib/core/app/my_app.dart` as two Material 3 `ColorScheme`s (`_darkColorScheme` / `_lightColorScheme`), both generated via `ColorScheme.fromSeed`. Always read colors through `Theme.of(context).colorScheme`, never hardcode a hex value that duplicates one of these.

| Role | Dark | Light |
| --- | --- | --- |
| `primary` | `#D90709` | `#BF0000` |
| `secondary` | `#026CC2` | `#035293` |
| `tertiary` | `Colors.grey` | `#757575` |
| `surface` | `#0B0B0C` | `#FFFFFF` |
| `scaffoldBackgroundColor` | `#030304` | `#F4F4F4` |
| `error` | `#FF0000` | `#B00020` |

Widgets should use semantic roles (`colorScheme.onSurfaceVariant`, `colorScheme.outlineVariant`, `colorScheme.surfaceContainerHighest`) rather than `primary`/`secondary` directly, except where a color is intentionally branded (e.g. the primary CTA).

`StatColors` (`lib/common/theme/app_tokens.dart`) adds four recurring accent colors that aren't part of the Material scheme:

```dart
StatColors.warStarGold  // #E8A524 — war star / achievement gold
StatColors.win           // #14A37F — positive/won state
StatColors.loss          // #E35D4F — negative/lost state
StatColors.tie           // #026CC2 — neutral/ongoing state
```

Beyond these, screens commonly reach for plain `Colors.*` (`Colors.amber.shade700` for loot/gold, `Colors.blueAccent` for attack counts, `Colors.teal` for districts, `Colors.redAccent` for missed/failed) — consistent by convention rather than a token, since they map to game concepts (gold, swords, etc.) more than UI state.

**Never hardcode `Colors.white`/`Colors.black` for text or icons that sit on a themed background — including hero headers.** It's tempting on a hero header, since the identity/back-button area sits on a photo darkened by a *fixed* `Colors.black.withValues(alpha: 0.50)` filter that looks the same in both themes — but the gradient scrim layered on top of that photo (`colorScheme.surface` at increasing alpha toward the bottom) is *not* theme-independent: `surface` is near-black in dark mode and near-white in light mode. Text placed where that gradient is already 60–90% opaque effectively sits on `colorScheme.surface`, not on the photo — hardcoded white text becomes white-on-near-white and disappears in light mode. Use `colorScheme.onSurface` (white in dark theme, black in light theme — same visual result in dark mode, correct contrast in light mode) for any text/icon inside a hero header's identity block, description, or stats-adjacent area. This was an actual bug (confirmed on-device) in all three hero headers before being fixed; watch for it if you copy the hero header pattern into a new screen.

### Typography
Single `TextTheme` (`ClashKing`, using the bundled static SemiBold face) shared by both themes, colored white in dark / black in light. The first font release covers Basic Latin plus common smart quotes and dashes; Flutter falls back to the platform sans for unsupported localized characters.

| Style | Size |
| --- | --- |
| `titleLarge` | 24 |
| `titleMedium` | 20 |
| `titleSmall` | 18 |
| `bodyLarge` | 16 |
| `bodyMedium` | 14 |
| `bodySmall` | 12 |
| `labelLarge` | 12 |
| `labelMedium` | 10 |
| `labelSmall` | 8 |

Component code almost always overrides `fontWeight` per role (`w600`–`w900` for values/titles, `w600`–`w700` for muted labels) rather than relying on the base weight — see any `ClanSummaryChip`/row widget for the pattern.

### Radius & opacity
`lib/common/theme/app_tokens.dart`:

```dart
AppRadius.chip   // 16 — list rows, small tiles
AppRadius.card   // 20 — section-level panels (raid/war summary cards, empty states)
AppRadius.pill   // 999 — filter/summary chips, status badges

AppOpacity.border        // 0.28 — default flat-card/row border alpha
AppOpacity.borderStrong  // 0.32 — border for a panel sitting directly under a header/tab bar
AppOpacity.fillMuted     // 0.45 — muted icon-circle/pill background fill
```

Two radii predate this token set and stay defined directly in `ThemeData` rather than here: the legacy `Card` radius (28, `cardTheme` in `my_app.dart`) and button/input radius (12, `elevatedButtonTheme`/`inputDecorationTheme`). New screens should not use `Card` at all (see [Layout patterns](#layout-patterns)), so in practice only the 12px button/input radius is still relevant from that set.

These tokens are the *target* for new code — not every existing widget in the app has been retrofitted to reference them by name, some still repeat the literal numbers. Prefer the token in anything you write or touch.

### Icons
Two tiers, by what the icon represents:
1. **Game/CoC concepts** (swords, war, capital gold, stars, medals, town halls, leagues...) → the branded `ImageAssets.*` game-asset images (e.g. `ImageAssets.cwlSwordsNoBorder`, `ImageAssets.sword`, `ImageAssets.capitalGold`), passed as `imageUrl` wherever a chip/tile/tab supports it. Prefer these over any generic icon when a CoC-branded asset exists for the concept — see the `feedback_coc_asset_icons_priority` project convention.
2. **Generic UI actions/concepts** (filter, search, shuffle, warning, chevron, calendar...) → **Material Icons**, `_rounded` variant, matching the app's rounded-corner language.

`lucide_icons_flutter` (`LucideIcons.*`) was a legacy leftover from before this system and has been fully removed from the clan/CWL/capital/player-war-stats screens (swapped to the two tiers above, e.g. `LucideIcons.swords` → `ImageAssets.cwlSwordsNoBorder`, `LucideIcons.shuffle`/`.handshake`/`.listFilter`/`.searchX` → their direct `Icons.*_rounded` equivalents). It still appears in a few screens outside that scope (`filter_dropdown.dart`, `clan_members.dart`, the FAQ page, some search/filter dialogs) — don't add new `LucideIcons.*` usage anywhere; migrate opportunistically when touching those files.

## Component catalog

All in `lib/common/widgets/`.

### `summary_chips.dart`
- **`ClanSummaryChip`** — read-only stat pill: dot-or-icon, bold value, muted label. `color` tints the icon/value; omit it for a neutral chip. Optional `onTap` wraps it in a tooltip + ripple.
- **`ClanSummaryChips`** — lays out a list of chips either as a horizontally-scrolling `Row` (`scrollable: true`, default — for a header's stat rail) or a wrapping `Wrap` (`scrollable: false` — for a tab body where wrapping to a second line is fine).
- **`ClanFilterChip`** — tappable filter pill, same visual family as `ClanSummaryChip` but `selected`/`onTap` driven (a toggle, not a display value).
- **`ClanFilterRail`** — horizontal-scroll rail for `ClanFilterChip`s.

### `search_sort_bar.dart`
- **`ClanTabSearchSortBar`** — glass search `TextField` (via `LiquidGlassBar`) + compact sort `FilterDropdown`, the standard header for any searchable/sortable list (clan members, war log, capital raid members...).

### `header_widgets.dart`
- **`HeaderIconButton`** — frosted circular icon button that floats over a hero header image. `showBackground: false` for a borderless icon-only variant (used for the back button so it doesn't compete visually with header content).
- **`CompactLeagueTile`** — league/rank tile: badge image, name, one-line subtitle (with optional small icon), optional chevron if `onTap` is set. The standard "featured stat" tile in a header's stats panel (war league, capital league, CWL rank...).
- **`MetricChip`** / **`MetricChipGrid`** — icon-in-circle + label/value chip, laid out N-per-row at equal width. Used less often than `ClanSummaryChip` now; prefer `ClanSummaryChip` for new work unless you specifically need the grid layout.
- **`GlassPanel`** — small floating glass card via `LiquidGlassBar`, optionally tinted via `dominantTintFromImage`/`LeagueTint` to pick up a badge's dominant color.
- **`LeagueSummaryTile`** — the full-size version of `CompactLeagueTile`: badge, league name, large trophy count, season label, and a secondary attack/defense-wins or best-trophies row. Used where there's room for one prominent tile rather than two compact ones side by side (originally the player header's hero league tile).
- **`MetricBar`** — tinted metric row (icon-in-circle + label/value + optional chevron), fixed 40px height; fills whatever width its parent gives it (not self-widening), used for single prominent stats.

### `liquid_glass.dart`
Thin wrapper layer around the [`liquid_glass_widgets`](https://pub.dev/packages/liquid_glass_widgets) package. It stays inside Flutter's compositor on every platform and never creates a UIKit platform view. Every consumer goes through these wrappers so tint, blur, border, and performance settings remain centrally tunable:
- **`LiquidGlassBar`** — the shared glass background for tab bars, search fields, header panels and buttons. Backed by `glass.GlassContainer(useOwnLayer: true)`; tint (`opacity`), `borderOpacity` and `shadowOpacity` are real Dart params honored identically on every platform.
- **`LiquidGlassIconButton`** — frosted round button via `glass.GlassIconButton`, built-in squash/press feedback.
- **`LiquidGlassSegmentedControl<T>`** — filter/mode toggles via `glass.GlassSegmentedControl`.
- The app's bottom navigation bar (`my_home_page.dart`) uses `LiquidGlassTabBar`, which delegates to the placement-aware `GlassTabBar.bottom` layout.
- Setup: `LiquidGlassWidgets.initialize()` + `LiquidGlassWidgets.wrap(child: ...)` around the app root in `main.dart` (shader pre-warm + accessibility bridging + theming — see package README "Quick Start"). No per-widget setup needed beyond that.

## Layout patterns

Reference implementation for all four: `lib/features/clan/presentation/clan_capital/` (the most recently built, most complete example).

### 1. Hero header
Background image → dark `ColorFilter`/gradient overlay fading down to `colorScheme.surface` → a `Column` on top with: back button (`HeaderIconButton`, `showBackground: false`, white icon) → centered identity block (badge/image + name + tag, white text since it sits on the darkened image) → stats panel (1–2 `CompactLeagueTile`s side by side, then optional quick-chip rows).

```dart
Stack(
  children: [
    Positioned(top: 0, left: 0, right: 0, height: imageHeight,
      child: Stack(fit: StackFit.expand, children: [
        ColorFiltered(colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.50), BlendMode.darken),
          child: CachedNetworkImage(imageUrl: ..., fit: BoxFit.cover)),
        DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [surface@0.36, surface@0.64, surface@0.92]))),
      ]),
    ),
    Column(children: [
      SizedBox(height: MediaQuery.of(context).padding.top),
      /* back button row */,
      /* identity block */,
      /* stats panel */,
    ]),
  ],
)
```
Reference: `clan_info/clan_header.dart`, `clan_capital/clan_capital_header.dart`, `war_cwl/cwl.dart`'s `_CwlHeaderCard`.

### 2. Tab bar
`LiquidGlassBar` background + `TabBar` with icon+label tabs (image or `IconData`, dimmed when unselected via `onSurface.withValues(alpha: 0.58)`). The `TabController` is driven by an **external `int selectedTab` held in the parent**, not `TabBarView` — content below crossfades via `AnimatedSwitcher` + `KeyedSubtree(key: ValueKey(selectedTab))`. This lets the parent share state (e.g. a selected week, or war-type filters) between tabs without each tab owning an independent copy.

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 180),
  switchInCurve: Curves.easeOutCubic,
  switchOutCurve: Curves.easeOutCubic,
  child: KeyedSubtree(
    key: ValueKey(selectedTab),
    child: switch (selectedTab) {
      0 => FirstTab(...),
      _ => SecondTab(...),
    },
  ),
)
```
Reference: `clan_info/clan_page.dart`'s `_ClanProfileTabs`, `clan_capital/clan_capital_page.dart`'s `_CapitalProfileTabs`, `war_cwl/cwl.dart`'s `_CwlProfileTabs`.

### 3. Flat card/row — no nested `Card`
Every panel and list row is a plain `Container`, never Flutter's `Card` widget:

```dart
Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  decoration: BoxDecoration(
    color: Theme.of(context).cardTheme.color ?? colorScheme.surface,
    borderRadius: BorderRadius.circular(AppRadius.chip), // or AppRadius.card for a section panel
    border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: AppOpacity.border)),
  ),
  child: ...,
)
```
A row never wraps another bordered container of the same weight inside it — that's the "card in a card" smell this system exists to avoid. Nested content (e.g. an expandable attacker list inside an opponent row) uses lighter-weight children (plain `Row`/`Column`/`Text`, or an `AnimatedCrossFade` reveal) instead of a second bordered box.

Reference: `clan_capital/clan_capital_details.dart`'s `_DistrictRow`/`_OpponentRow`, `clan_info/clan_page.dart`'s `_JoinLeaveEventCard`.

### 4. Empty states
Same flat-container recipe, with a circular icon badge instead of stat content:

```dart
Row(children: [
  Container(width: 38, height: 38,
    decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest.withValues(alpha: AppOpacity.fillMuted), shape: BoxShape.circle),
    child: Icon(icon, color: colorScheme.onSurfaceVariant)),
  const SizedBox(width: 12),
  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: bodyMedium.copyWith(fontWeight: FontWeight.w900)),
    Text(body, style: bodySmall.copyWith(color: onSurfaceVariant, fontWeight: FontWeight.w600)),
  ])),
])
```
Never a bare `Card` with a single line of text. Reference: `clan_info/clan_page.dart`'s `_ClanEmptyTab`, `clan_capital/clan_capital_page.dart`'s `_CapitalEmptyState`.

## Recipe: building a new detail screen

1. **Header** — hero header pattern (background image, gradient, back button, identity, stats panel with `CompactLeagueTile`s).
2. **Tabs** (if the screen has more than one logical section) — `LiquidGlassBar` + `TabBar`, external `selectedTab` state, `AnimatedSwitcher`.
3. **Content** — flat `Container` rows/panels for every list item and summary block; `ClanSummaryChip(s)` for read-only stats, `ClanFilterChip`/`ClanFilterRail` for toggles, `ClanTabSearchSortBar` if the tab is a searchable list.
4. **Empty/error states** — the empty-state recipe above, not a raw `Card`.
5. Before considering it done: does any screen area show two bordered containers nested inside each other? If yes, flatten it.

## Known gaps
- **Touch target size**: `HeaderIconButton` is 42×42 — under the 44×44pt minimum (Apple HIG) / 48×48dp (Material). It's used across every hero header's back/action buttons, so bumping it needs checking every header that hardcodes a `SizedBox(height: 42)` row around it (e.g. `_CwlHeaderActions`) to avoid clipping. Flagged, not fixed — do this as its own pass, not bundled into an unrelated screen change.
- `clan_info/clan_page.dart` has a richer filter row than `ClanFilterRail`/`ClanFilterChip`: a private `_FilterBar`/`_FilterPill`/`_FilterActionButton` (icon toggle that reveals a `Wrap` of chips on demand, plus optional trailing action icons and a middle `ClanSummaryChips` slot) already shared internally between its War Log and Statistics tabs. It isn't promoted to `common/widgets/` yet, so `clan_capital`/`cwl` screens fall back to the simpler always-visible `ClanFilterRail`. Worth promoting if a screen needs the collapsible behavior.
- Not every existing card/row in the app has been retrofitted to reference `AppRadius`/`AppOpacity` by name — some still repeat the literal numbers (16/20/0.28/0.32/etc). Prefer the token in new/touched code; a full retrofit hasn't been done.
- **Bespoke chip reimplementations**: several screens hand-roll their own icon+value pill instead of `ClanSummaryChip`/`ClanFilterChip` — `clan_header.dart`'s `_ClanQuickChip`/`_ClanChipRows`, `clan_members.dart`'s `_SortValueChip`, `pages/clan_page.dart`'s `_AccountCountChip`/`_ClanImageChip`/`_ClanIconChip`/`_ClanChipShell`, `players_page.dart`'s `_InfoChip`, `player_war_stats_profile_tab.dart`'s `_WarTypeChip`. Most have a genuine reason (image-vs-icon leading slot, different sizing, a `Wrap`-based auto-layout `ClanSummaryChip` doesn't do) rather than being pure duplication — audit case by case before consolidating, don't blanket-replace.
- **`Card` still used outside the migrated screens**: clan/CWL/capital/player-war-stats no longer use `Card` (the three instances found in `cwl_team_card.dart`/`cwl_member_card.dart`/`cwl_round_card.dart` were converted to the flat pattern). Plenty of `Card` usage remains elsewhere — auth flow dialogs (`forgot_password`, `reset_password`, `email_verification`, `account_management`), `clan_search_filters_dialog.dart`, and a handful of simple empty-state placeholders (`clan_war_log.dart`, `clan_members.dart`, `pages/clan_page.dart`, `player_legend_by_day.dart`). These are outside this system's current scope (mostly dialogs/simple lists, not the hero-header detail screens this document targets) — migrate opportunistically, not as a forced sweep.
- This document currently covers the Flutter app only. If `ClashKingDashboard` (web) ever needs to share visual identity, only the token layer (color/radius/opacity values, not the Flutter widgets themselves) would be portable — see the "design system repo" discussion in project history for why a shared component library isn't feasible across Flutter and web.
