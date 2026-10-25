# Native-only application

The product UI runs on iOS and Android. Browser URLs are handoff links, not a desktop or mobile-web app. Do not add browser UI parity work or browser-based product verification.

## Browser boundary

- Native keeps `src/app/_layout.tsx` and the existing route/deep-link handlers.
- Metro uses `_layout.web.tsx` only to show the small public landing page. It does not mount the app runtime, login, data providers or product routes.
- `npm run web:export` builds a static landing artifact to `dist`; it does not export Expo screens. The existing deployment job can consume that artifact without a host change.
- `prepare-app-landing.mjs` derives two small JavaScript modules from the native route manifest and public-link parser. Never maintain a separate list of supported routes in the landing page.
- The Open button preserves supported route parameters and uses the registered `clashking:` scheme. Unsupported links return to app home. Authentication parameters are not forwarded.
- Existing Apple/Android association files and OAuth callback pages remain. Native Discord OAuth uses its existing custom-scheme callback and is unchanged.
- `/sw.js` retires the old cache and unregisters itself. The new site is not an installable PWA.

## Store links and release

Set `CK_IOS_STORE_URL` and `CK_ANDROID_STORE_URL` to the actual HTTPS App Store / Google Play listing URLs during the landing build to enable download links. Omitted values keep the matching store card visible but disabled and marked “Coming soon”; no listing URL is invented. These are optional public URLs, not secrets. The same validated configuration is used by the local landing preparation step.

The handoff page is a compact, centered screen with the app icon, a short explanation, the Open button, and two store buttons. It is not a marketing site or product web app. `open-app.js` preserves supported deep links, so unrelated/authentication query parameters are not forwarded.

Keep `CK_ANDROID_APP_LINKS_SHA256` configured with the Play signing certificate to generate verified Android app links. Apple association identity is retained. Changing domains or native entitlements is separate release work, not part of the landing switch.

No hosting, DNS, production deployment or native release is performed by local edits. After an authorized deployment, old browser app sessions receive the retirement worker; rollback requires deploying the earlier web artifact. Native data has no migration.

Legacy `.web.tsx` adapters and web dependencies remain for now. They are unreachable product UI, but a separate cleanup may remove them after native validation. Removing dependencies blindly can break shared tooling or native packages.

## Verification

Use code checks and native device/simulator verification for app screens. Do not run the former Playwright product suite against the landing; it no longer represents the product. Static landing build and link-parser inspection are appropriate without opening a browser.
