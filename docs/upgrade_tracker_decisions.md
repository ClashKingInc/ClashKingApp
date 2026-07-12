# Upgrade Tracker — Product and Architecture Decisions

Status: local prototype implementation. Backend and schema work is intentionally deferred.

## Product thesis

**Visual thesis:** A calm, image-led village progress surface: one strong completion number, real Clash assets, flat rows, and almost no decorative chrome.

**Content plan:** Progress combines completion, active work, remaining upgrades, and planning. Collection answers “what do I own?”.

**Interaction thesis:** Two primary jobs, a slim Upgrades/Plan switch inside Progress, progressive disclosure for details, and one global share action.

## Decisions

### **Use mobile-first tracker navigation**

The primary navigation is Progress and Collection. Progress groups the underlying taxonomy into Buildings, Heroes & Guardians, Laboratory, Equipment, Pets, and Walls; Upgrades and Plan are modes of the same job.

### **Never let users set owned levels manually**

Owned levels, counts, supercharges, crafted-defense modules, cosmetics, and active timers come from the raw account snapshot. Static data supplies names, unlock requirements, maximum levels, upgrade costs, times, and assets. Planner choices may change ordering, but never ownership or current level.

### **Make the automatic plan the only plan**

The calendar editor and strategy comparison were removed after product review. Builder, laboratory, and pet suggestions begin now and schedule every remaining step across available parallel lanes. Users rank broad categories without ties, choose whether new buildings lead inside a category, and set how strongly shared Home Village resources should be smoothed.

### **Infer Home and Builder Base capacity separately**

Home Village counts owned Builder's Huts and adds B.O.B only when B.O.B's Hut is present and unlocked. Builder Base uses one builder below Builder Hall 6 and two from Builder Hall 6 onward, matching the second-stage unlock represented by the raw snapshot. Plans show both total work and real elapsed time so parallel builders are not presented as sequential duration.

### **Treat building and unit upgrade metadata differently**

Building/trap/crafted-defense `build_cost` and `build_time` belong to the target level, so a level 16 to 17 upgrade reads level 17 metadata. Troop, spell, hero, pet, guardian, and equipment `upgrade_cost`/`upgrade_time` belong to the current level and describe the next upgrade; their maximum-level row is therefore zero. This distinction is required for correct totals.

### **Apply reductions only when they are honest**

Gold Pass reductions from the account snapshot seed the planner, and users can select the current 0%, 10%, 15%, or 20% perk because this durable account state may lag or be absent from imported JSON. A live event applies only to tasks projected to start before that event ends and only to its matching resources/categories. Builder potions, research potions, pet potions, Clock Tower, helper time, and Town Hall boosts are shown as active state but do not discount the entire future plan. For an upgrade already running, the account snapshot's remaining timer is authoritative.

### **Compute completion from the owned snapshot until static data includes building quotas**

Static data provides maximum level by Town Hall but does not currently provide the allowed count of every structure at each Town Hall. Structure completion therefore uses every owned instance in the snapshot. This is accurate for a complete snapshot, including the supplied test account, but the static-data pipeline should eventually add per-hall structure quotas so a missing newly unlocked building also counts as incomplete.

### **Keep planner state client-side while the product is being shaped**

The raw snapshot, selected planning strategy, Gold Pass choice, and UI preferences live in local app storage. No database tables or API routes are added in this pass. Local data is keyed by normalized player tag and carries the source snapshot timestamp.

### **Await static-data freshness before calculating**

Normal app startup loads cached data and then awaits the remote freshness check. Tracker calculation only consumes the already-loaded static snapshot and never performs its own refresh.

### **Notifications require server-owned upgrade instances**

Reliable finish notifications need durable server state: player tag, target static-data ID, village, target level/supercharge/module, source snapshot timestamp, authoritative finish time, and notification preferences. The API should own CRUD and auth; the schema belongs in `clashking_schemas`; the tracking service should refresh snapshots and enqueue notifications. Client-only timers are useful for the prototype but cannot guarantee delivery.

### **Share a generated image, not a public village URL**

The first version renders a compact square graphic locally and opens the native share sheet. It supports Home Village and Builder Base and contains the player, correct hall, overall completion, calendar days, resource totals, main category percentages, and remaining levels. No account snapshot or private planner queue is uploaded.

### **Collections use the asset repository as the display contract**

Skins use `skins/<slug>/icon.webp`; sceneries use their static `thumbnail` path; decorations and obstacles use their village folders; Capital House parts use `capital_house_parts/<id>.webp`. Missing assets fall back through the app's existing image component instead of inventing substitute artwork.

Skins, sceneries, decorations, and obstacles expose Home Village/Builder Base scope when both villages exist; Capital House parts intentionally do not. Skin village is inferred from its static character (`BB` heroes are Builder Base), scenery village comes from `type`, and decorations and obstacles use `village`. Every collection tile opens an undistorted larger preview whether collected or missing.

### **Use game art for tracker taxonomy, not generic UI symbols**

Category, planner, and collection selectors use representative images resolved from the same parsed snapshot and asset URLs as their content. Artwork uses aspect-fit wrappers and a single decode target so wide, tall, and irregular source art keeps its intrinsic ratio. System actions may still use platform symbols.

### **Use a neutral ClashKing palette with restrained red accents**

Tracker navigation, village controls, progress, account actions, and import actions use white/graphite neutrals. Red is limited to small selected borders and non-text accents. Game assets provide most of the color.

### **Allow local raw-JSON import during product shaping**

The account switcher includes **Paste account JSON**. A scoped sheet accepts raw JSON or fills it from the system clipboard, validates that it has a player tag and recognizable hall data, parses it against current static data, and stores it in device preferences. Imported JSON never leaves the device in this prototype. This is deliberately a testing and iteration path; production snapshots should arrive from an authenticated API sync.

### **Do not repeat the page name in a large header**

The navigation entry and two tracker jobs already establish context. The compact top bar contains account, share, and import controls.

### **Show totals next to the thing they summarize**

Every upgrade category exposes its remaining upgrade-level count and resource totals directly above its rows. Every generated queue shows elapsed time, total work, and loot before its lane details. Totals stay horizontally scrollable to protect small-screen layout and keep controls close to the content they affect.

### **Use one configurable native upgrade widget**

The existing iOS widget extension and App Group are reused. Flutter writes only linked accounts that also have raw snapshots. System Large separates Home Village, Laboratory, Pets, and Builder Base; System Medium uses a purpose-built, less granular village/research summary. Both show structured boosts, helper status, level transitions beside compact durations, and aspect-fit artwork.

### **Follow iPhone interaction conventions during refinement**

Primary jobs stay limited to Plan, Upgrades, and Collection; secondary choices use familiar segmented controls or the app's established dropdown, game taxonomy uses undistorted asset art, and complex selection/import tasks open in focused sheets. Interactive category selectors use generous touch areas, labels remain single-line where wrapping damages a visual grid, and controls are progressively disclosed instead of shown all at once.

## Deferred API and schema shape

Suggested API resources:

- `GET /v2/mobile/players/{tag}/upgrade-snapshot`
- `PUT /v2/mobile/players/{tag}/upgrade-plan`
- `GET /v2/mobile/upgrade-modifiers`
- `PUT /v2/mobile/players/{tag}/upgrade-notifications`

Suggested SQL entities:

- `player_upgrade_snapshots`: normalized tag, account JSON, source timestamp, static-data revision, checksum.
- `player_upgrade_plan_items`: user, tag, queue, item ID, target level, order, optional locked start time.
- `player_upgrade_notifications`: user, tag, item identity, finish time, platform targets, sent/cancelled timestamps.
- `upgrade_modifiers`: event ID, start/end, affected categories/resources, cost/time percentages, source revision.

The raw account snapshot should be encrypted at rest or reduced to the minimum parsed fields before persistence. Snapshot and plan writes must reuse the app's current-user/auth source of truth.

## Asset audit

The current account/collection/resource URL audit is recorded in `docs/upgrade_tracker_asset_audit.md`. Five source files are absent from the local asset repository; the app uses its normal fallback for those exact paths. Builder Base Battle Machine and Battle Copter were corrected to use hero artwork instead of nonexistent building artwork.
