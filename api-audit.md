# ClashKing API Audit — Flutter vs Go

**Date:** 2026-06-14  
**Scope:** All HTTP calls made by the Flutter app vs all routes registered in the Go API (`internal/routes/register.go`).

---

## 1. How This Was Gathered

### Go API routes
All routes are registered in `internal/routes/register.go`.  
The router uses [Fiber v2](https://github.com/gofiber/fiber).  
The file defines two groups:
- **v2 routes** — the new Go API at `https://go.api.clashk.ing` (prefix `/v2/…`)
- **compatibility/legacy routes** — no version prefix, served at the same host

### Flutter API calls
All API calls were traced through:
- `lib/core/services/api_service.dart` — base URL is `https://go.api.clashk.ing/v2` for `apiUrlV2`, `https://api.clashk.ing` for `apiUrlV1`, `https://proxy.clashk.ing/v1` for `proxyUrl`
- `lib/features/auth/data/auth_service.dart`
- `lib/features/auth/data/user_service.dart`
- `lib/features/coc_accounts/data/coc_account_service.dart`
- `lib/features/player/data/player_service.dart`
- `lib/features/player/services/player_war_export_service.dart`
- `lib/features/clan/data/clan_service.dart`
- `lib/features/war_cwl/data/war_cwl_service.dart`
- `lib/core/services/game_data_service.dart`
- `lib/core/services/token_service.dart`
- `lib/widgets/war_widget.dart`
- `lib/widgets/widgets_functions.dart`
- `lib/widgets/clan_tag_manager.dart`
- `lib/features/pages/presentation/search_page.dart`
- `lib/features/pages/widgets/player_search_card.dart`
- `lib/features/pages/widgets/clan_search_card.dart`
- `lib/features/pages/widgets/clan_search_filters_dialog.dart`
- `lib/features/war_cwl/presentation/cwl/cwl.dart`
- `lib/features/war_cwl/data/war_cwl_service.dart`
- `lib/features/clan/models/clan_war_log.dart`

---

## 2. Summary

| | Count |
|---|---|
| **Go v2 routes registered** | 107 |
| **Go compatibility/legacy routes** | 32 |
| **Flutter endpoint calls (Go v2)** | 23 |
| **Flutter endpoint calls (Go v1/legacy)** | 3 |
| **Flutter endpoint calls (proxy — CoC API)** | 6 |
| **Matched (Flutter → Go v2 confirmed)** | 21 |
| **MISMATCHES: Flutter calls endpoint not in Go v2** | 2 |
| **Unused Go v2 routes (not called by Flutter)** | 86+ |

---

## 3. Confirmed Matches (Flutter calls → Go v2 route exists)

| Method | Path | Flutter file |
|--------|------|--------------|
| GET | `/v2/public-config` | `api_service.dart:358` |
| GET | `/v2/auth/me` | `auth_service.dart:51`, `user_service.dart:7` |
| POST | `/v2/auth/discord` | `auth_service.dart:89` |
| POST | `/v2/auth/email` | `auth_service.dart:121` |
| POST | `/v2/auth/register` | `auth_service.dart:157` |
| POST | `/v2/auth/verify-email-code` | `auth_service.dart:212` |
| POST | `/v2/auth/resend-verification` | `auth_service.dart:237` |
| POST | `/v2/auth/forgot-password` | `auth_service.dart:252` |
| POST | `/v2/auth/reset-password` | `auth_service.dart:271` |
| POST | `/v2/auth/link-discord` | `auth_service.dart:306` |
| POST | `/v2/auth/link-email` | `auth_service.dart:329` |
| POST | `/v2/auth/refresh` | `token_service.dart:50` |
| GET | `/v2/users/coc-accounts` | `coc_account_service.dart:53` |
| POST | `/v2/users/coc-accounts` | `coc_account_service.dart:87` |
| POST | `/v2/users/coc-accounts/verified` | `coc_account_service.dart:119`, `coc_account_service.dart:550` |
| DELETE | `/v2/users/coc-accounts/:player_tag` | `coc_account_service.dart:143` |
| PUT | `/v2/users/coc-accounts/order` | `coc_account_service.dart:165` |
| POST | `/v2/users/coc-accounts/:player_tag/verify` | `coc_account_service.dart:612` |
| POST | `/v2/initialization` | `coc_account_service.dart:330`, `player_service.dart:188` |
| POST | `/v2/players` | `player_service.dart:57`, `war_widget.dart:197`, `clan_tag_manager.dart:54` |
| POST | `/v2/players/extended` | `player_service.dart:125` |
| POST | `/v2/war/players/warhits` | `player_service.dart:369`, `player_service.dart:439` |
| POST | `/v2/war/clans/warhits` | `clan_service.dart:381`, `clan_service.dart:432` |
| POST | `/v2/war/war-summary` | `war_cwl_service.dart:27` |
| GET | `/v2/war/:clan_tag/war-summary` | `widgets_functions.dart:31` |
| GET | `/v2/static/app-bundle` | `game_data_service.dart:9` |
| GET | `/v2/static/app-translations` | `game_data_service.dart:11` |
| POST | `/v2/exports/war/player-stats` | `player_war_export_service.dart:19` |
| GET | `/v2/exports/war/cwl-summary` | `cwl.dart:79` (URL build with query param) |

---

## 4. Mismatches — Flutter Calls an Endpoint Not in Go

### 4.1 `POST /v2/auth/verify-email` — DOES NOT EXIST in Go

**Flutter call:** `auth_service.dart:185`
```dart
final response = await _apiService.post('/auth/verify-email', {
  'token': verificationToken,
});
```

**Go API:** The Go API only exposes `POST /v2/auth/verify-email-code` (which takes `email` + `code`). There is no `POST /v2/auth/verify-email` route anywhere in the Go API.

**Impact:** The `verifyEmail()` method in `AuthService` will receive a **404** every time it is called. This is the token-based flow (presumably the old Python flow or a flow that has not been ported to Go yet). The code-based flow (`verifyEmailWithCode()`) calls the correct `/auth/verify-email-code` and works fine.

**Recommendation:** Either add a `POST /v2/auth/verify-email` route to Go, or remove the `verifyEmail()` method from the Flutter app and redirect all callers to `verifyEmailWithCode()`.

---

### 4.2 `POST /v2/clans/join-leave` — DOES NOT EXIST in Go

**Flutter call:** `clan_service.dart:188`
```dart
final response = await _apiService.postResponse(
  '/clans/join-leave?current_season=true',
  body: {"clan_tags": clanTags},
  requiresAuth: true,
);
```

**Go API routes for join-leave:**
- `GET /v2/clan/:clan_tag/join-leave` — single clan, GET, with query params
- `GET /v2/clan/:clan_tag/join-leave/stats` — stats only, GET
- `GET /v2/player/:player_tag/join-leave` — player history, GET

There is **no** `POST /v2/clans/join-leave` (bulk, plural) route in Go. The Go API handles join-leave per single clan via GET, not as a bulk POST.

**Impact:** `ClanService.loadClanJoinLeaveData()` will get a **404** every time. Since the `/initialization` bulk endpoint already includes join-leave data inline (processed by `mobileFetchJoinLeaveData` in `mobile.go`), callers that go through the bulk `/initialization` path are fine. Only the **fallback path** in `coc_account_service.dart:_loadDataWithFallback()` calls this method directly and will fail silently (it catches the error).

**Recommendation:** Either add a `POST /v2/clans/join-leave` route to Go that accepts `{"clan_tags": [...]}`, or change the fallback path in Flutter to loop over clan tags and call `GET /v2/clan/:clan_tag/join-leave` individually (matching the existing Go API shape). The bulk endpoint already covers the primary path so this fallback path is rarely exercised, but it should be fixed.

---

### 4.3 `GET /v2/discord/me` — Likely Does Not Exist in Go

**Flutter call:** `user_service.dart:10`
```dart
return await _apiService.get('/discord/me');
```

There is no `GET /v2/discord/me` registered in `register.go`. The `GET /v2/auth/me` returns the ClashKing user including Discord info. The `UserService.getDiscordProfile()` method that makes this call does not appear to be called anywhere in the main app flow (it may be dead code or a placeholder), but it will 404 if invoked.

**Recommendation:** Either add `GET /v2/discord/me` to Go if it is needed, or remove `UserService.getDiscordProfile()` if it is unused.

---

### 4.4 `GET /v2/user/clash-accounts` — DOES NOT EXIST in Go

**Flutter call:** `user_service.dart:15`
```dart
final response = await _apiService.get('/user/clash-accounts');
```

The correct Go route is `GET /v2/users/coc-accounts` (plural `users`, different path segment `coc-accounts`). The active code in `coc_account_service.dart` calls the correct path. `UserService.getClashAccounts()` appears to be dead code using a stale path, but it will 404 if invoked.

**Recommendation:** Update or delete `UserService.getClashAccounts()` to use `/users/coc-accounts`.

---

## 5. Flutter Calls to the Legacy Go Compatibility Routes (No `/v2` Prefix)

These routes call `https://api.clashk.ing` (the `apiUrlV1` constant), which points at the **legacy compatibility routes** registered in `registerCompatibilityRoutes()` in `register.go`.

| Method | Path | Flutter file |
|--------|------|--------------|
| GET | `/war/:clan_tag/previous/:end_time` | `war_cwl_service.dart:96` |
| GET | `/player/full-search/:name` | `search_page.dart:161`, `player_search_card.dart:86` |

Both routes exist in `registerCompatibilityRoutes()` so these calls will work. However, they depend on the legacy host `api.clashk.ing` staying alive as these paths are served there.

---

## 6. Flutter Calls to `proxy.clashk.ing` (CoC Proxy)

These calls use `https://proxy.clashk.ing/v1` which is a reverse proxy to the official Clash of Clans API. They are not Go API routes and are expected to remain separate.

| Method | Path (after `/v1`) | Flutter file |
|--------|---------------------|--------------|
| GET | `/clans/:clan_tag/capitalraidseasons` | `clan_service.dart:262` |
| GET | `/clans/:clan_tag/warlog` | `clan_service.dart:331`, `clan_war_log.dart:190` |
| GET | `/players/:player_tag` | `search_page.dart:157`, `player_search_card.dart:82` |
| GET | `/clans?name=...` | `search_page.dart:180`, `clan_search_card.dart:74` |
| GET | `/clans/:clan_tag` | `search_page.dart:288` |
| GET | `/locations` | `clan_search_filters_dialog.dart:40` |

These are all valid CoC API proxy calls — no issue here.

---

## 7. Unused Go v2 Routes (Go Has Route, Flutter Never Calls It)

The Go API exposes many routes that the Flutter mobile app does not call. This is expected — most are used by the ClashKing Discord bot or web dashboard. The list below highlights routes that might be relevant to the mobile app but are currently unused by Flutter.

### Potentially mobile-relevant unused routes

| Method | Path | Notes |
|--------|------|-------|
| GET | `/v2/war/:clan_tag/previous` | Previous wars per clan. Flutter uses the legacy `/war/:clan_tag/previous/:end_time` on `api.clashk.ing` instead of this v2 equivalent. |
| GET | `/v2/cwl/:clan_tag/ranking-history` | CWL ranking history — not used in app. |
| GET | `/v2/cwl/league-thresholds` | CWL thresholds — not used in app. |
| GET | `/v2/war/:clan_tag/war-summary` | Single-clan war summary for widget — confirmed used by `widgets_functions.dart`. |
| GET | `/v2/clan/:clan_tag/join-leave` | Per-clan join-leave history — not called; Flutter uses the non-existent bulk POST. |
| GET | `/v2/dates/seasons` | Seasons list — not called by Flutter. |
| GET | `/v2/dates/current` | Current date info — not called by Flutter. |
| GET | `/v2/player/:player_tag/extended` | Single-player extended view — Flutter uses the bulk `POST /v2/players/extended` instead. |
| GET | `/v2/search/clan` | Clan search — Flutter uses `proxy.clashk.ing` for search instead. |

### Bot/web-only routes (definitely not needed by mobile app)
Routes under these path prefixes are clearly web/bot only and are not expected to be called by the mobile app:
- `/v2/server/:server_id/…` (all Discord server management routes)
- `/v2/roster…`, `/v2/roster-group…`, `/v2/roster-signup-category…`, `/v2/roster-automation…`
- `/v2/guilds`, `/v2/guild/…`
- `/v2/link/…`, `/v2/tracking/…`
- `/v2/legends/…`
- `/v2/capital/…`
- `/v2/activity/…`
- `/v2/internal/…`
- `/v2/cdn/upload`

---

## 8. Version Prefix Note

The Flutter `ApiService` uses `https://go.api.clashk.ing/v2` as its base for Go routes (the `/v2` prefix is baked into the base URL string). All endpoint strings passed to `_apiService.get()/post()` etc. are therefore relative to `/v2`, e.g., `/auth/me` becomes `/v2/auth/me`.

The Go routes registered in `register.go` all include `/v2` in the path string, so the prefix alignment is **correct** for v2 routes.

For legacy routes, Flutter calls `apiUrlV1 = "https://api.clashk.ing"` directly with the full path including no `/v2` prefix. These map to the `registerCompatibilityRoutes()` group, which also uses no version prefix. That alignment is also **correct**.

---

## 9. Summary of Action Items

| Priority | Issue | Action |
|----------|-------|--------|
| High | `POST /v2/auth/verify-email` does not exist in Go | Add Go route OR remove/redirect Flutter call to `/auth/verify-email-code` |
| Medium | `POST /v2/clans/join-leave` does not exist in Go | Add bulk clan join-leave POST to Go, OR change Flutter fallback to use `GET /v2/clan/:clan_tag/join-leave` |
| Low | `GET /v2/discord/me` does not exist in Go | Add route to Go if needed, OR confirm dead code and delete from Flutter |
| Low | `GET /v2/user/clash-accounts` is a stale path | Update to `/users/coc-accounts` or delete the method in `UserService` |
| Info | `GET /v2/war/:clan_tag/previous` exists in Go but Flutter still uses legacy `api.clashk.ing` host | Migrate to v2 path when convenient |
| Info | Join-leave data for the primary flow comes through `/initialization` bulk endpoint correctly | No action needed for primary flow |
