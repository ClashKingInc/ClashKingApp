// The static-export step replaces this token with a content fingerprint. That
// makes each release activate a fresh cache while keeping local public-file
// serving deterministic.
const CACHE_NAME = 'clashking-expo-__CLASHKING_WEB_BUILD__';
const APP_SHELL = [
  '/',
  '/index.html',
  '/favicon.png',
  '/manifest.webmanifest',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
  '/icons/Icon-maskable-192.png',
  '/icons/Icon-maskable-512.png',
];

self.addEventListener('install', (event) => {
  event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL)));
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((keys) =>
        Promise.all(
          keys
            .filter((key) => key.startsWith('clashking-expo-') && key !== CACHE_NAME)
            .map((key) => caches.delete(key)),
        ),
      ),
  );
  self.clients.claim();
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;
  // OAuth callback URLs contain one-time credentials in their query string.
  // Let the browser fetch them directly so neither the request nor response is
  // ever persisted in Cache Storage.
  if (url.pathname.startsWith('/auth/')) return;

  if (request.mode === 'navigate') {
    event.respondWith(
      fetch(request)
        .then(async (response) => {
          if (response.ok) {
            await storeResponse(request, response);
          } else if (response.status >= 500) {
            return (
              (await cachedResponse(request)) ?? (await cachedResponse('/index.html')) ?? response
            );
          }
          return response;
        })
        .catch(
          async () =>
            (await cachedResponse(request)) ??
            (await cachedResponse('/index.html')) ??
            Response.error(),
        ),
    );
    return;
  }

  event.respondWith(
    cachedResponse(request).then(
      (cached) =>
        cached ??
        fetch(request).then(async (response) => {
          if (response.ok) {
            await storeResponse(request, response);
          }
          return response;
        }),
    ),
  );
});

async function cachedResponse(request) {
  try {
    return await (await caches.open(CACHE_NAME)).match(request);
  } catch {
    return undefined;
  }
}

async function storeResponse(request, response) {
  // Private/no-store responses must never enter the offline cache. Cache quota
  // errors must also never turn a successful request into a failed page load.
  if (/no-store|private/i.test(response.headers.get('Cache-Control') || '')) return;
  try {
    const cache = await caches.open(CACHE_NAME);
    await cache.put(request, response.clone());
  } catch {
    /* The network response is still usable when storage is full. */
  }
}
