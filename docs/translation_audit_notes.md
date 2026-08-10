# Translation audit notes

Updated after the complete ARB localization audit.

## Mechanical validation

- All 33 `lib/l10n/app_*.arb` files parse as JSON and match every message and metadata key in `app_en.arb`.
- Every locale contains all 1,785 source messages, with no extra legacy keys.
- ICU generation and placeholder validation pass for every locale.
- `flutter gen-l10n` completes successfully and `untranslated_messages.json` is empty.
- Temporary translation markers and helper artifacts are absent.
- `flutter analyze` completes with no issues.

## Reviewed same-as-English values

`docs/translation_audit_doubts.json` records the remaining values that are byte-for-byte identical to English. They were reviewed during this pass and are product names, acronyms, numeric formats, established game terms, or genuine cognates; the file remains available for future native-speaker review.

| Locale | Reviewed identical values |
|---|---:|
| `af` | 23 |
| `ar` | 11 |
| `ca` | 31 |
| `cs` | 24 |
| `da` | 25 |
| `de` | 16 |
| `el` | 16 |
| `es` | 25 |
| `es_ES` | 25 |
| `fi` | 17 |
| `fr` | 28 |
| `he` | 21 |
| `hi` | 14 |
| `hu` | 18 |
| `it` | 28 |
| `ja` | 22 |
| `ko` | 17 |
| `nl` | 25 |
| `no` | 19 |
| `pl` | 21 |
| `pt` | 27 |
| `ro` | 24 |
| `ru` | 12 |
| `sr` | 19 |
| `sv` | 27 |
| `tr` | 10 |
| `uk` | 18 |
| `ur` | 10 |
| `vi` | 27 |
| `zh` | 12 |

## Terms intentionally preserved

- `CWL`, `TH`, `DPS`, `HP`, and `XP` remain where they are the established game or app abbreviations.
- `ClashKing`, `Discord`, `Google`, `Supercell`, and `Excel (.xlsx)` remain product names and formats.
- Strategy and league names such as `Queen Charge`, `Meta`, and `Top 200` remain unchanged where that is normal usage in the locale.
