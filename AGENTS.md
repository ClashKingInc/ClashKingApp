# ClashKing App agent guidance

## Native application boundary

The product UI runs on iOS and Android. Browser URLs serve only the small app-opening landing page, association files, and OAuth callbacks. Do not add browser UI parity or use browser product tests to validate native screens. The landing page derives supported routes from the native route manifest; do not maintain a separate route list or forward authentication parameters to app links.

Keep durable setup and maintenance guidance in the existing READMEs. Do not add one-off implementation reports or artwork-generation diaries to the repository. Preserve actual third-party license files.

## Localization pre-commit gate

Before committing any app change, inspect every supported `expo/src/i18n/arb/*.arb` file rather than checking only the template locale or relying on runtime fallback.

- Every user-facing ARB key added or changed by the task must have a real translation in every supported locale. Treat missing task keys as unfinished work unless the user explicitly accepts fallback before the commit.
- Preserve ICU syntax, placeholders, plural/select branches, escaping, and `@key` metadata. Placeholder names and types must match the template locale exactly.
- Run `npm run l10n:generate` from `expo/`, then run `npm run l10n:check`. No key added or changed by the task may remain untranslated, and tracked generated localization output must be current.
- Review the final diff for hard-coded user-facing copy and English text accidentally copied into non-English locale files. Do not claim localization is complete when only a subset of locales was updated.
- If unrelated pre-existing translation gaps prevent a clean global report, complete every task-owned translation and report the existing gaps before committing rather than silently expanding the task.

## Pull request completion loop

When asked to publish or finish a pull request, continue until the requested PR is review-clean and its required checks have completed successfully.

1. Before each commit, run the localization gate above and the focused formatting, analysis, and tests appropriate to the changed files.
2. Commit only task-owned files, preserve unrelated dirty work, use the user's requested Git identity, and push to the existing dedicated branch.
3. Read all current PR review threads with thread-resolution context. Address every unresolved actionable Codex review finding, add regression coverage, and push the fixes.
4. Monitor GitHub Actions after each push. Investigate and fix task-related failures, then repeat validation and push again.
5. Re-check for new Codex reviews and CI results after the latest commit. Do not call the PR complete while actionable review threads, pending required checks, or failing Actions remain.
6. Do not resolve or reply to review threads unless the user has authorized those GitHub writes. Report unrelated infrastructure failures or pre-existing quality issues explicitly instead of changing unrelated code.
