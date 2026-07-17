# Global privacy compliance readiness

This app is a general-audience Clash of Clans companion app intended for Google Play and App Store distribution in all eligible countries. This document records the product and engineering controls needed for privacy review. It is not legal advice.

## Regulations and policies covered

- EU GDPR and ePrivacy: lawful basis, transparency, minimization, data subject rights, consent withdrawal, international transfer awareness.
- UK GDPR and Data Protection Act / ICO children's code: same controls as GDPR plus child-appropriate transparency for users likely to be under the local digital-consent age.
- California CCPA/CPRA and other US state privacy laws: notice, access, deletion, correction, opt-out posture, sensitive data minimization.
- US COPPA and similar children's privacy rules: app is not child-directed; avoid behavioral ads/tracking; provide parental/support contact path.
- Google Play User Data, Data Safety, Account Deletion, and Families policies: in-app privacy surface, deletion initiation, data disclosure checklist, notification consent.
- Apple App Store Review Guideline 5.1, ATT, account deletion, and privacy manifests: in-app privacy access, no tracking, privacy manifest, deletion initiation.
- LGPD, PIPEDA/CPPA, APPI, PIPL/PIPL-like regimes, PDPA-style regimes: transparency, rights request channel, data minimization, transfer disclosure, security safeguards.

## App controls implemented

- Added `PrivacyControlsPage` in Settings so privacy policy, access/export, correction/restriction support, account deletion, and children/family notices are available in-app.
- Added client methods for privacy API contracts:
  - `POST /v2/auth/export`
  - `DELETE /v2/auth/me`
  - `DELETE /v2/notifications/devices`
- Added a mailto fallback for rights requests until backend privacy endpoints are deployed.
- Added push-token unregister flow when the global notification toggle is disabled.
- Reduced Sentry user scope to user ID only and removed username, auth-method metadata, and selected player tag context.
- Added `ios/Runner/PrivacyInfo.xcprivacy` with no tracking domains and declared app data categories.

## Store submission checklist

- Publish and link a real privacy policy at `https://clashk.ing/privacy` before release.
- Ensure Google Play Data Safety and Apple Privacy Nutrition Labels match the manifest and backend behavior.
- Deploy backend support for export, deletion, and push unregister endpoints before enabling account creation in production store builds.
- Confirm no ad SDK, ATT tracking, IDFA access, or personalized advertising is added without a separate consent design.
- Keep age rating and store listing language general-audience; do not market the app as child-directed unless Families/Kids rules are fully implemented.
- Document processors/subprocessors: hosting, Firebase Cloud Messaging, Sentry/Better Stack, Discord OAuth, email provider, analytics/observability vendors.
- Define retention windows for auth logs, device tokens, linked Clash of Clans accounts, support requests, crash reports, and backups.
- Add backend audit logs for privacy requests without storing unnecessary request content.
- Verify deletion also removes or anonymizes linked ClashKing app data, notification registrations, local sessions, and server-side linked account records.
