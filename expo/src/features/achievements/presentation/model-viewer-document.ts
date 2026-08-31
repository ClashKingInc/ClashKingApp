import type { AchievementModelRequest } from './contracts';

// Keep the viewer version pinned so native WebViews and web render the same camera behavior.
export const MODEL_VIEWER_SCRIPT =
  'https://unpkg.com/@google/model-viewer@4.1.0/dist/model-viewer.min.js';

export function buildAchievementModelDocument(
  source: string,
  request: AchievementModelRequest,
): string {
  const { achievement, semanticLabel, interactive, enableIdleRotation } = request;
  const attributes = [
    `src="${escapeAttribute(source)}"`,
    `alt="${escapeAttribute(semanticLabel)}"`,
    `loading="${interactive ? 'eager' : 'lazy'}"`,
    'reveal="auto"',
    'disable-pan',
    'disable-tap',
    'disable-zoom',
    'interaction-prompt="none"',
    'camera-orbit="0deg 75deg 105%"',
    'field-of-view="32deg"',
    'environment-image="neutral"',
    'shadow-intensity="0.7"',
    'shadow-softness="0.9"',
  ];
  if (interactive) {
    attributes.push(
      'camera-controls',
      'min-camera-orbit="auto 75deg 105%"',
      'max-camera-orbit="auto 75deg 105%"',
      'interpolation-decay="200"',
    );
    if (enableIdleRotation) {
      attributes.push('auto-rotate', 'auto-rotate-delay="3000"', 'rotation-per-second="18deg"');
    }
  }
  const lockFilter =
    achievement.earnedCount > 0 ? '' : 'filter:grayscale(1) saturate(0) opacity(0.44);';
  return `<!doctype html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>html,body{width:100%;height:100%;margin:0;overflow:hidden;background:transparent}model-viewer{width:100%;height:100%;--poster-color:transparent;touch-action:none;${lockFilter}}</style>
<script type="module" src="${MODEL_VIEWER_SCRIPT}"></script></head>
<body><model-viewer ${attributes.join(' ')}></model-viewer></body></html>`;
}

function escapeAttribute(value: string): string {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('"', '&quot;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;');
}
