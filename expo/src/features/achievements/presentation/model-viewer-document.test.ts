import type { Achievement } from '../models';
import { buildAchievementModelDocument, MODEL_VIEWER_SCRIPT } from './model-viewer-document';

const locked: Achievement = {
  id: 'war_warrior',
  modelUrl: 'https://assets.example/badge.glb',
  earnedCount: 0,
  isRepeatable: true,
};

test('builds the inert locked tile viewer with Flutter camera and lighting values', () => {
  const document = buildAchievementModelDocument('data:model/gltf-binary;base64,AQID', {
    achievement: locked,
    semanticLabel: 'War Warrior',
    interactive: false,
    enableIdleRotation: false,
  });
  expect(document).toContain(`src="${MODEL_VIEWER_SCRIPT}"`);
  expect(document).toContain('loading="lazy"');
  expect(document).toContain('camera-orbit="0deg 75deg 105%"');
  expect(document).toContain('field-of-view="32deg"');
  expect(document).toContain('environment-image="neutral"');
  expect(document).toContain('shadow-intensity="0.7"');
  expect(document).toContain('shadow-softness="0.9"');
  expect(document).toContain('filter:grayscale(1) saturate(0) opacity(0.44)');
  expect(document).not.toContain('camera-controls');
  expect(document).not.toContain('auto-rotate');
});

test('locks detail movement to horizontal orbit and enables delayed idle rotation', () => {
  const document = buildAchievementModelDocument('https://assets.example/badge.glb', {
    achievement: { ...locked, earnedCount: 2 },
    semanticLabel: 'War "Warrior"',
    interactive: true,
    enableIdleRotation: true,
  });
  expect(document).toContain('loading="eager"');
  expect(document).toContain('camera-controls');
  expect(document).toContain('disable-pan');
  expect(document).toContain('disable-zoom');
  expect(document).toContain('min-camera-orbit="auto 75deg 105%"');
  expect(document).toContain('max-camera-orbit="auto 75deg 105%"');
  expect(document).toContain('interpolation-decay="200"');
  expect(document).toContain('auto-rotate-delay="3000"');
  expect(document).toContain('rotation-per-second="18deg"');
  expect(document).toContain('alt="War &quot;Warrior&quot;"');
  expect(document).not.toContain('filter:grayscale');
});

test('omits idle rotation when reduced motion is active', () => {
  const document = buildAchievementModelDocument(locked.modelUrl, {
    achievement: locked,
    semanticLabel: 'War Warrior',
    interactive: true,
    enableIdleRotation: false,
  });
  expect(document).toContain('camera-controls');
  expect(document).not.toContain('auto-rotate');
});
