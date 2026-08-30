import type { MessageKey } from '../../../i18n';
import type { Achievement, AchievementId } from '../models';

export interface AchievementCopyKeys {
  readonly name: MessageKey;
  readonly description: MessageKey;
}

export const ACHIEVEMENT_COPY_KEYS: Readonly<Record<AchievementId, AchievementCopyKeys>> = {
  townhall_18: {
    name: 'achievementTownhall18Name',
    description: 'achievementTownhall18Requirement',
  },
  war_warrior: {
    name: 'achievementWarWarriorName',
    description: 'achievementWarWarriorRequirement',
  },
  mr_legend: {
    name: 'achievementMrLegendName',
    description: 'achievementMrLegendDescription',
  },
  defense_doesnt_matter: {
    name: 'achievementDefenseDoesntMatterName',
    description: 'achievementDefenseDoesntMatterDescription',
  },
};

export interface AchievementModelRequest {
  readonly achievement: Achievement;
  readonly semanticLabel: string;
  readonly interactive: boolean;
  readonly enableIdleRotation: boolean;
}

export function achievementColumnCount(width: number): number {
  if (width < 520) return 2;
  if (width < 760) return 3;
  return 4;
}
