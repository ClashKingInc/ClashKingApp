# Flutter to Expo parity ledger

The Flutter application is frozen as the behavioral and visual reference until
the Expo replacement ships. Every tracked Flutter, native, web, localization,
asset, and verification file must have a disposition in
`parity-manifest.json` before the Flutter implementation can be removed.

## Dispositions

- `port`: reproduce the behavior in Expo or retained native code.
- `consolidate`: preserve the behavior in a named shared Expo implementation.
- `backend`: replace the client behavior with an approved API/schema change.
- `remove`: omit only after reachability, runtime, and product review prove it
  is dead.
- `reference`: keep as design, test, fixture, or release evidence.

## Statuses

- `pending`: not implemented.
- `in_progress`: implementation exists but one or more parity gates remain.
- `blocked`: a named contract or product decision prevents completion.
- `verified`: implementation and every applicable non-visual gate passed.

An entry can become `verified` only when its target is named and the applicable
contract, component, navigation, localization, native-build, upgrade, and web
tests are recorded in `evidence`. Visual acceptance remains a manual user gate
and is deliberately not automated for this migration.

## Workflow

Run `npm run parity:generate` after Flutter source changes or after editing
`parity-overrides.json`. CI runs `npm run parity:check` to reject an outdated
ledger. Overrides contain reviewed dispositions and evidence; the generator
owns the exhaustive source inventory.

Known contract decisions are tracked explicitly:

- Raid reminder preferences remain blocked on coordinated schema and API work.
- Expo startup requires at least one verified account on every entry path.
- The stale `/tracking/verified-players` call is not ported.
- Logout unregisters the push device before clearing local session state.
- Stale Live Activity strings are removed; no Live Activity is invented.
