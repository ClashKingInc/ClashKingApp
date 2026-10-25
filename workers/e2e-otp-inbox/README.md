# ClashKing E2E OTP inbox

This Cloudflare Email Worker receives messages addressed to
`e2e+<unique-id>@e2e-mail.clashk.ing`, extracts a six-digit OTP, and stores it in
a recipient-scoped Durable Object for ten minutes. Playwright reads and consumes
the code through the bearer-protected `/v1/otp` endpoint.

The Cloudflare route is deliberately narrow:

- Email Routing DNS is enabled only for `e2e-mail.clashk.ing`.
- A literal `e2e@e2e-mail.clashk.ing` rule targets this Worker.
- Cloudflare plus-address matching maps unique test addresses to that rule.
- The zone catch-all remains disabled and the apex `clashk.ing` MX remains on
  Purelymail.

`OTP_API_TOKEN` is a required Worker secret and must match the GitHub Actions
secret `E2E_OTP_API_TOKEN`. Run `npm run check` before deploying with
`npm run deploy`; rerun `npm run types` whenever bindings change.

## Dependency maintenance

Miniflare currently pins an older Undici release. The scoped package override
keeps local worker tooling on Undici 7.30.1 for its HTTP security fixes. Remove
the override when Miniflare itself requires that version or newer; verify the
local email-to-OTP flow when changing it. PostalMime 4 retains the static
`PostalMime.parse` API used by the worker.

For a local end-to-end check, start `npx wrangler dev --local --ip 127.0.0.1
--port 8797 --var OTP_API_TOKEN:local-dependency-check`, then run
`npm run check:local`. The check sends a synthetic email through the actual
local worker, reads the parsed code, checks recipient isolation, and deletes
the local record. It refuses non-local URLs.
