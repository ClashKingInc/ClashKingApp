export const ACHIEVEMENT_IDS = [
  'townhall_18',
  'war_warrior',
  'mr_legend',
  'defense_doesnt_matter',
] as const;

export type AchievementId = (typeof ACHIEVEMENT_IDS)[number];

export interface Achievement {
  readonly id: AchievementId;
  readonly modelUrl: string;
  readonly earnedCount: number;
  readonly isRepeatable: boolean;
}

export function isAchievementId(value: string): value is AchievementId {
  return (ACHIEVEMENT_IDS as readonly string[]).includes(value);
}

export function isAchievementUnlocked(achievement: Achievement): boolean {
  return achievement.earnedCount > 0;
}

export const ACHIEVEMENT_CATALOG_FALLBACK: readonly Achievement[] = Object.freeze([
  {
    id: 'townhall_18',
    modelUrl: 'https://assets.clashk.ing/achievements/town-hall-18-achievement-badge.glb',
    earnedCount: 0,
    isRepeatable: true,
  },
  {
    id: 'war_warrior',
    modelUrl: 'https://assets.clashk.ing/achievements/war-champion-achievement-badge.glb',
    earnedCount: 0,
    isRepeatable: true,
  },
  {
    id: 'mr_legend',
    modelUrl: 'https://assets.clashk.ing/achievements/perfect-legends-day-achievement-badge.glb',
    earnedCount: 0,
    isRepeatable: true,
  },
  {
    id: 'defense_doesnt_matter',
    modelUrl: 'https://assets.clashk.ing/achievements/bad-legends-achievement-badge.glb',
    earnedCount: 0,
    isRepeatable: true,
  },
]);
