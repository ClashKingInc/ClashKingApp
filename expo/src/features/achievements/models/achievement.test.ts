import {
  ACHIEVEMENT_CATALOG_FALLBACK,
  ACHIEVEMENT_IDS,
  isAchievementId,
  isAchievementUnlocked,
} from './achievement';

test('keeps the Flutter catalog order, asset URLs, and locked defaults', () => {
  expect(ACHIEVEMENT_CATALOG_FALLBACK.map((item) => item.id)).toEqual(ACHIEVEMENT_IDS);
  expect(ACHIEVEMENT_CATALOG_FALLBACK.map((item) => item.modelUrl)).toEqual([
    'https://assets.clashk.ing/achievements/town-hall-18-achievement-badge.glb',
    'https://assets.clashk.ing/achievements/war-champion-achievement-badge.glb',
    'https://assets.clashk.ing/achievements/perfect-legends-day-achievement-badge.glb',
    'https://assets.clashk.ing/achievements/bad-legends-achievement-badge.glb',
  ]);
  expect(ACHIEVEMENT_CATALOG_FALLBACK.every((item) => !isAchievementUnlocked(item))).toBe(true);
  expect(ACHIEVEMENT_CATALOG_FALLBACK.every((item) => item.isRepeatable)).toBe(true);
});

test('accepts only the four API identifiers', () => {
  expect(isAchievementId('war_warrior')).toBe(true);
  expect(isAchievementId('warWarrior')).toBe(false);
  expect(isAchievementId('unknown')).toBe(false);
});
