# Local analytics UI revision — 23 September 2026

This revision is local only. No production deployment, browser test, simulator test, or physical-device visual verification was performed.

## Settings and notifications follow-up

The Linked → Players handoff now dismisses the outer native Settings route instead of only clearing its content. Content remains mounted until native removal, avoiding an empty black route during dismissal. Unit and bundled-navigation integration tests cover this handoff, multiple secondary layers, and unchanged gesture-back behavior. The subsequent full suite passed 239 suites / 1,362 tests.

The system-settings action now targets the notification panel specifically: `app-settings:notifications` on iOS and `android.settings.APP_NOTIFICATION_SETTINGS` with the installed application ID on Android. General app settings is only the failure fallback. This uses existing bridges and requires no native module rebuild. References: [Apple notification settings destination](https://developer.apple.com/documentation/uikit/uiapplication/opennotificationsettingsurlstring), [Android notification settings intent](https://developer.android.com/reference/android/provider/Settings#ACTION_APP_NOTIFICATION_SETTINGS). Five additional tests cover platform routing, fallback, and failure propagation; device handoff behavior has not been visually tested.

Settings no longer offers Add War Widget; existing widget cache synchronization remains intact. Notifications reuses the shared settings rows and selection picker: system permissions open device settings (or explicitly request initial permission), account controls link to Players → Linked → Options, and retired war attack/state categories are absent. The local iOS test tool offers ten notification types. The permission explanation points users to Settings for later adjustments.

New preferences enable the four supported general categories. Existing saved choices are preserved, account opt-in stays explicit, and war/raid reminders remain off with empty timings until configured. The API device-registration transaction inserts these defaults only when no preference row exists; this narrow backend change is local and requires deployment. Schema defaults were checked in `clashking_schemas/database/timescale/017_final_operational_contract.sql`; no schema change was needed.

Dark is the default before and after initial preference hydration, while saved Light/System selections remain respected. Settings now uses the existing native destination stack, so Notifications gesture-back and button-back return to Settings before Home, including notification deep links.

Validation: 239 app test suites / 1,358 tests passed, typecheck and localization checks passed, touched-file ESLint and diff whitespace checks passed, and the production web export generated 28 routes. Full lint had no errors and six unrelated existing warnings. The API notification suite passed 17 tests. Navigation is verified through the bundled navigator in code-level integration tests, not a physical gesture test.

## Screenshot follow-up: latest revision

This section supersedes the earlier presentation choices below.

| Before | After | Why |
| --- | --- | --- |
| Header picker overlapped the first controls/content. | The picker participates in the header's natural height. | Its space is reserved rather than painted over the next section. |
| Branding and an inner chart fill appeared on-screen. | Transparent live chart; separate branded image mounted only for copying. | Keep the page flat while retaining attribution on exported images. |
| Selecting a chart date inserted text and changed legend wrapping. | Date and value slots exist before selection and keep their line counts. | Inspection changes values without moving the page. |
| All armies showed a three-cohort matrix. | Every cohort uses the same two-metric card. | The selected All/Top 1,000/Top 200 tab controls the numbers shown. |
| Long variant labels were packed into glass tabs. | An existing Army selection picker inside the expanded family changes its composition and graphs. | Longer setup descriptions stay readable without resembling another family. |
| Representative siege and measured siege usage were separate sections. | Measured usage replaces the representative siege section; values that round to 0.0% are hidden. | Show one useful siege breakdown. |
| Troop cards repeated three cohorts and expensive per-click data scans. | Selected-cohort cards, concise background-rate difference, memoized category/day indexes, plain comparison controls. | Reduce text and repeated calculations. Device latency has not been profiled. |
| Army cohort switches replaced the whole section with skeletons. | Exact-date/cohort/sort response caching; controls remain available during first loads, with a small progress indicator and no incorrectly labeled old rows. | Returning to a cached cohort is immediate; out-of-order requests cannot replace the current selection. |
| CWL distribution segments were shades of blue. | Shared level-specific Town Hall colors. | Make the roster mix distinguishable; this is a UI palette, not official metadata. |
| Clan page repeated a population caption and total above distributions. | Caption/total removed, charts have no additional inner grey surface. | Keep attention on the distributions. |

The Furnace split was a classifier issue, not just naming. Three Furnaces crossed the combat-only core threshold despite accounting for about 17% of full army housing. Below 25% of full housing, Furnace is now auxiliary and cannot create a separate core; genuinely Furnace-heavy armies remain eligible. The six-day local replay merges the reported family into 28,843 attacks, with 470,192 total attacks unchanged and 18 visible groups. This threshold is an implementation choice, not a claim that every future edge case is resolved.

Initial Stats loads now use a single progress indicator instead of stacks of skeleton cards. No API response or database schema changes were needed for this follow-up.

Latest follow-up validation: 225 Expo test suites / 1,251 tests passed, semantic TypeScript checks and touched-file ESLint passed, and `go test ./internal/armyfamily` passed. Regression tests cover fixed chart inspection slots, export-only branding, one siege section with rounded-zero entries hidden, and cohort cache/loading behavior. Managed Metro accepted the reload and logged an iOS bundle completion (117 ms). That confirms bundling, not visual correctness or measured device latency. The runtime notes further below describe the earlier revision.

## Before / after / why

| Before | After | Why |
| --- | --- | --- |
| Full-screen native back gesture could interrupt chart gestures on iOS 26. | Explicit `fullScreenGestureEnabled: false` on the native stack; detail retains `gestureEnabled: true`. | Keep UIKit's edge-back interaction without claiming the whole chart as a navigation gesture. |
| Only chart start/end dates, an always-selected final point, inconsistent export controls. | Intermediate date ticks, selection/date/dots on interaction, one shared branded clipboard export. | Make time legible and keep inspection optional. |
| Army variants looked like adjacent army cards. | One family surface contains setup tabs, one changing composition, measured siege breakdown and charts. | Make the family/variant hierarchy unambiguous. |
| Repeated usage/rate text, three stacked selector levels, Healer in names. | Page selection in header; league/sort together; cohort tabs; comparison matrix with shared row labels; support icons without Healer in names. | Reduce repeated UI while preserving cohort comparisons. |
| Many separate player/clan category cards. | One compact distribution chart per dimension, all ordered Town Halls/leagues and expandable location tail. | See the distribution as a whole. |
| Large CWL cards all open. | Centered season totals and collapsible league/size summaries. | Compare buckets before inspecting roster details. |

## Reused components and interaction

The ClashKing, Apple and Emil design skills informed reuse of `SelectionPicker`, `ProfileTabs`, `Surface`, existing game imagery, and accessible disclosure controls. `ProfileTabs` now offers an opt-in scroll overflow mode; its existing menu default is unchanged for other screens.

`LeagueStatsPicker` uses the authoritative Legend League 1 badge and the translated `League` picker title. War and Ranked hide the redundant Star rates heading and include zero, one, two and three stars. Every rendered analytics graph uses `AnalyticsLineChart` or `StatsChartFrame`, including war sizes and player/clan distributions. Copy captures the chart and ClashKing logo/name, excludes the button itself, and reports failure rather than claiming success.

Chart touch handling distinguishes a tap or horizontal scrub from vertical page scrolling. Missing daily observations remain gaps, not zeros. Screen-reader users can step through dates. No refresh/freshness footer is rendered.

Troop Stats loads every category item without Load more. Each item expands in place. Comparison is opt-in and limited to five selected items. Expanded trends compare Overall, Top 1,000 and Top 200; per-cohort summaries include the background hit rate and signed percentage-point difference. An unavailable optional cohort should not erase successful overall results.

## Data decisions made during implementation

- Healer stays available as an identifying support icon but is excluded from generated army names. Combat-core selection is independent of support troops, so a healer-heavy army cannot become a Healer-only family.
- The suggested variant cutoff is interpreted as **1% of all observed daily Legend League 1 attacks**, not 1% within each family. There is no fixed variant-count cap. This is a tunable local choice, not proof that every surviving combination is strategically meaningful.
- The six-day replay contains zero persisted Overall variants combining Warden equipment with Invisibility Spell. This verifies the reported example for the local window, not every possible future combination.
- Rank/movement refer to the latest completed day and the immediately preceding calendar day in the requested range and selected cohort/sort. A missing observation gives null movement rather than a fabricated rise/fall. The list itself still sorts by the requested range's usage or hit rate.
- Siege percentages are measured from normalized Clan Castle siege observations and divided by that family/variant's attacks. Only the top three are displayed; they need not add to 100%.
- Unknown clan locations are excluded from the location chart. Its percentages therefore describe **known-location clans**, not all tracked clans. No global total label is placed on that chart.
- The legacy player league ID is folded into Unranked; the CWL Unranked ID uses the legacy Unranked badge.

## Related backend detail

The updated schema, endpoint examples, classifier replay findings and local HTTP checks are recorded in `clashking_tracking/docs/local-analytics-implementation.md`. The API now exposes measured siege usage and daily rank fields on army results plus a dedicated rank-history endpoint. The local generated API packages and app dependency/license inventory were refreshed together.

## Validation and local runtime

- Full Expo Jest run: 224 suites, 1,247 tests passed.
- Expo semantic typecheck and touched-file ESLint passed; `git diff --check` passed.
- Shared export tests cover clipboard success, clipboard failure and image-capture failure. Chart tests cover unselected initial state, date stepping, tapping and missing-day gaps.
- The local API returned HTTP 200 with the new army fields and rank-history endpoint after its managed restart. Six observed days were replayed locally; this does not imply 90 days of source history exist.
- Metro is running from `feat/0.4.2` on port 7357. A reload was requested, but Metro reported **no connected app**, so a phone refresh was not confirmed. Open the development app to load these changes.
- No production deployment or visual/device testing was performed.

## Follow-up: account selection, chart controls, and bounded rendering

This pass supersedes the fixed-range and reserved date-slot behavior above. Cohorts remain All, Top 1,000, and Top 200.

| Before | After | Why |
| --- | --- | --- |
| Home defaulted to combined accounts | One persisted valid account per card | Keep the front page actionable for the selected account |
| Troop combinations eagerly mounted every card | Windowed FlatList with memoized rows and indexed metadata | Bound initial rendering work even for hundreds of combinations |
| Chart selection occupied space above the graph | Absolute tooltip beside the selected point; latest values in multi-series legends | Scrubbing cannot shift the page layout |
| Copy control reserved blank vertical space | Overlay copy control with a temporary success state | Keep screen and exported charts compact |
| Daily charts only, fixed 90-day views | Shared date settings and weighted daily/weekly/monthly charts | Explore different intervals without averaging percentages incorrectly |
| Army ordinal came from a different snapshot | Current visible rank plus separate daily movement | Rank labels match the displayed ordering |

The date range remains limited to 90 days by the existing API contract; all-time is not advertised. Percentage aggregation uses actual denominators and preserves missing intervals. Army cohort comparison reuses response data rather than issuing extra requests. Player population callouts are removed, clan league sections precede nonzero member bins, and CWL season selection follows the totals. Main Clan/War lists no longer derive clans from bookmarked players. No visual or physical-device performance tests were performed.

Validation for this follow-up: 226 Jest suites / 1,259 tests passed, semantic typecheck and localization consistency passed, touched-file ESLint and `git diff --check` passed. The large-list regression verifies bounded mounting, not measured physical-device frame times.

## Screenshot-driven correction: shared header and exports

This correction supersedes the previous fixed header and 90-day-only War behavior. The header regression came from placing a `fillWidth` picker (whose wrapper has `flex: 1`) in a vertical, fixed-height hero. The section picker now lives in its own horizontal, normal-flow row below the shorter backdrop. No section content shares or overlaps that image container.

| Before | After | Why |
| --- | --- | --- |
| Tall fixed hero with vertically growing picker | Content-sized hero, separate horizontal picker row | Prevent overlap and excessive empty height across every Stats section |
| Mixed-size secondary War metrics | Equal-width centered cells with one value style | Make counts and averages scan consistently |
| Broken graph segments and sharp miter joins | Connected observed points, bounded coordinates, rounded joins | Bridge gaps without fabricating tooltip values or drawing spikes below zero |
| Chart-only tight copies | Padded, rounded exports; full expanded Town Hall and overview exports | Include useful context without copy buttons or permanent on-screen branding |
| Large Army art and separate metric row | 22% smaller art, centered rank, right-side metrics | Keep a compact recognizable army identity |
| Glass category slider and optional cohort display | Category picker, default cohort usage, adjacent clear-comparison action | Reduce controls and repeated labels while preserving list virtualization |
| Combined main Clan/War lists | Players-style Linked/Bookmarked tabs with shared persisted clan order | Keep direct clan bookmarks separate and consistently ordered |

War presets now include 7/30/90 days, one year, and all time; no calendar picker. War dates are independent of Ranked/Troops/Armies, which remain capped at 90 days. Three archive-backed API endpoints accept the game-lifetime range under a bounded 20,000-day guard; this is retained data, not guaranteed complete history. The local summary returned 447 observed days for the all-time query. Supporting hit-rate and war-summary endpoints returned HTTP 200 as well. Production was not deployed. The existing local API was restarted to load the change.

Validation: full app suite passed 227 suites / 1,271 tests before the final export regression addition; the added export and chart tests passed separately. App typecheck, localization consistency, touched-file lint, and Expo web export passed. The API's focused 29 tests, typecheck, and lint passed. Structural tests cover header flow, presets, cohort defaults, comparison clearing, bounded large-list mounting, and shared bookmark ordering. Supplied screenshots were used as references; no visual/device tests were run.

## References

- Native stack options: https://reactnavigation.org/docs/native-stack-navigator/
- Apple chart guidance: https://developer.apple.com/design/human-interface-guidelines/charts
- Apple segmented controls: https://developer.apple.com/design/human-interface-guidelines/segmented-controls

The installed `react-native-screens/ios/RNSScreenStack.mm` was also inspected: on iOS 26, the native content-pop recognizer is gated by the effective full-screen-swipe option. No dependency source was edited.

## Navigation and compact profile follow-up

This pass supersedes the section picker and generic Stats hero above. Stats and Rankings have destination grids; each detail page has a compact, content-sized Player Info-style image header. The Player Info chip was extracted into `ProfileStatChip` and reused directly, rather than approximating its appearance. Rankings keeps its existing shared location picker inside the header, with starred locations and five recent nonstarred locations persisted locally.

| Before | After | Why |
| --- | --- | --- |
| Tall grid tiles with colored circles behind art | Compact horizontal tiles, unframed artwork, wrapping labels and a faint category-colored panel gradient | Fit the normal-phone navigation grid without making the imagery generic or clipping larger text |
| Repeated trophy/war artwork | Current maximum Town Hall artwork and distinct war-streak star artwork | Make destination identity recognizable at a glance |
| Flat detail headers or a generic Stats hero and section picker | Compact Player Info backdrop, page identity and exact shared chips where useful | Keep the app's established header language without overlapping controls or unused image height |
| One set of chart filters affected multiple pages | Separate per-page dates and intervals; Armies/Troops daily only; year-plus War weekly/monthly only | Match available data and preserve the user's choices while moving between pages |
| Mixed overview alignment with an obvious Summary heading | Equal-width metrics with consistent typography, no redundant heading and a footer copy action | Give the numbers room without reserving an empty heading row |
| Expanded Town Hall copy overlapped disclosure | Copy sits below the expanded chart; disclosure stays in the header | Keep collapse discoverable and preserve whole-card export |
| Chart details persisted until another selection | Outside touches and accessibility escape dismiss details; another chart replaces the previous selection | Keep exploration reversible without an overlay intercepting scrolling or controls |
| Swipeable home account content | Account chips explicitly switch the rendered panel | Avoid partially visible neighboring account content |
| Troop category dropdown, cohort toolbar and tall cards | Scrollable underline category tabs, tappable cohort boxes, compact art-side metrics and Compare beside the league picker | Keep categories and cohort comparison directly accessible while preserving bounded list rendering |
| Rankings refresh button beside navigation | Pull-to-refresh on populated, empty and error lists | Match refresh behavior elsewhere in the app |
| Subpages only changed local content inside the outer utility route | Native destination stack retains Grid beneath Detail | An iOS back swipe or Android back returns to the grid and preserves the provider, filters and location preferences |
| Seven undifferentiated Stats tiles left a stranded Clans tile | Battle, Battlelogs and Global Stats groups with a filled final row | Give the landing page useful hierarchy while preserving the compact card treatment |
| Padded SVG backgrounds ended before the tile edge | Absolute-fill unpadded gradient layer | Avoid hard bottom/right seams without changing the liked card styling |
| Rotated Town Hall disclosure disappeared in the open state | Explicit up/down icons inside a fixed nonshrinking slot | Keep the collapse affordance visible independently of the footer copy action |
| Current/History menu and custom gray ranking filters | Shared Legends date navigator with clickable Current/date calendar and standard SelectionPicker controls | Reuse established interactions and eliminate redundant control rows |
| Historical rows required explicit icon URLs | Snapshot league names/IDs resolve through canonical game imagery; Builder Base metadata arrival updates visible rows | Display the historical league without substituting a player's current profile or constructing invalid object-based URLs |
| Troop list was keyed by cohort and category | One retained FlatList/header/tab bar across data and empty states | Preserve native vertical and horizontal scroll positions without re-fetching already-loaded cohorts |
| Pet combinations hid the fourth pet behind a count | All four pets remain visible with adaptive overlapping artwork | Preserve the identity of the combination without enlarging normal-phone cards |
| Home account chips could scroll independently | Stationary, wrapping tap targets and a five-account Home inclusion preference in existing player Options | Keep the selected accounts visible without restricting the linked account list |
| Player Options disclosure used a rotated down icon | Fixed-size slot with explicit up/down icons | Keep the collapse affordance visible in the expanded account settings |
| Clan Capital used the daily ranking calendar and arrow interval | Monday-only calendar selections and Monday-to-Monday arrows, with Current retained as the live view | Avoid requesting unsupported weekday snapshots while preserving daily navigation on other boards |
| Sidebar repeated Home destinations and bounced when content fit | Ranked League and To-do are removed from sidebar only; overscroll is disabled while real overflow stays scrollable | Keep navigation concise and stable without removing existing Home entry points |
| Calculators could be entered in production | Visible disabled menu item with production feature gating, including deep links | Preserve discoverability without exposing the unfinished feature |
| Home rail redesign moved the name below the pill or made every chip fixed-width | Original 28px content-width pill, selected name inside, compact inactive chips and original under-title placement | Restore the requested appearance while retaining a non-scrollable wrapping row and five-account limit |

The supplied screenshots informed this correction, along with the ClashKing, Apple and Emil design skills. No screenshots, browser automation, simulator runs or manual app visual tests were performed. Code-level layout, navigation, export and interaction checks do not establish physical-device visual or performance verification. No production deployment was performed.

Latest follow-up validation: **237 suites / 1,350 tests passed** after restoring the original expanding Home account pill and under-title placement. TypeScript, localization consistency, scoped ESLint, diff checks and the 28-route web export passed. Sidebar regression tests cover visible-but-disabled calculators and no bounce; feature-flag tests cover production, absent environment, failed refresh, and local/development behavior. Stats group headings are localized as Battlelogs and Global Stats.

Final validation for this pass: **237 Jest suites / 1,344 tests passed**, semantic TypeScript checking and localization consistency passed, touched-file ESLint and `git diff --check` passed, and Expo web export completed for 28 routes. Regression coverage includes retained native destination navigation, stable Troop header/list/tab instances across populated and empty categories, all four pet images at narrow and large-text sizes, delayed Builder Base metadata, Monday-only Capital history, fixed disclosure slots, and the five-account Home preference boundary. Home inclusion uses existing linked-player Options and does not limit or remove linked accounts; transient empty rosters cannot erase saved selection.
