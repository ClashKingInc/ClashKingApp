const { getDefaultConfig } = require('expo/metro-config');
const fs = require('node:fs');
const path = require('node:path');

const config = getDefaultConfig(__dirname);
// SDK 58's Rust worker preserves Babel fallback for transforms it cannot run
// (including worklets). Keep this at the actual Metro transformer boundary.
config.transformer.unstable_noxcturnalTransformWorker = true;
if (!config.resolver.assetExts.includes('glb')) config.resolver.assetExts.push('glb');
// The pinned model-viewer source is read as text inside the local hero scene.
if (!config.resolver.assetExts.includes('txt')) config.resolver.assetExts.push('txt');

config.server.enhanceMiddleware = (middleware) => (request, response, next) => {
  const url = new URL(request.url || '/', 'http://localhost');
  // This middleware exists only in Metro, never in exported production assets.
  // Allowlist the preview files and avoid sharing production catalog cache keys.
  const localRoot = process.env.CLASHKING_LOCAL_ASSETS_ROOT;
  const previewFiles = {
    '/__local-game-assets/equipment.json':
      localRoot && path.join(localRoot, 'static_data/equipment.json'),
    '/__local-game-assets/abilities.json':
      localRoot && path.join(localRoot, 'static_data/abilities.json'),
    '/__local-game-assets/portal_pendant.webp': process.env.CLASHKING_LOCAL_PORTAL_ICON,
  };
  if (Object.hasOwn(previewFiles, url.pathname)) {
    const file = previewFiles[url.pathname];
    if (!file || !fs.existsSync(file)) {
      response.statusCode = 404;
      response.end();
      return;
    }
    response.setHeader('Cache-Control', 'no-store');
    response.setHeader('Content-Type', file.endsWith('.json') ? 'application/json' : 'image/webp');
    fs.createReadStream(file).pipe(response);
    return;
  }
  if (url.pathname === '/auth/callback' || url.pathname === '/auth/callback/') {
    // Expo's static-directory redirect drops the query string, including the
    // OAuth code and state. Serve the same callback file without a redirect;
    // never log this URL because its query contains short-lived credentials.
    request.url = `/auth/callback/index.html${url.search}`;
  }
  return middleware(request, response, next);
};

module.exports = config;
