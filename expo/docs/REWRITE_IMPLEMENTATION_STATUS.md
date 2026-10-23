# Expo rewrite implementation status

## Checkout and source evidence

Work is local and uncommitted in the independent repository:

`/Users/matthewanderson/Documents/Codex/2026-09-03/http-effectnative-dev-can-this-be/implementation/ClashKingApp`

This is a detached checkout of saved rewrite snapshot `9d7fd109d8a23e9f0306a3f5c447cfc98eb656f1`, recovered from `refs/codex/snapshots/146510a6af5b6d9316889f269d7ea5dcf70e9645` in `/Users/matthewanderson/IdeaProjects/ClashKingApp`. It has its own `.git`, no remote, and no linked worktree. The original checkout and its dirty work were not changed. The recorded original source is `f9c531da597e0e0cb6f09a26916f19501972fcfb`; neither commit is asserted to be the deployed App.

The later full reconciliation also fetched GitHub main directly at 2026-09-04 16:13:38 UTC, resolving to `c90a766afb4abf4598cf85979109e8e402f54ce1`, and reviewed the original dirty `feat/0.4.2` checkout. `SOURCE_RECONCILIATION.md` describes the restored behavior; `SOURCE_RECONCILIATION.json` records all 263 relevant paths and source hashes. Of 885 original files, 801 now match byte-for-byte, 81 intentionally differ, and only the three retired raw-client files are absent. This is source evidence, not a deployment assertion.

## Corrections in this implementation

1. **Repeatable local installation.** The saved manifest named the two API packages, but its lockfile did not contain them. The manifest and lockfile now install the API owner's provisional tarballs. A fresh `npm ci --ignore-scripts --no-audit --no-fund` installed 1,269 packages in this checkout. Regeneration added the two packages and eleven missing Babel/Metro peer entries without changing any previously locked package version. npm also corrected dependency classification metadata; the production license list must follow that actual lockfile.
2. **Original startup behavior.** `startup-coordinator.ts` and `app-state.ts` again use the original concurrent initialization and fail-fast behavior. The saved rewrite's mandatory-update result, scene, component, and feature-service state were removed. A revoked session can reach login while configuration is still pending. Typed shared-client error classification stays intact. Feature-specific minimum versions remain supported, and existing OTA configuration/release tooling was preserved.
3. **Enforced mobile package boundary.** `scripts/api-package-boundary.mjs` parses imports, exports, dynamic imports, requires, and type imports; only `@clashking/api-contracts/expo` is accepted. The installed Expo contracts graph is checked for server-only modules. Tests cover both forbidden imports and legitimate client/Expo imports.
4. **Verified TypeScript split.** Canonical TypeScript `6.0.3` provides the compiler APIs required by Expo and lint tooling. The `typescript7` alias is exactly `7.0.2`; the typecheck script first tests both compiler roles and proves that the alias rejects an intentional semantic error, then checks the App with TS7. Effect remains exactly `4.0.0-rc.112`.
5. **Explicit unavailable-feature regression.** A real shared-transport fixture verifies Town Hall and league distributions load while the Builder Hall route remains a 501. No Builder Hall request is made and no fabricated Builder Hall result is returned. The five former stats QUERY requests retain existing real-transport POST-body tests.
6. **Corrected implementation guidance.** `API_V2_EFFECT_CUTOVER.md` no longer directs an unapproved forced-update rollout, compatibility layer, or version escalation. It separates local verification from later package/native/OTA/deployment authorization.
7. **Complete dependency license inventory.** The API owner added its inherited root license to both packages. The App inventory was regenerated from the fresh install; each installed API license was verified byte-for-byte against the API root file. The coverage test now uses npm's canonical package name for aliases such as `@jest/react-is-18` → `react-is`; it still requires an exact match with the full production package set and does not exempt missing licenses.
8. **Preserved original unfinished OTA startup flow.** The first pass retained only the saved snapshot's OTA configuration/release tooling. A follow-up now also ports the original dirty `StartupUpdateGate`, its actual `ApplicationRoot` wrapper, optional loading progress/background controls, and three existing translations in all 33 locales. Native automatic checking is `NEVER` so this opt-in gate owns checking once; `CK_ENABLE_UPDATES` and signing requirements remain intact. This is separate from the removed mandatory minimum-version policy.
9. **Reconciled newer original work.** Direct links now survive login, open the correct screen/entity/parameters, and participate in browser history. The current widget selection/handoff behavior, public game-data cache, safe service-worker handling, web viewport/association configuration, iPad orientations, and current native dependency selection are restored. Existing screen components and reduced-motion behavior remain; this was not a redesign.
10. **Stored CWL contract integration.** The API owner exposed the existing stored-group endpoint through the restricted Expo entry. The App verifies requested season/clan and hydrates stored wars without Bot imports. Explicit missing seasons do not become live seasons. The newly packed contracts install cleanly and the package-boundary graph passes.
11. **Preserved failure behavior.** Clan capital results survive an ordinary API error from another clan, while offline search and ranked-group transport failures remain visible instead of appearing as empty results. Focused regressions accompany these corrections. Exports use only the fields supported by the current authoritative Go endpoint; unsupported old payload filters were not invented in the backend.

## Reviewed omissions, not hidden completion claims

- Legend attack/defense notifications are confirmed retired by the user, not an open implementation decision. Keep their preferences and controls absent; do not add notification storage/delivery. A fresh GitHub `main` fetch on 2026-09-04 still found stale model/transport fields and controls at `c90a766afb4abf4598cf85979109e8e402f54ce1`, while this independent App omits them. `LEGEND_NOTIFICATION_RETIREMENT.md` records the exact remote source links and scope; two regressions protect defaults, parsing, request/local serialization, and control/model absence. General Legend statistics and supported notification preferences remain untouched.
- The original App's `expo/src/features/stats/data/stats-repository.ts` requested Builder Hall counts in the same `Promise.all` as working Town Hall/league counts. The recorded original API's Builder Hall route returns 501, which the new API deliberately preserves. The App omission fixes that old combined-load failure rather than removing working count data.
- The original unfinished OTA startup gate is now integrated and covered by code tests, not verified on a native device. The five-second limit applies to the manifest check; downloading clears that timer. The existing background action releases startup and prevents a later reload, as do timeout/unmount. Web, development builds, and disabled updates bypass the gate. No download timeout or forced store-update policy was invented. The subsequent full reconciliation also integrated the relevant original navigation/configuration work, including both iPad landscape orientations. Earlier status text saying those changes remained unported is superseded.
- Android HTTPS auto-opening needs the actual Play app-signing fingerprint in `CK_ANDROID_APP_LINKS_SHA256` at release time. The local export did not receive it and correctly warned without generating a fake association file. iOS/Android link verification and native widget behavior are source-tested, not device-tested.
- Connected-app approval remains intentionally retired. No replacement consent flow, new forced-update policy, new notification persistence, new count provider, storage bucket, proxy, compatibility route, or new API version was introduced.

## Original OTA source pins and port boundary

The original checkout remains at HEAD `f9c531da597e0e0cb6f09a26916f19501972fcfb` with unfinished user work. These are Git blob hashes of the exact dirty files read before porting, not claimed commits or deployed source:

| Original file under `expo/`                 | Git blob hash                              | Port                                                                                      |
| ------------------------------------------- | ------------------------------------------ | ----------------------------------------------------------------------------------------- |
| `src/core/app/startup-update-gate.tsx`      | `1cdc32d08865763d83fe520f2f80c29312303a9f` | Exact file copied.                                                                        |
| `src/core/app/startup-update-gate.test.tsx` | `ee9dcf4f3753abd632c3d10da73b3b6ef15da425` | Exact five helper tests copied.                                                           |
| `src/core/app/startup-loading.tsx`          | `184d837c5f75a7382411247a520ac2cf2057393b` | Exact file after applying only its OTA additions.                                         |
| `src/core/app/application-root.tsx`         | `90a3f85490b284e52e588226566144bf61b45c2f` | Gate import/wrapper and `ApplicationContent` split only; shared API corrections retained. |
| `app.config.ts`                             | `5272e3a74f3fc34b114268b38abef26aefa62c0c` | First port changed `NEVER` only; full reconciliation now matches the complete original dirty config, including iPad orientations and public-link configuration. |

The gate and loading source files remain byte-identical to those original blobs. The five copied helper test cases remain unchanged, with a test-only observability mock added to avoid importing the native monitoring SDK's cleanup interval. The 20 focused tests also pass with `--detectOpenHandles` and no reported open handles.

The three message keys are `startupCheckingUpdate`, `startupDownloadingUpdate`, and `startupUpdateInBackground`. Each value was checked against all 33 original ARBs, and every other parsed ARB field remains identical to the independent snapshot. The SHA-256 of the ordered `[filename, selected-three-key-object]` JSON is `46cd5d56a8fe2e964d92640e8f8acbb7717cf3785f84da5cb577b3121fc035a7`. Existing localization generation updated the 33 catalogs.

No runtime dependency of this bounded gate remains unported. `expo-updates`, observability, themes, and localization were already installed/present. The additional lifecycle tests fake update calls and prove disabled/web/dev bypass, the exact check deadline, progress forwarding, download completion, no reload after background/timeout/unmount, and error release. A source contract regression verifies `ApplicationRoot` actually wraps bootstrap in the gate and verifies opt-in plus `NEVER`; the loading component regression checks its button callback and progress props.

One inherited detail is recorded without expanding this port: the original progress `View` declares an accessibility role/value but omits `accessible={true}`, so the test renderer's accessible-role lookup excludes it. The code test checks the emitted role/value props; it does not claim native screen-reader accessibility. Native accessibility review remains a later task.

## Provisional package identity

Final local validation used these API-owned archives at `implementation/clashking_api/dist/packages`, both version `0.1.0-rc.0`:

| Archive                                  | SHA-256                                                            |
| ---------------------------------------- | ------------------------------------------------------------------ |
| `clashking-api-contracts-0.1.0-rc.0.tgz` | `9d7ba741673dd37f4024cd620f3342eb0e6b5d43de5994909f1ba53d0317848b` |
| `clashking-api-client-0.1.0-rc.0.tgz`    | `6efb92517bea793d891ca255d0aaf1602cd06e058652d6d3e2523e67ab689035` |

The lockfile SHA-512 integrities were verified directly against those archive bytes:

- Contracts: `sha512-+bNpyVbsKd5sSEbrBZufWQpqC1MD+N+Tdo6FgtF3NTygYcT39EVDTmmFVoyWqWFI1127Shsb7QPW/revpVQhpA==`
- Client: `sha512-BMBvh1xwHSZkcjhPp3ZGcJgR0DLHBcGzKHq2E+dO6h6biPkds9HbzKfP9FkDM5IInDeLFCNmWNODqVgfqlfxRA==`

These replace earlier provisional archives and include the restricted stored-CWL contract plus the API owner's final canonical Bot/Admin corrections. The Expo import surface remains restricted and unchanged. Explicit local-tarball reinstallation refreshed the same-version lock entries before another clean install; archive hashes and lock integrities were verified directly. All 144 installed contracts files and all six client files match the packed bytes. Both packages include `SEE LICENSE IN LICENSE` metadata and a 35,149-byte license identical to the API root. No package was published or frozen for release.

The final refresh on 2026-09-04 used a fresh, App-specific npm cache. The first sandboxed download failed with DNS `ENOTFOUND`; the completed network-authorized retry installed all 1,269 locked packages. No package version changed. The regenerated license inventory remained byte-identical. This pass changed only the lockfile and these status/inventory records: a combined hash of the other 896 source files remained `1edd05785837d87877f7e0e74a1eeb555f32f3e8500fdee6cee23f399b9891c4`.

## Validation record

Final local checks using Node `26.8.1` and npm `12.0.0`:

- Fresh install: 1,269 packages; own checkout dependency tree, repeated after the latest API-owned package refresh. No unrelated dependency version change was introduced.
- Full Jest suite repeated after the final package refresh: 177 suites and all 932 tests passed, including Builder Hall transport, exact license coverage, OTA/runtime wiring, direct links/inbox, stored CWL, caching, widgets, and transport-failure behavior.
- TypeScript: full semantic application check passed; two toolchain regression tests passed.
- Startup/feature-flag corrections: 25 focused tests across five files passed.
- OTA focused checks: 20 tests across four files passed, including three existing loading/runtime tests.
- Contract boundary: ten tests passed; actual scan covered 531 App files and 18 contracts modules.
- Lint, localization check, and E2E structure check passed. The latter checked 23 files without executing E2E tests.
- Native-plugin, release-plan, release-manifest, web-service-worker, and association-file tooling: 57 local fixture tests passed. The final combined tooling run passed 69 tests including the ten package-boundary and two compiler-role regressions.
- License generation/check passed: 324 verbatim license texts cover 964 production package records.
- Offline Expo web export was repeated successfully against the final packages: 27 static routes and two web bundles, followed by association generation and service-worker stamping (`72ff7e7d18e16411`). Export logged the missing local Android signing fingerprint, web notification-listener limitation, Node's experimental local-storage warning, and an Expo cleanup/forced-exit notice; the command exited successfully with generated output. Earlier nonsilent Jest runs emitted existing React `act` and InteractionManager warnings; the final full run used `--silent`. No browser or visual check was run.

Local implementation validation is complete; this is not a release-readiness statement.

## Remaining work and boundaries

- Freeze and distribute the final API package pair only after cross-repo review; then update any release lockfile and repeat consumer checks. Current local paths intentionally depend on this workspace layout.
- The coordinator still owns real API/schema/provider validation and coordinated release planning. App tests use fake network responses, not production API calls.
- Native compilation, prebuild, physical-device/simulator/browser checks, Expo Doctor, store submission, OTA behavior, and deployment have not been run. There has been no publication, push, commit, CI dispatch, or production mutation.
