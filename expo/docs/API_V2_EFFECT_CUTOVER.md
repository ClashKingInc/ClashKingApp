# ClashKing API v2 Effect cutover

This is a preparation checklist. It does not authorize publishing npm packages, dispatching a mobile release, changing Cloudflare traffic, or raising either native minimum version.

## Current validation boundary

The app declares the shared registry prereleases, but the API owner has not yet frozen or published the final package pair. The checked-in lockfile therefore still needs registry resolution after publication; a clean `npm ci` is a required open gate. Local typechecks, tests, and web export use transient builds of the shared packages in `node_modules`, not vendored source or release tarball dependencies. Regenerate the license inventory again after the final registry lockfile is available.

## Non-outlined decisions

- TypeScript 7.0.2 is installed as the secondary alias `typescript7`. `npm run typecheck` explicitly invokes that compiler with `--noEmit` for semantic application typechecking. `npm run e2e:structure` invokes the same compiler with `--noCheck --noEmit` for syntax checking only; it does not typecheck the E2E tests. Use `npm run typecheck` rather than bare `tsc`, which currently resolves to TypeScript 6 in the Expo checkout.
- TypeScript 6.0.3 remains under the canonical `typescript` package name for tooling that requires the established compiler, transpiler, or language-service APIs. This includes typescript-eslint and Expo's `@expo/require-utils` loader, which calls `transpileModule`; the TypeScript 7 package's root export does not provide those legacy APIs. The installed typescript-eslint packages also require the peer range `>=4.8.4 <6.1.0`. Jest transforms and structural AST checks use Babel, separately from the TS7 semantic typecheck. This package split preserves tooling compatibility and valid npm peer resolution without `--force`, `--legacy-peer-deps`, or runtime require interception.
- The repository's OTP inbox Worker uses the standard `typescript@7.0.2` package, so both of its plain `tsc` commands resolve to TypeScript 7.0.2. The other repository packages do not declare or invoke a TypeScript compiler; GitHub workflows call the Expo `typecheck` script rather than a separate `tsc` binary.
- `react-test-renderer` is pinned to `19.2.3`, matching Expo's exact React version. Its former caret range selected `19.2.8` during fresh resolution, whose React peer caused a clean npm install failure.
- The two legend notification toggles and transport fields were removed because the authoritative schema and API do not support them. Other legend-related player statistics and home tasks are unchanged. Raid reminder preferences remain supported by the canonical schema and Worker implementation.
- Builder Hall distribution was removed from the statistics screen and repository because its backend route was never implemented (501). It is not represented as a successful empty distribution.
- Player workbook downloads now use the shared authenticated client and the authoritative `player_tag`, optional timestamp bounds, and limit fields. The old helper sent unsupported plural player tags and filter fields; the export endpoint does not implement season, Town Hall, star, or war-type filtering.
- HTTP error behavior is mapped from the shared tagged errors; malformed success payloads are rejected by shared schemas rather than accepted through legacy parsing. The no-war response remains JSON `null`, and official clan search has its own schema without detail-only member fields.
- Clan Capital contracts were checked against the complete stored official fixture: defense logs use `attacker`, untouched districts may omit `attacks`, and older seasons may omit `members`. These are separate typed wire fields, not compatibility aliases.
- HTTP breadcrumbs and sanitized exception reporting are retained around the shared transport/client. Breadcrumb latency measures receipt of response headers; body size is recorded only when declared by `Content-Length`, so streamed downloads are not cloned or buffered for diagnostics.
- License coverage is checked against the actual production lockfile package set, replacing a fixed dependency-count threshold.
- The unused Bunny CDN constant was removed. Announcement banners and stories retain the canonical API-returned `banner_image_url` and `story_url`, including R2-backed media URLs; the app does not reconstruct them from a storage hostname. Static game assets, badges, and OTA origins remain separate and unchanged.

## Release artifacts

The QUERY-to-POST migration covers six routes across the API: home/activity and five stats routes. Expo calls only the five stats routes (`armies`, `items`, `ranked`, `war`, and `cwl`); all five now use shared POST contracts. Home/activity is part of the API-wide cutover, not a sixth Expo caller. Do not add an unused app operation to match the API route count.

### Shared-package freeze

Before publishing the release candidate, expose the existing Expo-only contracts barrel as the `@clashking/api-contracts/expo` package subpath and move every app import to it. The Expo barrel must also re-export the shared `endpoint`, `app-config`, and `stats` modules; those provide the generic endpoint types, app update policy, and five POST contracts used by the app. The root contracts barrel also exports Admin, Dashboard, bot, and persistent-runtime contracts, so the React Native dependency graph must not import the root even though the current schemas have no Node, Cloudflare, PostgreSQL, or Redis runtime imports. Keep `@clashking/api-client` on its public root export; its contracts dependency is type-only at runtime.

Freeze and validate one immutable package pair:

1. Record the API source commit and build both packages from that exact clean revision. Run their typechecks and tests before publishing.
2. Verify that `@clashking/api-client` depends on the exact contracts version, both packages use the exact Effect v4 release candidate, and the contracts package exports `./expo` to `dist/expo.js` and `dist/expo.d.ts`.
3. After publishing, query npm for each package's version, `dist.tarball`, and `dist.integrity`. Save those identities with the source commit; do not validate against local tarballs or workspace links.
4. Regenerate `package-lock.json` from the registry. Its two package entries must use the exact versions, HTTPS npm tarball URLs, and SHA-512 integrity values, with no `file:`, `link:`, workspace, or worktree references.
5. In a clean checkout of the final app commit, run `npm ci` without transient package builds. Confirm the installed package metadata and bytes match the lockfile, then run the full validation commands below.

The clean validation run is: `npm run typecheck`, `npm run lint`, `npm test -- --silent`, `npm run test:api-boundary`, `npm run e2e:structure`, `npm run l10n:check`, `npm run licenses:generate`, `npm run licenses:check`, `npm run test:release`, `npm run test:native-plugin`, `npm run test:web-build`, `npx expo-doctor`, and `npm run web:export`. In disposable clean checkouts, also generate both native projects with the same certificate-backed `npx expo prebuild --platform android --clean --no-install` and `npx expo prebuild --platform ios --clean --no-install` commands used by release CI. Do not run `prebuild --clean` in a dirty checkout.

PR checks enforce the committed license inventory and release-tooling tests. The manual release workflow also runs the local code, contract-boundary, localization, license, and tooling checks on the exact checked-out release commit before materializing signing inputs, creating a GitHub release, or starting native/OTA publication. These gates verify committed output; they do not regenerate and silently accept a stale license inventory during a release.

The following local candidate identities are historical and superseded. They are not the final freeze and must not be used to approve a cutover; the API's shared contracts have changed since these candidates were built:

- `clashking-api-contracts-0.1.0-rc.0.tgz`: historical SHA-256 `81823829f0cbcba25e406e2dec2aa50bd225e60fe8f4047b0f6d78af201549d1`; historical integrity `sha512-BmHOi0M+XGzukIqNJGCpzpgcLB7bSudJvVzWPh5M8gItpkjx0QxRgdOVDdOT/rVO+eqZngZLvX4YLUCGe1ZpBw==`.
- `clashking-api-client-0.1.0-rc.0.tgz`: historical SHA-256 `26303df84bf81f7be13ff49ef036c7c245dd7c03113c084686bf80faa7dcae8a`; historical integrity `sha512-80+OBTpuDqqjS6qMnyL8gsvhoAxhflhGw8Qs13fM5QJ0d4crSzGyhBsBb5Mx/pbiJ3Qznhygz0KZx5qkslboSA==`.

The latest local previews also reuse the `0.1.0-rc.0` version strings, so a version match alone is not evidence of matching bytes. After API integration is stable, freeze a new exact source revision and package pair, record their SHA-256 and SHA-512 identities, and rerun every consumer against that pair. After publication, npm must report those newly frozen SHA-512 values before the registry lockfile is accepted. A mismatch means the published bytes are not the validated candidates even if the version strings match.

- Publish `@clashking/api-contracts@0.1.0-rc.0` and `@clashking/api-client@0.1.0-rc.0` from the API repository, then regenerate this app's lockfile from the registry. A local tarball or worktree path must not appear in the release lockfile.
- Use the repository's `Release mobile app` GitHub workflow for native builds. This project does not have an `eas.json`; iOS is built and uploaded through Xcode/TestFlight, and Android is built and uploaded through Gradle/Google Play.
- Choose an `x.y.0` release version so the workflow creates native binaries. Patch versions `x.y.1+` are OTA-only and cannot carry a new native runtime or protect users who do not already have the forced-update code.
- Keep beta and production independent. Beta uploads to TestFlight and Play internal testing; production uploads to the production Play track and submits iOS for App Store review.

## Required configuration

The API's public `GET /v2/app/config` response must contain validated policies for both native platforms:

```json
{
  "updates": {
    "ios": {
      "minimum_version": "x.y.0",
      "store_url": "https://apps.apple.com/...",
      "message": "..."
    },
    "android": {
      "minimum_version": "x.y.0",
      "store_url": "https://play.google.com/store/apps/details?id=...",
      "message": "..."
    },
    "web": null
  }
}
```

Do not raise `minimum_version` until that exact version is downloadable from the corresponding production store. Web is intentionally ungated. A config fetch failure is fail-open so a transient API outage does not strand an otherwise usable installed app. Startup waits for the policy refresh even if authentication or translation loading fails first; once a mandatory update is known, it takes precedence over recoverable error screens and account bootstrap.

The release workflow expects the existing environment secrets documented in the repository README: Apple distribution and App Store Connect credentials, Android signing and Play service-account credentials, the Expo Updates certificate/private key, and the R2 update credentials/origin. Confirm them in both GitHub Environments before dispatching a build; do not copy production credentials into local files.

OTA storage is a separate, unresolved deployment gate. The release workflow selects the `beta` or `production` GitHub Environment and reads `R2_UPDATES_BUCKET_NAME` from secrets and `R2_UPDATES_PUBLIC_ORIGIN` from variables. `expo/scripts/publish-release.mjs` writes to that bucket through the account's R2 S3 endpoint; `release-plan.mjs` reads the same bucket's `releases/` markers. No app source establishes `clashking-app-updates` as the actual bucket. Before binding the Worker's `APP_UPDATES` provider, confirm both environments' bucket names, the serving origin, and existing `releases/<track>/<version>/release.json` objects. Resolve any difference between the track configurations explicitly. Do not create an empty bucket merely to satisfy an unverified binding name.

## Cutover order

1. Publish and verify the two shared packages, update `package-lock.json`, and run `npm ci`, typecheck, lint, unit tests, localization checks, license checks, `expo-doctor`, and native-plugin tests from a clean checkout.
2. Deploy the Effect Worker as a candidate without switching production traffic. Validate contract/OpenAPI parity, authentication, binary exports, expected 204/404 behavior, and all five Expo stats POST operations against that candidate.
3. Build the native `x.y.0` beta release, install the TestFlight and Play-internal artifacts, and verify startup, authentication, account linking, stats, notifications, exports, and the update gate against candidate configuration.
4. Promote/build the production native release. Wait until the exact binary is downloadable from both store URLs.
5. Serve the new update policy from the currently active API, verify the typed config response, then raise the native minimum versions. Only after the gate is confirmed should Cloudflare traffic move to the Effect Worker.
6. Hold the previous API deployment and configuration ready until error rate, auth refresh, schema-decode failures, and the five converted stats endpoints are stable.

## Compatibility condition

Clients released before the forced-update screen cannot enforce this policy. Production traffic must therefore retain the response compatibility those builds need, or the edge must have another explicit version-enforcement mechanism, until their remaining usage is acceptable. The minimum-version field by itself does not protect an older binary that never reads it.

## Rollback

If the Worker fails before the minimum is raised, restore the prior Cloudflare route/deployment and leave store releases unchanged. If it fails after the minimum is raised, first restore the prior API deployment, then lower the native minimum policy to the last supported store build and verify `GET /v2/app/config` from outside the deployment environment.

Store binaries are not instantaneously reversible. Use an OTA rollback only when both platform fingerprints match the target native runtime and the rollback does not depend on removed API behavior. Otherwise ship a new native build number while the prior API remains available.
