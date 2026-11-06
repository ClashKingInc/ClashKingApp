import type { GameDataFileStore } from './game-data-service';

const CACHE = 'clashking-game-data-v1';

/** Public static metadata only; never stores user data or authentication tokens. */
export const webGameDataFileStore: GameDataFileStore = {
  async read(fileName) {
    if (typeof caches === 'undefined') return null;
    try {
      const cache = await caches.open(CACHE);
      const response = await cache.match(`/__game-data/${encodeURIComponent(fileName)}`);
      return response ? await response.text() : null;
    } catch {
      return null;
    }
  },
  async write(fileName, contents) {
    if (typeof caches === 'undefined') throw new Error('Cache Storage is unavailable');
    const cache = await caches.open(CACHE);
    await cache.put(
      `/__game-data/${encodeURIComponent(fileName)}`,
      new Response(contents, { headers: { 'Content-Type': 'application/json' } }),
    );
    // Let the service keep its previous committed slot on a failed write.
  },
};
