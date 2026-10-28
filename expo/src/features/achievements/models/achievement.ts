import { ASSET_ORIGIN } from '../../../core/assets/asset-origin';
export const ACHIEVEMENT_IDS = [
  'townhall_18',
  'war_warrior',
  'mr_legend',
  'defense_doesnt_matter',
  'verified_accounts',
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
    id: 'verified_accounts',
    modelUrl: 'derived:verified_accounts',
    earnedCount: 0,
    isRepeatable: false,
  },
  {
    id: 'townhall_18',
    modelUrl: `${ASSET_ORIGIN}/achievements/town-hall-18-achievement-badge.glb`,
    earnedCount: 0,
    isRepeatable: true,
  },
  {
    id: 'war_warrior',
    modelUrl: `${ASSET_ORIGIN}/achievements/war-champion-achievement-badge.glb`,
    earnedCount: 0,
    isRepeatable: true,
  },
  {
    id: 'mr_legend',
    modelUrl: `${ASSET_ORIGIN}/achievements/perfect-legends-day-achievement-badge.glb`,
    earnedCount: 0,
    isRepeatable: true,
  },
  {
    id: 'defense_doesnt_matter',
    modelUrl: `${ASSET_ORIGIN}/achievements/bad-legends-achievement-badge.glb`,
    earnedCount: 0,
    isRepeatable: true,
  },
]);
