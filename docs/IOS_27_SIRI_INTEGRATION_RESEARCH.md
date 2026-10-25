# iOS 27 Siri integration research

Research date: 2026-09-22

## Recommendation

Ship a small, read-only App Intents layer first: **Check Legend day**, **Check remaining war attacks**, **Check upgrades**, and **Find/open player or clan**. These are useful from Siri, Shortcuts, Spotlight, the Action button, and future widgets without pretending ClashKing belongs to an unrelated Apple schema domain.

iOS 27's more conversational Siri requires schema-conforming entities and intents for the new Apple Intelligence behavior. Apple's published primary schema domains cover areas such as audio, calendar, mail, maps, messages, notes, phone, and photos; there is no game-statistics or clan-management domain. Apple explicitly advises keeping custom App Intents for actions that do not fit and using the generic system search schema where search genuinely fits, rather than adopting the nearest incorrect schema. ([App schema domains](https://developer.apple.com/documentation/appintents/app-schema-domains), [Apple Intelligence Group Lab](https://developer.apple.com/videos/play/wwdc2026/8011/))

That makes the practical plan:

1. Use ordinary App Intents and App Shortcuts for Clash-specific questions on iOS 17 and later. These give deterministic Siri phrases and work in Shortcuts and Spotlight today.
2. On iOS 27, adopt `.system.searchInApp` for player/clan search and `.system.open` only where its contract exactly matches opening an entity. Keep the Clash-specific status intents custom until Apple publishes a fitting schema.
3. Delay direct roster writes. A spoken mutation needs authenticated execution, an explicit confirmation containing the exact clan/player/change, idempotent server behavior, and a safe ownership model.

## What is actually available

Apple released iOS 27.0 and Xcode 27 on September 14, 2026. This is no longer an announced-only OS release. The current development machine still has Xcode 26.5, though, so iOS 27-only source cannot be compiled or validated here until the toolchain is upgraded. ([Apple platform releases](https://developer.apple.com/news/releases/?id=01182023e), [iOS 27.0 release](https://developer.apple.com/news/releases/?id=09142026a))

| Capability | Existing through iOS 26 | iOS 27 change | ClashKing consequence |
| --- | --- | --- | --- |
| App Intent, App Entity, entity queries, App Shortcuts | Already available and back-deployable to ClashKing's iOS 17 floor. App Shortcuts expose selected intents to Siri, Spotlight, Shortcuts, and the Action button. | Still the foundation for every new Siri integration. | Build the first release with these APIs; do not make the useful status actions iOS 27-only. |
| Assistant schemas | `AssistantSchemas` and schema macros exist in the Xcode 26.5 SDK. | The public API is now presented as `AppSchema`; old `AssistantSchemas` symbols are deprecated. Schema conformance is the route to new Siri natural-language execution. | Put iOS 27 schema adapters behind availability checks while retaining ordinary intents for older systems. |
| Search and entity discovery | `EntityStringQuery`, Spotlight indexing, and App Entity view annotations already exist. | Siri can reason over schema-conforming indexed entities, use structured `IntentValueQuery`, and call the renamed `.system.searchInApp` schema. | Index only linked/bookmarked players and clans; use server queries for arbitrary tags and fast-changing global data. |
| Responses and context | Dialog, result values, snippets, and on-screen entity annotations already exist. | iOS 27 expands contextual Siri, interaction donations, ownership-aware confirmation, and content transfer. | Return short spoken summaries plus a compact status snippet; annotate the current player/clan screen later so “this player” can resolve. |
| Runtime and scale | Intents normally have bounded background execution. | New APIs include `ExecutionTargets`, `LongRunningIntent`, `SyncableEntity`, `EntityCollection`, `RelevantEntities`, richer/union parameter values, and `AppIntentsTesting`. | `ExecutionTargets` is valuable for separating native read work from foreground Expo handoff. Long-running work is unnecessary for status checks. CoC tags are natural stable IDs for `SyncableEntity`. |

Apple's iOS 27 release is public, but several current documentation pages still display beta/preliminary banners, including `.system.searchInApp`, `OwnershipProvidingEntity`, and `AppIntentsTesting`. Treat exact API signatures as needing verification against the shipping Xcode 27 SDK before implementation. ([searchInApp](https://developer.apple.com/documentation/appintents/appschema/systemintent/searchinapp), [OwnershipProvidingEntity](https://developer.apple.com/documentation/appintents/ownershipprovidingentity), [App Intents Testing](https://developer.apple.com/documentation/appintentstesting))

## Current ClashKing boundary

ClashKing currently defines `AppEntity` and `EntityStringQuery` types only in `expo/native/ios/WarWidget/WarWidget.swift`, for War, Legends, and Upgrade widget configuration. There is no `AppShortcutsProvider`, app-level App Intent, Spotlight entity index, or App Intents extension. Because those entity types are compiled into the WidgetKit extension target, they are a useful model but not yet a reusable app-wide Siri surface.

The existing Expo config plugin creates and wires the widget target, while `ClashKingNativeModule.swift` owns native app-group, secure-session, notification, and widget bridges. The TypeScript app already has validated public deep links for player, clan, war, Legends, and upgrade destinations. This provides a clean handoff path, but the current deep-link handler waits for authenticated app readiness before dispatching, so an open-app intent must handle signed-out users explicitly instead of silently waiting.

The right integration boundary is a small shared Swift intents package plus a dedicated App Intents extension, both generated/wired by the existing Expo config plugin:

- Shared Swift code owns `PlayerEntity`, `ClanEntity`, stable tag normalization, display representations, intent result models, and narrow cache decoding.
- The App Intents extension owns Siri execution, app-group reads, public endpoint reads, and secure authenticated reads. It must never copy tokens into `UserDefaults`; authenticated calls should read the existing access-group Keychain value at execution time.
- Expo remains the source of truth for feature UI and mutations. Open-style intents return the existing validated `clashking://` routes. Do not attempt to boot the React Native runtime headlessly inside an intent extension.
- The existing widget entities should move to or wrap the shared entities instead of creating a second player/clan identity system.

## Prioritized intents

### 1. Check Legend day

This is the strongest first intent because it is personal, frequent, read-only, and already has a native cache contract for bookmarked players.

- Entity: `PlayerEntity`, suggested from linked and bookmarked players, identified by canonical CoC tag.
- Data: read `legendsWidget_TAG` first for an immediate result, then make the same public battlelog/rank refresh used by the iOS widget when network time allows. Always speak the snapshot timestamp or stale state when the current Legend day is not fresh.
- Result: net trophies, attacks used out of eight, defenses taken out of eight, current trophies/global rank, and the latest attack or defense. Return a dialog plus a compact SwiftUI snippet; return the entity so a Shortcut can feed it into an open-player intent.
- Example phrase: “Siri, check Matthew’s Legend day in ClashKing.”
- Security: public data and a user-selected bookmark can be available while locked, but provide a setting to require authentication if users consider their tracked-player list private.

### 2. Check remaining war attacks

This has higher urgency than upgrades but needs more careful auth and freshness handling.

- Entity: `ClanEntity`, with an optional linked `PlayerEntity` when the question is about one member's attacks.
- Data: use the current war cache only when it includes a war identity, state, and timestamp; otherwise call the authenticated ClashKing/Clash API path through the existing secure session. Never infer “zero remaining” from a missing or failed response.
- Result: player remaining attacks, clan remaining attacks, war state, and time remaining. If the selected player is not in the current roster, say that directly.
- Example phrases: “Siri, how many war attacks does Matthew have left in ClashKing?” and “Siri, check Phoenix Fire’s remaining war attacks in ClashKing.”
- Security: set `authenticationPolicy` to require authentication for linked/private clan data. Apple notes that the default policy allows execution while locked, so leaving the default would expose data more broadly than intended. ([Intent authentication policy](https://developer.apple.com/documentation/appintents/intentauthenticationpolicy), [requiresLocalDeviceAuthentication](https://developer.apple.com/documentation/appintents/intentauthenticationpolicy/requireslocaldeviceauthentication))

### 3. Check upgrades

This is inexpensive because the upgrade widget already stores typed, timestamped account summaries in the app group.

- Entity: `PlayerEntity` restricted to linked accounts for private upgrade data.
- Data: cache-first from `upgradeWidget_TAG`; refresh through the authenticated repository only if a native endpoint can do so within the normal intent budget.
- Result: free/total builders, active laboratory/pet/Builder Base work, and the next completion with a relative time. A stale cache must be labeled, not projected forward as current.
- Example phrases: “Siri, what finishes next for Matthew in ClashKing?” and “Siri, how many builders are free in ClashKing?”
- Security: require authentication because upgrade state belongs to a linked account.

### 4. Find or open a player or clan

This is the only strong match for an iOS 27 system schema.

- Use `.system.searchInApp` to receive the person's search criteria and open ClashKing's existing search UI with the query. Apple says the schema works even when entities are not indexed. ([WWDC26 advanced App Intents](https://developer.apple.com/videos/play/wwdc2026/343/))
- Index only linked and bookmarked `PlayerEntity` and `ClanEntity` instances in Spotlight, updating and deleting entries when bookmarks change. Spotlight indexing makes those entities available to Siri as well as search. ([Spotlight integration](https://developer.apple.com/documentation/appintents/spotlight), [Making app entities available in Spotlight](https://developer.apple.com/documentation/appintents/making-app-entities-available-in-spotlight))
- Use `EntityStringQuery` for arbitrary public player/clan lookup because the global dataset is remote and fast-changing. Do not index every search result.
- Example phrases: “Siri, find Phoenix Fire in ClashKing” and “Siri, open Matthew’s Legends in ClashKing.”

## Mutations: defer direct roster editing

A future `SetRosterMemberIntent` can be valuable for clan leadership, but it should not be in the first release. Spoken names can resolve to the wrong player, clan rosters are shared state, and repeating an intent after a timeout can duplicate a non-idempotent write.

Before enabling it, require all of the following:

- a verified linked Discord/ClashKing identity with permission for the selected clan;
- an exact entity choice containing tag and display name, never a free-form name-only write;
- a server idempotency key and a precondition/version so a retry cannot overwrite newer roster work;
- local-device authentication and `requestConfirmation()` showing the clan, player, roster, and add/remove operation;
- `OwnershipProvidingEntity` on iOS 27 where the shared-clan ownership model is accurate;
- execution in the main app or a purpose-built App Intents extension selected with `ExecutionTargets`, never a background React Native side effect;
- a spoken and visual receipt containing the resulting roster state.

Until that exists, the intent should only open the roster editor with the player and clan preselected, then let the existing UI authorize and confirm the mutation. Apple explicitly recommends confirmation before destructive or unsafe work. ([requestConfirmation](https://developer.apple.com/documentation/appintents/appintent/requestconfirmation%28%29), [WWDC26 App Intents capabilities](https://developer.apple.com/videos/play/wwdc2026/345/))

## Delivery sequence

1. Upgrade CI and local validation to shipping Xcode 27 while retaining the iOS 17 deployment target.
2. Add the shared Swift intents package, `PlayerEntity`, `ClanEntity`, and App Shortcuts for the three read-only checks plus open/search.
3. Add cache-first native readers and a narrow authenticated HTTP client; keep dialogs useful on AirPods and snippets supplementary.
4. Index linked/bookmarked entities and donate only accurate interactions. Apple warns that excessive donations are ignored.
5. Add iOS 27 schema adapters for `searchInApp`/open and availability-gated `SyncableEntity` support; keep custom status intents for older releases and for Clash-specific concepts.
6. Add an AppIntentsTesting XCUITest target for entity resolution, cache freshness, auth failures, and result values, then manually verify Siri phrasing on a supported physical device. Apple says AppIntentsTesting exercises the same out-of-process stack as Siri, Shortcuts, and Spotlight without UI automation. ([AppIntentsTesting session](https://developer.apple.com/videos/play/wwdc2026/295/))

The first release should optimize for trustworthy answers rather than breadth: a correct cached answer marked stale is useful, while a fluent “zero attacks” or “no upgrades” produced from missing data is harmful.
