# Error reporting

The Expo app uses the Sentry React Native SDK for error reporting. Its public
Sentry DSN is built into the app, so native, OTA, web, and local bundles use the
same project without a CI secret. `EXPO_PUBLIC_CK_SENTRY_DSN` can override that
destination for a temporary test project.

## Current behavior

The integration sends error events only. Tracing, profiling, replay, logs,
sessions, HTTP breadcrumbs, screenshots, view hierarchy, failed-request
capture, and client reports are disabled.

Before an event is sent, the app removes user, request, context, extra,
breadcrumb, frame-variable, and server-name data. It sanitizes URLs, link user
ids, query strings, fragments, email addresses, IP addresses, bearer tokens,
and common secret parameters. Events retain the release, build number,
sanitized exception and stack, and a sanitized operation tag.

The same exception object is reported once. Equivalent sanitized error
signatures are also reported once per app session, with the in-memory signature
index capped at 256 entries. Restarting the app starts a new session, so a
persistent failure remains visible across launches without generating an event
for every retry.

## Optional destination override

```sh
EXPO_PUBLIC_CK_SENTRY_DSN="https://PUBLIC_KEY@INGEST_HOST/PROJECT_ID" npm start
```

The DSN is a public ingestion identifier embedded in every client bundle. It is
not an account credential. Source-map and native-symbol uploads, if added later,
must use a separate private Sentry auth token in CI.

The Sentry environment follows `EXPO_PUBLIC_CK_API_ENV`: `local` and
`development` map to `development`, production maps to `production`, and other
named environments are preserved.

## Profiling

Profiling remains disabled. Enabling mobile UI profiling would require an
explicit sampling policy and Sentry billing decision; it should not be coupled
to basic error reporting. A temporary local-only profiling project can be used
for focused investigations without changing production collection.
