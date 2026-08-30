# Observability and Better Stack

The Expo app uses the Sentry React Native SDK as the client-side error reporting
library. By default it sends events to the ClashKing Better Stack
Sentry-compatible application. The default DSN is intentionally hardcoded because
Sentry-style DSNs are client ingestion identifiers, not account passwords.

`EXPO_PUBLIC_CK_SENTRY_DSN` can still be used to override the destination for local testing
or if the Better Stack application is rotated later. The Better Stack
environment is derived from `EXPO_PUBLIC_CK_API_ENV`.

## Better Stack setup

1. In Better Stack, open **Errors → Applications**.
2. Create or select the ClashKing mobile application.
3. Open **Data ingestion**.
4. Copy the Sentry-compatible DSN:

   ```txt
   https://$APPLICATION_TOKEN@$INGESTING_HOST/$APPLICATION_ID
   ```

Better Stack documents this Sentry SDK flow here:
https://betterstack.com/docs/errors/collecting-errors/sentry-sdk/

## Optional build-time configuration

The app works without extra variables. To override the DSN for an Expo run or build:

```sh
EXPO_PUBLIC_CK_SENTRY_DSN="https://APPLICATION_TOKEN@INGESTING_HOST/APPLICATION_ID" npm start
```

Production example:

```sh
EXPO_PUBLIC_CK_SENTRY_DSN="https://APPLICATION_TOKEN@INGESTING_HOST/APPLICATION_ID" \
EXPO_PUBLIC_CK_SENTRY_TRACES_SAMPLE_RATE_PERCENT=5 \
npx expo export
```

If `EXPO_PUBLIC_CK_SENTRY_DSN` is empty, the built-in Better Stack DSN is used.

## Available Expo environment variables

| Define                                                      | Default                   | Notes                                                                                                                                       |
| ----------------------------------------------------------- | ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `EXPO_PUBLIC_CK_SENTRY_DSN`                                 | built-in Better Stack DSN | Optional override for local/staging/rotation.                                                                                               |
| `EXPO_PUBLIC_CK_API_ENV`                                    | `production`              | Also drives the Better Stack environment: `production` -> `production`, `staging` -> `staging`, and `local`/`development` -> `development`. |
| `EXPO_PUBLIC_CK_SENTRY_TRACES_SAMPLE_RATE_PERCENT`          | `0`                       | Use a low value in production, for example `1` to `5`. Values are clamped to `0` through `100`.                                             |
| `EXPO_PUBLIC_CK_SENTRY_REPLAY_SESSION_SAMPLE_RATE_PERCENT`  | `0`                       | Keep disabled for Better Stack; debug symbols/replay support is not equivalent to Sentry.                                                   |
| `EXPO_PUBLIC_CK_SENTRY_REPLAY_ON_ERROR_SAMPLE_RATE_PERCENT` | `0`                       | Keep disabled unless we intentionally test replay support.                                                                                  |

## Current app behavior

- Error reporting is enabled by default through Better Stack.
- The app sets:
  - `environment`
  - `release`
  - `dist`
  - authenticated user id only
- The selected-player context is explicitly removed and isn't sent with events.
- `sendDefaultPii` is disabled.
- Session replay defaults to `0%`.
- Centralized API calls add sanitized HTTP breadcrumbs. `/links/{id}` paths are
  redacted to `/links/:user_id`, and query strings/fragments are removed from
  breadcrumbs.
- The SDK's automatic network and navigation-history breadcrumbs are disabled so
  they cannot duplicate those requests with raw account ids or query strings;
  safe default integrations such as error handlers remain enabled.

## Release pipeline note

No CI secret is required for the default Better Stack app. If a separate staging
or temporary Better Stack application is needed, pass it with
`EXPO_PUBLIC_CK_SENTRY_DSN=...`.
