# Legend attack/defense notifications are retired

The user explicitly confirmed retirement. This is no longer a product/backend question: do not restore these notification preferences, settings controls, storage fields, or delivery behavior. General Legend player statistics are a separate retained feature.

## Fresh GitHub main audit

Fetched `https://github.com/ClashKingInc/ClashKingApp.git` branch `main` into the independent repository's `refs/audit/origin-main-20260904`. The audit was verified at **2026-09-04 16:13:38 UTC**:

- Remote commit: `c90a766afb4abf4598cf85979109e8e402f54ce1`.
- Commit time: `2026-09-01T10:22:03-05:00`.
- Commit subject: `feat: remove connected apps management (#236)`.

Yes, that actual remote branch still contains stale Legend notification code:

| Location                                                                                                                                                                                                         | Remaining remote behavior                                                                                        |
| ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| [`notification-preferences.ts:4`](https://github.com/ClashKingInc/ClashKingApp/blob/c90a766afb4abf4598cf85979109e8e402f54ce1/expo/src/core/dto/notification-preferences.ts#L4)                                   | Declares both categories; lines 24–25 add their boolean model fields and 55–56 default them.                     |
| [`notification-preferences.ts:106`](https://github.com/ClashKingInc/ClashKingApp/blob/c90a766afb4abf4598cf85979109e8e402f54ce1/expo/src/core/dto/notification-preferences.ts#L106)                               | Requires `legendAttacksEnabled` and `legendDefensesEnabled` when decoding; lines 130–131 restore local defaults. |
| [`notification-preferences.ts:147`](https://github.com/ClashKingInc/ClashKingApp/blob/c90a766afb4abf4598cf85979109e8e402f54ce1/expo/src/core/dto/notification-preferences.ts#L147)                               | Serializes both retired flags into outgoing preference requests.                                                 |
| [`notification-settings-screen.tsx:59`](https://github.com/ClashKingInc/ClashKingApp/blob/c90a766afb4abf4598cf85979109e8e402f54ce1/expo/src/features/settings/presentation/notification-settings-screen.tsx#L59) | Still defines the attack control; line 65 defines the defense control.                                           |

Remote tests also retain the flags in `expo/src/core/__tests__/foundation.test.mjs:86–87` and `expo/src/features/notifications/data/notification-preferences-service.test.ts:14–15,116–117`. These are source findings, not proof of what is currently deployed or delivered to a device.

## Independent implementation

The saved rewrite already removed those model fields, wire fields, and controls. The current App keeps that removal, adds `notification-retirement.test.ts`, and no longer describes the feature as an open decision. The regressions require absence from defaults, decoded state, PUT/local serialization, the model source, and settings control source while preserving supported war/raid fields.

No notification backend was added. No general Legend statistics or unrelated localization strings were removed. Historical missing API/schema fields and stale Admin reads do not override the user's retirement decision.

Only the isolated audit ref was fetched. The independent working checkout remains on saved snapshot `9d7fd109d8a23e9f0306a3f5c447cfc98eb656f1` with implementation edits; it was not switched, merged, or reset. The original checkout was not edited. Nothing was pushed, deployed, or released, so this local cleanup has not changed GitHub `main`.
