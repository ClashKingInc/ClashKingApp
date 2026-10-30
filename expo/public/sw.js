// Retirement worker for previously installed browser builds. New landing
// pages never register a worker or cache private app screens.
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const keys = await caches.keys();
      await Promise.all(
        keys.filter((key) => key.startsWith('clashking-expo-')).map((key) => caches.delete(key)),
      );
      await self.clients.claim();
      await self.registration.unregister();
      const clients = await self.clients.matchAll({ type: 'window' });
      await Promise.all(
        clients
          .filter((client) => !new URL(client.url).pathname.startsWith('/auth/'))
          .map((client) => client.navigate(client.url)),
      );
    })(),
  );
});
