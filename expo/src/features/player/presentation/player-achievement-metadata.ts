import { gameDataState, isRecord, type JsonRecord } from '../../../core/game-data/game-data-state';
import { localizedNameForItem } from '../../../core/game-data/game-data-localization';
import type { PlayerAchievement } from '../models/player-support';

export type AchievementTier = {
  readonly level: number;
  readonly target: number;
  readonly action: string | null;
  readonly gems: number | null;
};

export type AchievementMetadata = {
  readonly raw: JsonRecord;
  readonly village: string;
  readonly tiers: readonly AchievementTier[];
};

const nameKey = (name: string) => name.normalize('NFKC').replace(/[‘’]/g, "'").trim().toLowerCase();

function collection(value: unknown): readonly JsonRecord[] {
  const items = Array.isArray(value) ? value : isRecord(value) ? value.items : [];
  return Array.isArray(items) ? items.filter(isRecord) : [];
}

/** Only enrich live player progress with the loaded authoritative bundle.
 * Missing or older metadata must not fabricate targets, rewards or tiers. */
export function achievementMetadata(item: PlayerAchievement): AchievementMetadata | null {
  const raw = collection(gameDataState.bundleData.achievements).find(
    (entry) => typeof entry.name === 'string' && nameKey(entry.name) === nameKey(item.name),
  );
  if (!raw) return null;
  return metadataFromEntry(raw, item.village);
}

function metadataFromEntry(raw: JsonRecord, fallbackVillage: string): AchievementMetadata {
  const tiers = collection(raw.levels)
    .flatMap((tier): AchievementTier[] => {
      const level = tier.level;
      const target = tier.action_count;
      if (
        typeof level !== 'number' ||
        !Number.isInteger(level) ||
        level < 1 ||
        typeof target !== 'number' ||
        !Number.isFinite(target) ||
        target < 0
      )
        return [];
      return [
        {
          level,
          target,
          action: typeof tier.action_data === 'string' ? tier.action_data : null,
          gems:
            typeof tier.gems === 'number' && Number.isFinite(tier.gems) && tier.gems >= 0
              ? tier.gems
              : null,
        },
      ];
    })
    .sort((a, b) => a.level - b.level);
  return {
    raw,
    village: typeof raw.village === 'string' ? raw.village : fallbackVillage,
    tiers: tiers.filter((tier, index) => index === 0 || tier.level !== tiers[index - 1]?.level),
  };
}

/** Sum each API achievement's unique catalog tiers once, including account
 * protection. Missing metadata or rewards make the corresponding total unknown,
 * because a partial sum must not appear complete. Stars establish earned tiers. */
export function achievementGemTotals(items: readonly PlayerAchievement[]) {
  const groups = new Map<string, PlayerAchievement[]>();
  for (const item of items) {
    const key = nameKey(item.name);
    const group = groups.get(key) ?? [];
    group.push(item);
    groups.set(key, group);
  }
  let earnedKnown = items.length > 0;
  let possibleKnown = items.length > 0;
  let earned = 0;
  let possible = 0;
  for (const group of groups.values()) {
    const first = group[0]!;
    const metadata = achievementMetadata(first);
    if (!metadata) {
      earnedKnown = possibleKnown = false;
      continue;
    }
    const rawTiers = collection(metadata.raw.levels);
    const levels = new Set(rawTiers.map((tier) => tier.level));
    if (!rawTiers.length || levels.size !== metadata.tiers.length) {
      earnedKnown = possibleKnown = false;
    }
    // Repeated levels are safe to collapse only when their rewards agree.
    for (const tier of metadata.tiers) {
      if (rawTiers.some((raw) => raw.level === tier.level && raw.gems !== tier.gems)) {
        earnedKnown = possibleKnown = false;
      }
    }
    const stars = achievementStarCount(first, metadata).earned;
    // The API can repeat an achievement. Count matching records once; if their
    // earned tiers disagree, the earned total cannot be determined safely.
    if (group.some((item) => achievementStarCount(item, metadata).earned !== stars)) {
      earnedKnown = false;
    }
    for (const tier of metadata.tiers) {
      if (tier.gems === null) {
        possibleKnown = false;
        if (tier.level <= stars) earnedKnown = false;
        continue;
      }
      possible += tier.gems;
      if (tier.level <= stars) earned += tier.gems;
    }
  }
  return { earned: earnedKnown ? earned : null, possible: possibleKnown ? possible : null };
}

export function achievementStarCount(
  item: PlayerAchievement,
  metadata: AchievementMetadata | null,
) {
  const maximum = metadata?.tiers.length || 3;
  // These campaign bosses have one static tier even though older API records
  // use three-star conventions. Preserve their earned status without inventing tiers.
  const singleBoss = item.name === 'Dragon Slayer' || item.name === 'Ungrateful Child';
  const completed =
    (singleBoss && item.value >= 1) ||
    (item.target > 0 && item.value >= item.target && item.stars >= maximum);
  return {
    maximum,
    earned: completed ? maximum : Math.max(0, Math.min(maximum, item.stars)),
    completed,
  };
}

export function achievementTierTarget(
  tier: AchievementTier,
  metadata: AchievementMetadata,
  locale: string,
): string {
  const namedUnlock = metadata.tiers.every((item) => item.target === 1 && item.action);
  if (!namedUnlock || !tier.action) return new Intl.NumberFormat(locale).format(tier.target);
  const name = tier.action.replace(/^BB /, '');
  for (const key of ['buildings', 'troops', 'heroes', 'spells']) {
    const raw = collection(gameDataState.bundleData[key]).find(
      (entry) => typeof entry.name === 'string' && nameKey(entry.name) === nameKey(name),
    );
    if (raw) return localizedNameForItem(raw);
  }
  return name;
}
