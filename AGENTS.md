# ClashKing App agent guidance

## Shared local web development

The server exposes local Expo web development at `https://dev-app.clashk.ing` through the Cloudflare Tunnel to `127.0.0.1:7357`. Only one ClashKing App checkout may run at a time because that stable hostname and Discord OAuth callback belong to a single shared development process.

- Manage the process from the repository root with the tracked `tooling/dev-app` command. Do not start a separate Expo server, static server, or second checkout manually.
- `tooling/dev-app start [worktree]` starts the given worktree, or the current worktree when omitted. It refuses to replace a different active worktree.
- `tooling/dev-app use <worktree>` explicitly stops the current app and switches the shared development URL to another worktree.
- `tooling/dev-app reload` requests an Expo reload. Use `tooling/dev-app restart` for a full process restart, and `tooling/dev-app stop`, `tooling/dev-app status`, `tooling/dev-app logs`, or `tooling/dev-app attach` for normal management and inspection.
- The manager owns the named tmux session `clashking-app-dev` and port `7357`, so every chat can inspect and manage the same process.
- Local development uses the production API at `https://api.clashk.ing` with `http://localhost:7357/auth/discord_callback.html` as its Discord redirect. Cloudflare Pages staging uses `https://staging-app.clashk.ing` and its matching callback instead.

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
4. Monitor GitHub Actions and Sonar after each push. Investigate and fix task-related failures or newly introduced Sonar issues, then repeat validation and push again.
5. Re-check for new Codex reviews and CI results after the latest commit. Do not call the PR complete while actionable review threads, pending required checks, failing Actions, or new Sonar issues remain.
6. Do not resolve or reply to review threads unless the user has authorized those GitHub writes. Report unrelated infrastructure failures or pre-existing quality issues explicitly instead of changing unrelated code.
