# Legends performance and army analytics

Scope: local experimental build, populated manually. New metadata is not activated in scheduled Tracking or deployed to production; promotion is a later decision after evaluating results.

## Current local implementation

`GET /v2/player/:playerTag/legend/season` resolves the current four-week season from the latest retained official `v2-<end timestamp>` season ID. It returns seasonStart, seasonEnd, recorded attack army codes and observed attack/defense counts, triples and trophy averages. It does not depend on a player's personal finishing history. Legacy YYYY-MM and date season IDs remain supported for finishes, but do not anchor the current calendar.

`GET /v2/player/:playerTag/legend/comparisons` has no query parameters. It deliberately omits playerTag, asOf and window:

```json
{
  "items": [
    { "cohort": "top_200", "days": 2, "attacks": 1400, "triples": 1120,
      "playerAttacks": 16, "playerTriples": 12 }
  ],
  "army": {
    "familyId": "548",
    "name": null,
    "shareCode": "h0p10e14_51-1p9e17_48-2p16e22_24-7p4e52_53...",
    "items": [
      { "cohort": "legend_i", "days": 6, "attacks": 423, "triples": 197,
        "playerAttacks": 24, "playerTriples": 11 }
    ]
  }
}
```

The response shape above is illustrative. The global cohort values are `legend_i` (all collected Legend attacks), `top_1000` and `top_200`; the top-100 stored cohort remains available for compatibility elsewhere but is not part of this comparison UI. Each comparison pools real attacks across the same finalized, available days for cohort and player. Coverage starts at the resolved current-season start and ends before the current open Legend day at the 05:10 UTC boundary. Missing aggregate days are omitted, not counted as zeros. Triple rate is triples / attacks; automatic defenses never contribute. Show sample counts and covered days, and no rate for a zero denominator. Small samples are descriptive, not reliable evidence of performance differences.

`army` is optional. When present, it selects the player's most-used existing narrow family by recorded current-season attack count, using stable `army_family_members` identities and family ID as the tie-breaker. Its `items` compare only that player's attacks assigned to the selected family with the same family's daily cohort totals over shared finalized days. If the player's armies are unknown, no stable family matches, or the family has no finalized cohort coverage, the field or unavailable cohort item is omitted. This is exact existing-family matching, not the broader troop-overlap classifier described below.

Season charts use stored trophy/rank snapshots, never a reconstruction backwards from today's value. Missing snapshots remain missing. The player's favorite troop uses housing-weighted quantities across recorded season attacks; spells use quantities; siege placement is normalized into Clan Castle.

## Global endpoint extensions

Retain `/v2/stats/armies`, `/detail`, `/timeline` and `/v2/stats/legend/days`. Extend daily metadata instead of creating competing endpoints. The comparison UI exposes all / top 1,000 / top 200. The manually built top-100 daily cohort remains additive compatibility data and is not removed from the API's general Legend-day cohort type.

Global item popularity counts presence once per attack, with uses, triples and total observed attacks as the denominator. This intentionally differs from a player's housing-weighted favorite troop. Hero-pet assignments, sorted hero-equipment pairs and sorted pet combinations describe setups, not separate family identities. The manual local builder rebuilds aggregates atomically per closed day using stored attacks and that day's rank cohort, never today's rank. The scheduled path keeps its existing behavior.

Family lists remain in `/v2/stats/armies`; individual family trends remain in `/v2/stats/armies/timeline`. Do not embed all families in every daily item row: the measured six-day response was 2.47 MB with those duplicates, versus 137 KB for item metadata alone.

## Broad family classifier: staged replacement, not silently activated

The preferred research model is frozen Troop overlap / core from Army Lab export 20260920T160707Z-9bb2eb-recent-6900e4, using core-parents.npz from 20260920T160707Z-9bb2eb-5b958f. It has 33 known broad families plus review/unclassified results. Parents use housing-weighted troop proportions, not spells, pets, equipment or outcomes. Existing production matching is narrower and must not be presented as this model.

```text
Observed battle -> normalized army -> frozen troop-overlap parent
                                  -> troop/spell variants
                                  -> independent setup combinations
                -> daily cohort totals -> API -> Stats and comparisons
```

The next local experiment should export a self-describing snapshot from the materialized `core.json`, catalog and normalized exact-code membership. The `.npz` labels and centers alone omit the feature ordering and normalization needed for safe inference. Use opaque run-scoped IDs such as `exp:core:p1`, never decimal production family IDs. Keep the snapshot separate from the existing family tables and scheduled closeout.

Proposed local-only routes (not implemented):

- `GET /v2/experimental/stats/army-taxonomy` returns the loaded run and its family summaries.
- `GET /v2/experimental/stats/army-taxonomy/:experimentalFamilyId` returns one parent and exclusive troop/spell variants.
- `GET /v2/experimental/stats/army-taxonomy/resolve?armyLink=...` resolves exact normalized membership; unseen recipes return unclassified.

These routes must fail closed unless the local experiment is explicitly enabled. Do not merge their frozen coverage with the existing live date filters. A minimal export has this shape:

```json
{
  "run": {
    "schemaVersion": 1,
    "runId": "army-lab:core:20260920T160707Z-9bb2eb-recent-6900e4",
    "model": "troop_overlap_80",
    "provisional": true,
    "sourceDays": ["2026-09-15", "2026-09-20"],
    "trainingDays": ["2026-09-15", "2026-09-17"],
    "heldOutRecipesExcluded": true
  },
  "families": [],
  "memberships": []
}
```

Family records carry an experimental ID, name, core troop IDs, representative code, attacks, code count and daily totals. `troopVariants` and `spellVariants` carry their own run-scoped IDs, counts, shares and recipes. Membership records carry normalized code, parent ID and optional variant IDs. Setup patterns are overlapping associations, not exclusive subtypes. Include catalog version, checksum, thresholds and generation time in the actual artifact; do not invent them from file timestamps. The researched materialized run contains 444,962 attacks, 120,926 normalized codes and 33 non-review parents.

Before any later production activation, compare old/new assignments on this snapshot, inspect disagreements and unclassified coverage, then agree on a versioned migration of reviewed identities. Never renumber permanent IDs or retrain on each day's incoming data. Keep classification frozen when evaluating hit rate to avoid outcome-driven assignment.

See the forward schema migration and Tracking closeout implementation for typed daily table layouts. No arbitrary metrics JSONB storage is introduced.

## Local verification boundary

Production stays read-only. The scoped player import copies current-season battles, historical ranks, finish history and opponent names after backing up local rows. The separate local current-ranking snapshot replacement was explicitly approved and backed up. Neither operation is a deployment or proof of complete local coverage.

Code checks do not constitute visual/device approval. Browser, screenshots, simulator and manual visual tests remain excluded unless explicitly requested.

### Verified local snapshot, September 21, 2026

Goose migrations 030 and 031 are applied only to `clashking_dev`. The manual rebuild produced 24 cohort/day rows for September 15–20 (all, top 1,000, top 200 and compatibility top 100), with 470,192 observed all-cohort attacks. All rows contain troop, spell, siege, equipment-pair and pet-combination metadata. Existing narrow-family matching covers over 99.9% of these attacks; that is lookup coverage, not validation of the proposed broad taxonomy. For `#GLQU82YQU`, the local comparison resolves dominant narrow family `548`: 24 player attacks and 11 triples share six finalized days with 423 all-cohort family attacks and 197 triples. This local observation does not promote that narrow family to a broad taxonomy identity.

Aggregate backups are at `/private/tmp/clashking-legend-closeout-backup-20260921`. The approved current-rank replacement backup is `/private/tmp/clashking-legend-refresh-BZvn52`; the full September 20 battle/rank import backup is `/private/tmp/clashking-legend-refresh-91YynI`. These local temporary backups should be preserved before any later cleanup.

The manual command is `go run ./cmd/rebuild-legend-days --days 2026-09-15,2026-09-16,2026-09-17,2026-09-18,2026-09-19,2026-09-20` in Tracking with the configured local Timescale environment. It refuses non-loopback hosts, any port other than 54330, any database other than `clashking_dev`, connection-query overrides and incomplete days. It starts no collectors or scheduled jobs. No production schema, application or tracking changes were deployed.
