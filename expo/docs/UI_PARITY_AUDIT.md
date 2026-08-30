# Flutter to Expo code-level UI parity audit

Audited against Flutter commit `23171c5c5dcb0560799890f6533bd98f32cd06fb` on
2026-08-30. This audit used source inspection, import-graph reachability, TypeScript,
ESLint, Jest, localization parity, asset parity, and manifest regeneration. It did
not use browser, simulator, emulator, screenshot, or other visual testing.

## Route and feature reachability

The Expo application root reaches all Flutter-authenticated route families: the
four retained primary tabs (Home, Players, Clans, War), Search, Posts, Rankings,
Stats, Calculators, Subscription, To-do, Ranked League, Upgrade Tracker, Bases &
Armies, Game Assets, linked-account management, Settings, and Achievements. The
same mobile/desktop route differences and feature gates are declared in
`src/navigation/route-manifest.ts`. Player, clan, Clan Capital, war, and CWL
details are represented as pushed scenes in `src/core/app/authenticated-root.tsx`.

Authentication reachability covers startup, login, registration, email
verification, forgot/reset password, first-account setup, maintenance, retry,
and the verified-account gate through `src/core/app/application-root.tsx` and
`src/core/app/startup-coordinator.ts`.

## Non-player parity reconciliation

Every reachable shared UI, core, achievements, auth, clan, linked-account,
game-assets, pages, rankings, settings, stats, upgrade-tracker, and war/CWL
source now names its concrete Expo implementation and focused contract evidence
in `parity-overrides.json`. The independent review passes closed the remaining
behavior gaps: linked-account verification refreshes transferred accounts and
retains Flutter's selected-account rules; startup and post-login both require a
verified account; the upgrade-tracker picker is restricted to verified links;
search, posts, announcements, subscription, and calculator controls honor the
selected locale's direction and exact conditional states; and notification-open
routes wait for authenticated navigation instead of being lost at cold start.

The clan war log retains Flutter's result, perfect-war, team-size, type, search,
and ordering filters. Clan tabs now remain mounted, reset their shared outer
scroll on selection, and automatically request the next join/leave page within
500 pixels of the end. Selected-locale number and date formatting is applied to
Clan Capital, the upgrade tracker, and all audited summary variants.

## Player-detail parity follow-up

The four player-detail gaps found by the first pass were ported against their
reachable Flutter sources. Item tiles now route ordinary items through the shared
upgrade-detail presentation and retain Flutter's distinct super-troop dialog;
TH progress, remaining time/resources, equipment rarity, locked styling, subtype
queue/category mapping, weights, per-level costs, and unlock/stat sections are
covered by `player-item-section.test.tsx` and `player-item-adapter.test.ts`.

War statistics now retain all three default quick types, applied-filter summaries,
clear behavior, the six built-in presets, generated performance suggestions,
saved preset equivalence plus long-press apply/rename/delete flows, and the
all-time/season/custom date controls. The filter sheet is capped at 80% of the
viewport with a scrollable body, and the TH/star/destruction/map/limit controls,
localized explanations, confirmation, export, and generated-file open flow match
their reachable Flutter branches. The production export body and Excel response
contract are isolated and covered by `player-war-filter-state.test.ts`,
`player-history-presentation.test.tsx`, and `player-war-export.test.ts`.

Attack and defense history now matches Flutter's accent/performance rows,
directional swipe actions, progressive rendering, type quick filters, and full
detail sheet. The detail sheet includes war metadata and timing, clan comparison,
attacker/defender snapshots, and the town-hall matchup matrix. Completed history
without an explicit live state is projected as `warEnded`, matching the endpoint's
completed-war semantics.

Join/leave now uses Flutter's History/Clan totals dropdown, compact expandable
filter bar, summary rail, event rows, clan totals, and automatic near-end cursor
pagination. Existing rows remain visible while one skeleton row is appended, and
a pagination failure silently permits the next near-end scroll to retry. Player
achievements are informational and grouped into Home/Others with completion counts,
incomplete-first sorting, progress bars, compact counts, completed styling, and the special
three-star completion rules for Dragon Slayer and Ungrateful Child. Both paths
are covered by `player-detail-screen.test.tsx`.

Visited player tabs remain mounted like Flutter's retained `TabBarView`, so item
expansion, battle mode, filters, and pagination survive tab changes. Active super
troops occupy the first responsive-grid slot, and the empty league label preserves
Flutter's exact `Unranked` copy.

## War and CWL parity follow-up

CWL rounds now preserve Flutter's preparation/current/prior ordering, timing,
attack counts, perfect-war results, and actionable states. Missing-data screens
retain the Back escape hatch, inactive banners do not advertise unavailable
actions, and nested CWL-to-war navigation returns to the correct parent.

War attack details are scrollable and include type, stars, destruction, attack
order, conditional duration, and both participants. Previous-war resolution uses
the deployed path-parameter API route; stale Flutter query and bulk-war transport
calls were deliberately not carried forward.

## Shell and web parity follow-up

The selected locale now restores with Flutter's ordered picker fallback, including
`en` resolving to `en_GB` and hidden Hindi/Urdu catalogs falling back to English.
The retained native pager resynchronizes its logical page without animation when
the selected locale changes between LTR and RTL, preserving all mounted tab state.

Flutter web uses unnamed Navigator 1.0 routes and single-entry browser history:
the URL remains `/`, reload discards the secondary stack, forward reconstruction
is absent, and desktop nested content is not popped by root browser Back. Expo's
local secondary stack intentionally retains those exact semantics; a drafted
semantic-history layer was removed because it would have changed user behavior.
The static export keeps Flutter's byte-identical favicon and splash/icon rasters,
without Expo's duplicate generated ICO. The stale Flutter template description
was replaced with the same ClashKing product copy used by the HTML document.

## Dead Flutter inventory

A static import graph from `lib/main.dart` reaches 302 of 329 Dart files. The
following 27 files have no reachable import and are verified with the `remove`
disposition after exact import, declaration, product, runtime, native, test, and
tooling searches found no reachable consumer. The frozen Flutter files were not
deleted:

- `lib/common/widgets/buttons/chip.dart`
- `lib/common/widgets/buttons/pulsating_chip.dart`
- `lib/common/widgets/labels/beta_label.dart`
- `lib/common/widgets/navigation/scrollable_tab.dart`
- `lib/common/widgets/shapes/stat_tile.dart`
- `lib/core/functions/legend_functions.dart`
- `lib/features/pages/widgets/clan_search_result_tiles.dart`
- `lib/features/pages/widgets/cwl_war_card.dart`
- `lib/features/pages/widgets/player_search_result_tile.dart`
- `lib/features/player/models/player_legend_spot_data.dart`
- `lib/features/player/presentation/legend/player_legend_by_day.dart`
- `lib/features/player/presentation/legend/player_legend_header.dart`
- `lib/features/player/presentation/legend/player_legend_history.dart`
- `lib/features/player/presentation/legend/player_legend_page.dart`
- `lib/features/player/presentation/legend/player_legend_season.dart`
- all nine files under `lib/features/player/presentation/legend/widgets/`
- `lib/features/player/presentation/player/player_season_stats_tab.dart`
- `lib/features/war_cwl/presentation/war_stats/clan_war_stats_filter_dialog.dart`
- `lib/l10n/update_arb.dart`

Generated locale implementations and conditional platform imports were included
in the graph; the list above excludes those false positives.

## Unreachable Expo inventory

The current production TypeScript import graph has no unreachable implementation
files outside the player-detail follow-up described above. Four unreachable
files are intentional public aggregation barrels and are retained:
`src/features/achievements/index.ts`, `src/features/home/index.ts`,
`src/features/notifications/debug/index.ts`, and
`src/features/settings/app-icons/index.ts`. They provide stable feature import
surfaces without adding runtime code.

The unreferenced `src/core/dto/serialization.ts` implementation has been removed.
Declaration-level inspection also proved that `AnnouncementWebViewPage`,
`HeroHeader`, `MetricChip`, `SummaryPill`, `MetricGrid`, `ProfileTabPanel`, and
`TileSurface` had no production, test, native, tooling, or public-package
consumer. Those implementations and the now-empty `src/ui/metrics.tsx` module
have been removed. The separately owned player-detail follow-up also removed
`RankedLeagueScreen` after confirming it had no caller.

## Validation

- `npx prettier --check .`, `npx eslint . --no-cache`, and `npm run typecheck`
  completed without errors or warnings.
- The full Jest run passed 137 suites and 603 tests. Native config-plugin tests
  passed 29 tests, and web service-worker tooling passed both tests.
- Localization generation/parity, byte-level Flutter asset parity, the production
  license inventory, the 23-file Expo E2E structure gate, and Expo Doctor's 21
  checks all passed.
- The regenerated parity ledger contains 736 exhaustive source entries: 735
  verified and one explicitly backend-blocked raid-reminder persistence entry.
- A production-mode static web export passed. The callback documents, manifest,
  headers, redirects, and service worker were present; all 12 Flutter favicon,
  splash, and PWA icon rasters remained byte-identical through export, with one
  PNG favicon link per page and no generated ICO.
- A clean isolated Android CNG prebuild and `:app:assembleDebug` completed 712
  Gradle tasks. The packaged APK excludes `SYSTEM_ALERT_WINDOW`, both legacy
  storage permissions, and retains the audited deep links, widgets, receiver,
  and background task service.
- A clean isolated iOS CNG prebuild, 145-pod install, and unsigned generic-device
  `xcodebuild` compiled the arm64 app, local native module, and embedded
  `WarWidgetExtension` with the retained bundle IDs, app group, and keychain group.
- JSON, plist, workflow YAML, shell syntax, stale-endpoint, removed-symbol, and
  frozen-Flutter-source checks passed.

Visual acceptance and interactive browser/device behavior remain for the user's
manual review, as requested. Native compilation and the static web artifact are verified.
