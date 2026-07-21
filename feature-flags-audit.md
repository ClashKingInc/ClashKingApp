# ClashKing mobile feature-flag audit

Audit date: 2026-07-15. Scope: Flutter navigation, startup services, remote content, platform integrations, experimental surfaces, placeholders, and data-backed detail tabs.

## Policy

- Flag release-risk, external-service, expensive, incomplete, or remotely-authored surfaces.
- Do not flag core navigation and data needed to use the product: authentication as a whole, linked accounts, Dashboard, Players, Clan, War/CWL, search, bookmarks, language, theme, and legal/support access.
- Established production features fail open if config is temporarily unavailable.
- Preview, placeholder, or fabricated-data surfaces fail closed.
- A flag must gate the side effect as well as its button. Hiding a settings tile alone is insufficient.

## Implemented catalogue

| Key | Surface / side effect | Default | Reason |
| --- | --- | ---: | --- |
| `notifications` | Firebase initialization, device registration, notification settings | on | Operational kill switch; established feature |
| `posts` | Posts archive navigation | on | Remote content dependency |
| `home_announcements` | Automatic featured story presentation | on | Remotely-authored interruptive UI |
| `leaderboards` | Official proxy-backed rankings | on | External proxy/API dependency |
| `leaderboard_previews` | Unfinished endpoint mockups under rankings | off | Preview-only content |
| `global_stats` | Proxy-backed aggregate ranking statistics | on | External proxy/API dependency |
| `calculators` | ZapQuake and Fireball calculators | on | Complex formulas can be remotely withdrawn |
| `subscription_support` | `$1.99/month` support placeholder | off | No purchase flow exists |
| `upgrade_tracker` | Upgrade tracker and remote game-data parsing | on | Large, fast-moving feature with external data assumptions |
| `bases_armies` | Discord-synced bases/armies placeholder | off | No synchronized payload is implemented |
| `game_assets` | CDN/game-data asset browser | on | External asset dependency |
| `clan_rankings_preview` | Clan detail rankings tab | off | Ranks are currently fabricated previews |
| `cwl_history_preview` | Clan detail CWL history tab | off | Seasons and results are currently fabricated previews |
| `account_connections` | Discord/email connect-disconnect settings | off | Actions currently display placeholders only |
| `war_widgets` | Widget settings and background integration entry point | on | Platform-specific operational risk |
| `feature_requests` | Embedded external request portal | on | Third-party WebView dependency |

## Reviewed but intentionally not flagged

- **Dashboard, Players, Clan, War/CWL:** primary product contract. Maintenance and network error handling already provide the appropriate global fallback.
- **Search and deep links:** cross-cutting navigation infrastructure; partial flagging would create dead links and inconsistent push behavior.
- **Authentication as a whole:** must always retain at least one recovery path. Provider-specific auth flags can be added only with server-enforced guarantees that one method remains available.
- **Bookmarks and account management:** required local recovery/navigation tools.
- **Language, theme, help, privacy, licences:** safe local or mandatory surfaces.
- **Live Activity and notification debug tools:** already compile/runtime-gated with `kDebugMode`.
- **Observability sampling:** intentionally controlled by build-time environment values, not product flags.
- **Liquid Glass rendering:** platform capability and fallback widgets already decide this locally; remote switching would require rebuilding state throughout the widget tree.

## Defects found and corrected

1. The `notifications` condition wrapped the Language tile while the Notifications tile remained visible.
2. Push initialization and token registration occurred even when `notifications` was disabled.
3. Several production-visible surfaces contained placeholders or fabricated ranks/history without a kill switch.
4. Flag keys were string literals with no central fallback policy.
5. The client ignored the `min_app_version` rule configured in the admin panel.

## Follow-up before enabling fail-closed previews

- Replace clan ranking preview numbers with a real backend response.
- Restore CWL history only after the endpoint returns verified season data.
- Implement store purchase and restore flows before enabling subscription support.
- Implement Discord bases/armies payload synchronization before enabling that entry.
- Implement real account connect/disconnect actions before enabling account connections.
