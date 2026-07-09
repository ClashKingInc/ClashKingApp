# Observability and Better Stack

The Flutter app uses the Sentry Flutter SDK as the client-side error reporting
library. By default it sends events to the ClashKing Better Stack
Sentry-compatible application. The default DSN is intentionally hardcoded because
Sentry-style DSNs are client ingestion identifiers, not account passwords.

`CK_SENTRY_DSN` can still be used to override the destination for local testing
or if the Better Stack application is rotated later. The Better Stack
environment is derived from `CK_API_ENV`.

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

The app works without extra flags. To override the DSN, pass a Dart define:

```powershell
flutter run `
  --dart-define=CK_SENTRY_DSN="https://APPLICATION_TOKEN@INGESTING_HOST/APPLICATION_ID"
```

Production example:

```powershell
flutter build appbundle --release `
  --dart-define=CK_SENTRY_DSN="https://APPLICATION_TOKEN@INGESTING_HOST/APPLICATION_ID" `
  --dart-define=CK_SENTRY_TRACES_SAMPLE_RATE_PERCENT=5
```

If `CK_SENTRY_DSN` is empty, the built-in Better Stack DSN is used.

## Available Dart defines

| Define | Default | Notes |
|--------|---------|-------|
| `CK_SENTRY_DSN` | built-in Better Stack DSN | Optional override for local/staging/rotation. |
| `CK_API_ENV` | `prod` | Also drives the Better Stack environment: `prod`/`production` -> `production`, `local`/`dev`/`development` -> `development`. |
| `CK_SENTRY_TRACES_SAMPLE_RATE_PERCENT` | `0` | Use a low value in production, for example `1` to `5`. |
| `CK_SENTRY_REPLAY_SESSION_SAMPLE_RATE_PERCENT` | `0` | Keep disabled for Better Stack; debug symbols/replay support is not equivalent to Sentry. |
| `CK_SENTRY_REPLAY_ON_ERROR_SAMPLE_RATE_PERCENT` | `0` | Keep disabled unless we intentionally test replay support. |

## Current app behavior

- Error reporting is enabled by default through Better Stack.
- The app sets:
  - `environment`
  - `release`
  - `dist`
  - authenticated user id and username
  - selected player tag context
- `sendDefaultPii` is disabled.
- Session replay defaults to `0%`.
- Centralized API calls add sanitized HTTP breadcrumbs. `/links/{id}` paths are
  redacted to `/links/:user_id`, and query strings/fragments are removed from
  breadcrumbs.

## Release pipeline note

No CI secret is required for the default Better Stack app. If a separate staging
or temporary Better Stack application is needed, pass it with
`--dart-define=CK_SENTRY_DSN=...`.
