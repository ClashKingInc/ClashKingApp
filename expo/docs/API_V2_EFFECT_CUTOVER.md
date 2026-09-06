# ClashKing API v2 Effect integration

This is a local implementation and validation record. It does not authorize a package publication, native or OTA release, deployment, production configuration change, or CI dispatch. The workspace's `CLASHKING_REWRITE_REPLACEMENT_PLAN.md` is the governing plan. Earlier instructions in this document requiring a forced-update screen, raised minimum versions, or a compatibility period are superseded.

## Shared packages and compiler setup

The App uses Effect `4.0.0-rc.112`, browser-safe `@clashking/api-client`, and only `@clashking/api-contracts/expo`. Its API remains v2; the five stats request methods change from QUERY to POST. This does not introduce API v3 or retain an old-response compatibility layer. Home/activity is a sixth API-wide method change, but Expo has no caller for it.

For local integration, the manifest and lockfile use the API repository's packed artifacts under `../../clashking_api/dist/packages`. A fresh install from these archives replaces the saved snapshot's missing package-lock entries and transient dependencies. These local archives are provisional, reuse the `0.1.0-rc.0` version strings, and are not a final package freeze. The implementation status document records their exact identities and validation results.

TypeScript `6.0.3` stays at the canonical `typescript` name because Expo and lint tooling use its compiler/transpiler APIs. TypeScript `7.0.2` is installed as the `typescript7` alias for semantic checking. `npm run typecheck` verifies both roles, proves TS7 rejects an intentional type error, and then runs TS7 with `--noEmit` over the application. Bare `tsc` is not the supported substitute. `e2e:structure` is a separate syntax/structure check, not a semantic check or a device test.

`test:api-boundary` checks static imports, re-exports, dynamic imports, CommonJS requires, and type imports. It rejects every contracts package entry except `/expo`, then traverses the actual installed Expo contracts graph for forbidden server modules. The client remains on its browser-safe public entry point.

## Preserved behavior and explicit gaps

- Startup follows the recorded original source: authentication, game data, and application state initialize together; a revoked session can return to login without waiting for unrelated remote configuration. The saved rewrite's invented mandatory-update screen and precedence rule were removed. Feature-specific version rules remain; no global forced-update policy is added.
- Existing OTA signing/release scripts, native modules, and web service-worker workflow are preserved. The original unfinished OTA startup gate has also been ported narrowly: an opt-in native gate checks once, shows download progress, permits background continuation, and prevents a late reload after release or unmount. Its manifest-check deadline is five seconds; downloading clears that deadline. The matching `NEVER` automatic-check setting avoids a second owner. The original checkout and its unrelated dirty files remain unchanged; exact source hashes and test evidence are in `REWRITE_IMPLEMENTATION_STATUS.md`.
- Legend attack/defense notifications are retired by the user's explicit decision. Do not restore their preferences, controls, or backend delivery. The independent App already omits them and now has a targeted absence regression; general Legend statistics and supported war, raid, event, announcement, and support preferences stay unchanged. The fresh GitHub `main` audit still found stale App controls and transport fields; see `LEGEND_NOTIFICATION_RETIREMENT.md` for exact source links. That remote code is not an instruction to bring the retired feature back.
- Builder Hall distribution remains absent. The original API returns 501 for that route, and the original App's combined request caused the otherwise available Town Hall and league data to fail with it. The App now requests only the two supported distributions and never presents an invented empty Builder Hall result. A real-transport fixture guards that behavior.
- Connected-app approval remains retired as explicitly requested. This is separate from login and account verification.
- Existing authenticated exports, API error decoding, notifications, and feature-flag behavior stay on shared contracts. No storage hostname is invented: announcement and story media use API-returned URLs. Static game assets, badges, and OTA origins are outside this change.
- A full reconciliation against freshly fetched main and the newer original dirty `feat/0.4.2` now restores direct links, browser history, public metadata caching, current widget selection/handoffs, and native/web configuration. `SOURCE_RECONCILIATION.md` and its path-level JSON inventory record the exact sources and deliberate differences. Stored CWL links use the existing API endpoint through the restricted Expo entry; no Bot contract graph enters the App.

## Local validation

Run these in `expo/`, with a fresh install in this checkout:

```sh
npm ci --ignore-scripts --no-audit --no-fund
npm run typecheck
npm run lint
npm test -- --silent
npm run test:api-boundary
npm run e2e:structure
npm run l10n:check
npm run licenses:generate
npm run licenses:check
npm run test:release
npm run test:native-plugin
npm run test:web-build
npm run web:export
```

License generation must use the installed artifacts and production lockfile package set. A missing package license is a packaging issue to fix at its owner; do not suppress that package or fabricate a license in the App. Native-plugin and release-script tests use local fixtures and do not publish or install anything. A web export is a code build, not a visual or browser test.

## Work requiring a later release decision

1. Freeze a final source revision and immutable shared package pair, record their hashes, and validate every consumer against the same bytes. Current local `file:` dependencies are appropriate for this independent implementation, not a publish-ready lockfile. Package distribution must be decided before a standalone release checkout can install them.
2. Re-run the App checks against that final pair and review remaining API/schema/provider gaps with the coordinator. Passing App unit tests does not prove a live replacement API or production database.
3. Confirm the existing native/OTA delivery configuration and supported distribution targets before authorizing any release. No minimum version is raised by this implementation, no forced-update mechanism is presumed, and no compatibility layer is introduced.
4. Native compilation, device behavior, and real update delivery remain unvalidated here. They require separately authorized validation; there has been no prebuild, simulator, physical-device install, store submission, or OTA publication.

The user requested a coordinated replacement without backward compatibility. Older installed clients will not automatically gain POST requests or new code, so the handling of those clients is a release consequence to review explicitly, not a reason to silently add forced updates, proxies, compatibility routes, or a staggered deployment policy.
