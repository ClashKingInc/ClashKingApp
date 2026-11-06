import { appLinkPath, parseAppLink } from './app-link.js';
import { storeLinks } from './store-links.js';

// Use the native router's parser, not a second list of destinations. Never
// forward OAuth tokens or arbitrary query parameters through a public link.
const source =
  window.location.pathname === '/app-landing.html'
    ? new URLSearchParams(window.location.search).get('destination') || '/'
    : window.location.pathname + window.location.search;
const link = parseAppLink(source);
const path = link ? appLinkPath(link) : '/';
const open = document.getElementById('open-app');
open.href = 'clashking://' + path;
open.addEventListener('click', () => {
  document.getElementById('status').textContent =
    'If nothing opens, check that ClashKing is installed on this device.';
});

if (link && path !== '/') {
  const destination = document.getElementById('destination');
  destination.textContent = 'Your shared page will open directly in the app.';
  destination.hidden = false;
}

for (const [name, id] of [
  ['App Store', 'ios'],
  ['Google Play', 'android'],
]) {
  const href = storeLinks[name];
  if (!href) continue;
  const anchor = document.getElementById('store-' + id);
  anchor.href = href;
  anchor.rel = 'noopener noreferrer';
  anchor.removeAttribute('aria-disabled');
  document.getElementById('store-' + id + '-status').textContent = 'Download the app';
}
// Retire only ClashKing's former offline shell. No new worker is registered.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker
    .getRegistrations()
    .then((registrations) =>
      Promise.all(
        registrations
          .filter((registration) => {
            const worker = registration.active || registration.waiting || registration.installing;
            return worker && new URL(worker.scriptURL).pathname === '/sw.js';
          })
          .map((registration) => registration.unregister()),
      ),
    )
    .catch(() => {});
}
if ('caches' in globalThis) {
  caches
    .keys()
    .then((keys) =>
      Promise.all(
        keys.filter((key) => key.startsWith('clashking-expo-')).map((key) => caches.delete(key)),
      ),
    )
    .catch(() => {});
}
