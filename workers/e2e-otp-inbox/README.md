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
