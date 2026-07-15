# Translation audit notes

Generated during the ARB localization audit.

## Mechanical validation

- All `lib/l10n/app_*.arb` files now contain every non-metadata key from `app_en.arb`.
- No locale has extra non-template keys after realigning `app_es.arb`.
- Placeholder validation passes: no missing or extra placeholders versus English values.
- Temporary placeholder markers such as `ZKSPH` / `ЗКСПХ` are absent.
- `flutter gen-l10n` completed successfully.

## Build/analyze note

`flutter analyze` passes after the merge conflict cleanup and Liquid Glass compatibility fixes. No analyzer error observed was caused by ARB parsing or generated localization output.

## Linguistic review queue

The file `docs/translation_audit_doubts.json` lists values that are still identical to English in non-English locales. Some are intentional product names or acronyms, but many locales were clearly using English fallback copy before this audit. These entries should be reviewed by native speakers or by an approved translation workflow.

| Locale | Identical-to-English candidates |
|---|---:|
| `af` | 736 |
| `ar` | 886 |
| `ca` | 934 |
| `cs` | 560 |
| `da` | 560 |
| `de` | 273 |
| `el` | 784 |
| `es` | 720 |
| `es_ES` | 720 |
| `fi` | 596 |
| `fr` | 75 |
| `he` | 929 |
| `hi` | 662 |
| `hu` | 746 |
| `it` | 584 |
| `ja` | 928 |
| `ko` | 928 |
| `nl` | 194 |
| `no` | 904 |
| `pl` | 404 |
| `pt` | 607 |
| `ro` | 945 |
| `ru` | 822 |
| `sr` | 933 |
| `sv` | 970 |
| `tr` | 287 |
| `uk` | 698 |
| `ur` | 628 |
| `vi` | 964 |
| `zh` | 688 |

## Terms intentionally kept or cautiously preserved

- `CWL`, `TH`, `BH`, `XP`: Clash of Clans/common app acronyms; preserved when natural for the locale.
- `Discord`, `Google`, `Supercell`, `Excel (.xlsx)`: product names/formats.
- `endpoint`, `Live Activity`: preserved where already used as platform/product terminology or where localization would be risky without native review.
