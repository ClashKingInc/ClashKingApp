# Translation audit notes

Updated after the complete ARB localization audit.

## Mechanical validation

- All 33 `lib/l10n/app_*.arb` files parse as JSON and match every message and metadata key in `app_en.arb`.
- Every locale contains all 1,783 source messages, with no extra legacy keys.
- ICU generation and placeholder validation pass for every locale.
- `flutter gen-l10n` completes successfully and `untranslated_messages.json` is empty.
- Temporary translation markers and helper artifacts are absent.
- `flutter analyze` completes with no issues.

## Reviewed same-as-English values

`docs/translation_audit_doubts.json` records the remaining values that are byte-for-byte identical to English. They were reviewed during this pass and are product names, acronyms, numeric formats, established game terms, or genuine cognates; the file remains available for future native-speaker review.

| Locale | Reviewed identical values |
|---|---:|
| `af` | 17 |
| `ar` | 11 |
| `ca` | 26 |
| `cs` | 20 |
| `da` | 19 |
| `de` | 13 |
| `el` | 14 |
| `es` | 22 |
| `es_ES` | 22 |
| `fi` | 13 |
| `fr` | 18 |
| `he` | 19 |
| `hi` | 12 |
| `hu` | 14 |
| `it` | 25 |
| `ja` | 20 |
| `ko` | 17 |
| `nl` | 14 |
| `no` | 13 |
| `pl` | 18 |
| `pt` | 22 |
| `ro` | 19 |
| `ru` | 10 |
| `sr` | 17 |
| `sv` | 20 |
| `tr` | 8 |
| `uk` | 15 |
| `ur` | 8 |
| `vi` | 20 |
| `zh` | 9 |

## Terms intentionally preserved

- `CWL`, `TH`, `DPS`, `HP`, and `XP` remain where they are the established game or app abbreviations.
- `ClashKing`, `Discord`, `Google`, `Supercell`, and `Excel (.xlsx)` remain product names and formats.
- Genuine cognates and established loanwords remain unchanged where the localized spelling is naturally identical, including French `Village`, Spanish `Error`, German `Gold`, and Italian `Password`.
