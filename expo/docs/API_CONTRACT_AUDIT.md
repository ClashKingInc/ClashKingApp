# Expo API contract audit

Audited against the deployed `https://api.clashk.ing/openapi.json` contract and safe read-only production requests on 2026-08-30. The pinned contract used for this pass has SHA-256 `5b70b0bd89da58697e8423ac8e02a52180ded59ad0d120c0f0a30984985133b4` and contains 235 paths. The deployed API is authoritative; the local API checkout is useful implementation context but does not override production when the two differ.

## Transports

- `ApiClient` uses `https://api.clashk.ing/v2` for ClashKing routes and `https://api.clashk.ing/proxy/v1` for official Clash API-compatible routes. The proxy requires the ClashKing bearer token.
- Previous-war lookup uses deployed `GET /v2/war/{clan_tag}/previous/{endtime}` with a Clash-formatted end time. The query-form v2 route present in an earlier draft is not deployed.
- Current-war resolution starts with `GET /v2/war/{clan_tag}/basic`, then loads the full regular war or CWL group/round through the authenticated official proxy. The app and native widget share this resolver.
- Direct non-API network reads are limited to ClashKing static assets, translations, fonts, announcement story content, scenery audio checks, Discord OAuth, and exported files. The CWL export remains `/v2/exports/war/cwl-summary`.

## Removed or rewritten calls

| Removed or stale caller                                       | Deployed replacement                                                                                                 |
| ------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `GET /v2/achievements`                                        | Authenticated `POST /v2/achievements/check`, the deployed route returning the achievement catalog                    |
| `GET /v2/war/{tag}/war-summary`                               | Shared `/v2/war/{tag}/basic` plus official-proxy regular-war/CWL resolution, adapted to the existing widget payload  |
| Query-form `GET /v2/war/{tag}/previous?...`                   | `GET /v2/war/{tag}/previous/{endtime}`                                                                               |
| `POST /v2/war/players/warhits`                                | Public `GET /v2/player/{tag}/war/stats`, aggregated and filtered on-device into the existing player-statistics model |
| `POST /v2/war/clans/warhits`                                  | Public typed `GET /v2/clan/{tag}/wars`, aggregated and filtered on-device                                            |
| `/v2/clan/{tag}/war-log`                                      | Deployed `GET /v2/clan/{tag}/warlog`                                                                                 |
| Scanning `/v2/app/posts` for one announcement                 | Public `GET /v2/app/announcements/{id}` with locale, accepting the deployed direct or wrapped response shape         |
| `/v2/ranking/player-*` and `/v2/ranking/clan-*` history paths | Public `GET /v2/leaderboard/history/{leaderboard_type}/{location_id}/{date}`                                         |
| `/v2/tracking/verified-players`                               | Removed with no replacement; account and notification state use their current dedicated routes                       |
| Flutter device-unregister JSON body                           | Authenticated `DELETE /v2/notifications/devices?device_id=...`, matching the deployed query contract                 |

## Verified live reads

Production returned contract-shaped responses for player and clan search, player timers and typed war history, clan profile/leaderboard/legend history, historical leaderboard snapshots, typed previous-war lookup, typed clan wars, and player war stats. A live player-history sample confirmed that `attacks` and `defenses` carry the opposing player snapshot expected by the on-device adapter. Live clan-war requests also confirmed that the `type` query filters random, CWL, and friendly histories.

`GET /v2/app/config` and `GET /v2/app/posts` are live even though they are omitted from the current OpenAPI document. `GET /v2/auth/export` is also deployed and returned `401` without a token, confirming the authenticated route without exporting any account data.

The official proxy, links/bookmarks/upgrades, achievements, notification preferences/devices, subscription status, clan war logs, and authenticated auth/account operations require a real session. Their deployed paths and methods match the current client, but no authenticated or state-changing production request was sent during this audit.

## Remaining backend dependency

The live notification-preferences transport schema exposes Flutter's raid-reminder fields, but the deployed persistence layer and current database schema do not retain them. Expo keeps the matching local controls and explicitly records this as the sole deferred parity dependency; durable cross-device persistence requires coordinated API and `clashking_schemas` work and was intentionally not invented in the client.

The deployed player-war history currently returns an empty `type` for some random wars even though OpenAPI declares `cwl`, `random`, or `friendly`. The compatibility adapter treats an empty type as `random`. Clan-war responses omit `type`; Expo requests each type explicitly and attaches the requested type before aggregation.
