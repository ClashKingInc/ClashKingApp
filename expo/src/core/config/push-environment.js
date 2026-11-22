/**
 * Keep the delivery audience tied to both the release environment and endpoint.
 * Production releases explicitly set their canonical URL; an override alone
 * must never classify those installations as test devices.
 * @param {'production'|'development'|'local'} environment
 * @param {string|undefined} pushApiV2BaseUrlOverride
 * @returns {'production'|'sandbox'}
 */
export function pushEnvironment(environment, pushApiV2BaseUrlOverride) {
  if (environment !== 'production') return 'sandbox';
  const override = pushApiV2BaseUrlOverride?.trim();
  if (!override) return 'production';
  try {
    const url = new URL(override);
    return url.origin === 'https://api.clashk.ing' &&
      url.pathname.replace(/\/+$/, '') === '/v2' &&
      !url.username &&
      !url.password &&
      !url.search &&
      !url.hash
      ? 'production'
      : 'sandbox';
  } catch {
    return 'sandbox';
  }
}
