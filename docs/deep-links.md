# App deep links

Implemented in the local 0.4.2 checkout. No public login/registration routes were added; existing internal Discord callbacks, verification, and password recovery keep their own handlers.

Use `https://app.clashk.ing/PATH` for shareable web links or `clashking://PATH` for an installed native app. For example, `clashking://clan/2VC0Q9LV/war`. Tags in paths omit `#`; encode query values. Existing `clashking://player?tag=%23TAG` and clan query-tag links still work.

## Routes and initial state

| Destination | Path | Supported parameters |
| --- | --- | --- |
| Home | `/` | None |
| Players | `/players` | `tab=linked,bookmarks` |
| Clans | `/clans` | `tab=linked,bookmarks` filters the existing combined roster |
| War overview | `/war` | `clan=TAG` opens that clan's current war |
| Search | `/search` | `q`, `type=players,clans` |
| Player | `/player/TAG` | `tab=home,builder,battles,history,war,cwl,achievements,joinLeave` |
| Clan | `/clan/TAG` | `tab=members,warLog,joinLeave,statistics,rankings,cwlHistory,leaderboardHistory,legendHistory,records` when enabled |
| Capital | `/clan/TAG/capital` | `tab=summary,members,breakdown,history`, `day=YYYY-MM-DD` selects a loaded raid weekend |
| Current war | `/clan/TAG/war` | Regular war or active CWL war; `/war/TAG` is also accepted |
| Historical war | `/clan/TAG/war/20260904T120000.000Z` | Exact end timestamp in Clash format, not a fabricated war ID |
| CWL | `/clan/TAG/cwl` | `season=YYYY-MM`, `tab=rounds,teams,members`, `round=1..7` expands that round |
| To-do | `/todo` | `player=TAG` or `q` filters the user's existing to-do accounts |
| Ranked | `/ranked` | `player=TAG`, `tab=period,history`, `mode=details,ranking`, `day=YYYY-MM-DD` or `season=YYYY-MM` selects a loaded period |
| Upgrade tracker | `/upgrade-tracker` | `player=TAG`, `tab=home,builder,calendar,plan,collection`; existing account authorization still applies |
| Rankings | `/rankings` | `type=players,clans`, `board` (existing board name), `location` (country code or location ID), `period=current,history`, `day` or `season` for boards supporting history |
| Global statistics | `/stats` | `audience=battle,world`; battle sections `ranked,armies,items,war,cwl`; world sections `overview,players,clans`; `start` and `end` (YYYY-MM-DD, 1–90 days) |
| Calculators | `/calculators` | `mode=damage,farmGoal` |
| Posts | `/posts` | None |
| Announcement | `/posts/POST_ID` | Existing article ID |
| Bases/armies | `/bases-armies` | Existing preview page only; no item service exists yet |
| Game assets | `/game-assets` | `category`, `q`, `format`, `asset` (URL-encoded manifest path) |
| Achievements | `/achievements` | Account-wide achievements; no per-player/category control exists |
| Accounts | `/accounts` | Existing account-management page; no actions run automatically |
| Support | `/subscription` | Existing feature gate; no purchase runs automatically |
| Settings | `/settings` | None |
| Notifications | `/settings/notifications` | Native only; web opens main settings without requesting permission |
| FAQ | `/settings/faq` | `q`, `question` (existing FAQ ID) |
| Translation | `/settings/translation` | Opens the page; doesn't change the user's language |
| Privacy | `/settings/privacy` | Opens the page; doesn't export/delete anything |
| Licenses | `/settings/licenses` | `package` (package name, optionally including version) |

The parser rejects malformed tags/dates, untrusted hosts, credentials, and public auth destinations. Unknown optional values fall back to existing screen defaults. Links remain pending through app bootstrap/login. New destinations remount only their own state; ordinary primary navigation keeps its retained screens. Browser back/forward restores page destinations; screen controls are initialized from the URL, not continuously synchronized back to it.

Private account access and feature flags still apply. Missing data shows existing feedback. Stored CWL seasons never silently substitute another season. Historical war lookup verifies the returned end time exactly because the API itself permits a ten-minute nearest-match window.

## Widget handoff

iOS uses WidgetKit's `widgetURL`; Android uses per-widget VIEW intents. War links contain the instance's saved clan, and upgrade links contain its saved player. An unconfigured widget opens the corresponding overview. Refresh actions remain refresh actions. The iOS clan picker gets hydrated bookmark names from the app's shared data.

## HTTPS activation

Native configuration now includes the iOS associated domain and Android verified HTTPS intent filters for `app.clashk.ing`. The web export includes `/.well-known/apple-app-site-association` and JSON headers. Domain files still need deployment before HTTPS links can reliably auto-open the installed app.

Android additionally requires the **Play app-signing certificate SHA-256 fingerprint**, not merely the AAB upload-key fingerprint. Set repository variable `CK_ANDROID_APP_LINKS_SHA256` to it (comma-separated values support signing-key rotation). The existing web deployment action passes it to the export, which generates `/.well-known/assetlinks.json`. With no fingerprint, the export warns and omits the file instead of inventing a certificate. Custom-scheme widget links do not depend on domain verification.

No production deployment, GitHub release, store upload, or new signing secret was performed as part of these edits. No new per-item deep links or numerical calculator-prefill contracts were invented for controls/services absent from the current implementation.
