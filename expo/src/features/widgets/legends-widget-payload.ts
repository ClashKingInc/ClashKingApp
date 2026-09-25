import { ImageAssets } from '../../core/assets/image-assets';
import type { MessageKey } from '../../i18n';
import type { Player } from '../player/models';
import {
  currentLegendDay,
  type PlayerLegendBattle,
  type PlayerLegendLeagueData,
} from '../player/models/player-legend';

export const LEGENDS_WIDGET_SCHEMA_VERSION = 1;

export type LegendsWidgetTranslate = (
  key: MessageKey,
  values?: Record<string, string | number>,
) => string;

export interface LegendsWidgetLabels {
  readonly title: string;
  readonly attacks: string;
  readonly defenses: string;
  readonly globalRank: string;
  readonly latestAttack: string;
  readonly latestDefense: string;
  readonly noData: string;
  readonly staleData: string;
  readonly updated: string;
  readonly dayFormatted?: string;
}

export interface LegendsWidgetArtwork {
  readonly attackIconUrl: string;
  readonly defenseIconUrl: string;
  readonly trophyIconUrl: string;
  readonly starFilledIconUrl: string;
  readonly starEmptyIconUrl: string;
}

export interface LegendsWidgetBattlePayload {
  readonly trophies: number;
  readonly battleTime: string;
  readonly opponentName?: string;
  readonly opponentTownHallLevel?: number;
  readonly stars?: number;
  readonly destructionPercentage?: number;
}

export interface LegendsWidgetPayload {
  readonly schemaVersion: 1;
  readonly tag: string;
  readonly name: string;
  readonly townHallLevel: number;
  readonly townHallImageUrl: string;
  readonly updatedAt: string;
  readonly legendDay: string;
  readonly legendDayIndex?: number;
  readonly dayStartsAt: string;
  readonly dayEndsAt: string;
  readonly trophies?: number;
  readonly globalRank?: number;
  readonly attackTrophies?: number;
  readonly defenseTrophies?: number;
  readonly netTrophies?: number;
  readonly attacksUsed?: number;
  readonly defensesTaken?: number;
  readonly latestAttack?: LegendsWidgetBattlePayload;
  readonly latestDefense?: LegendsWidgetBattlePayload;
  readonly clan?: { readonly tag: string; readonly name: string; readonly badgeUrl: string };
  readonly artwork?: LegendsWidgetArtwork;
  readonly labels: LegendsWidgetLabels;
}

export interface LegendsWidgetPlayer
  extends Pick<Player, 'tag' | 'name' | 'townHallLevel'> {
  readonly clanOverview?: Player['clanOverview'];
}

export function legendsWidgetLabels(
  t: LegendsWidgetTranslate,
  dayIndex?: number,
): LegendsWidgetLabels {
  return {
    title: t('legendsTitle'),
    attacks: t('rankedLeagueAttacks'),
    defenses: t('rankedLeagueDefenses'),
    globalRank: t('legendsGlobalRankTitle'),
    latestAttack: t('rankedLeagueAttacks'),
    latestDefense: t('rankedLeagueDefenses'),
    noData: t('generalNoDataAvailable'),
    staleData: t('widgetDataStale'),
    updated: t('upgradeTrackerHeaderUpdated'),
    ...(dayIndex === undefined
      ? undefined
      : { dayFormatted: t('statsDayIndex', { index: dayIndex }) }),
  };
}

export function buildLegendsWidgetPayload(
  player: LegendsWidgetPlayer,
  data: PlayerLegendLeagueData,
  t: LegendsWidgetTranslate,
  now = new Date(),
): LegendsWidgetPayload {
  const legendDay = currentLegendDay(now);
  const start = new Date(`${legendDay}T05:10:00.000Z`);
  const end = new Date(start.getTime() + 86_400_000);
  const day = data.currentDay?.day === legendDay ? data.currentDay : null;
  const rank = data.currentRank;
  const dayIndex = legendDayIndex(data.seasonStart, legendDay);
  const defenseTrophies = day
    ? day.defenseTrophies > 0 ? -day.defenseTrophies : day.defenseTrophies
    : undefined;
  const clan = player.clanOverview?.tag
    ? {
        tag: player.clanOverview.tag,
        name: player.clanOverview.name,
        badgeUrl:
          player.clanOverview.badgeUrls.medium ||
          ImageAssets.clanBadgeForTag(player.clanOverview.tag),
      }
    : undefined;
  return {
    schemaVersion: LEGENDS_WIDGET_SCHEMA_VERSION,
    tag: canonicalPlayerTag(player.tag),
    name: player.name,
    townHallLevel: player.townHallLevel,
    townHallImageUrl: ImageAssets.townHall(player.townHallLevel),
    updatedAt: now.toISOString(),
    legendDay,
    ...(dayIndex === undefined ? undefined : { legendDayIndex: dayIndex }),
    dayStartsAt: start.toISOString(),
    dayEndsAt: end.toISOString(),
    ...(rank && rank.trophies > 0 ? { trophies: rank.trophies } : undefined),
    ...(rank && rank.globalRank > 0 ? { globalRank: rank.globalRank } : undefined),
    ...(day
      ? {
          attackTrophies: day.attackTrophies,
          defenseTrophies,
          netTrophies: day.attackTrophies + (defenseTrophies ?? 0),
          attacksUsed: day.attacks.length,
          defensesTaken: day.defenses.length,
          ...optionalBattle('latestAttack', latestTimedBattle(day.attacks)),
          ...optionalBattle('latestDefense', latestTimedBattle(day.defenses)),
        }
      : undefined),
    ...(clan ? { clan } : undefined),
    artwork: {
      attackIconUrl: ImageAssets.sword,
      defenseIconUrl: ImageAssets.shieldWithArrow,
      trophyIconUrl: ImageAssets.trophies,
      starFilledIconUrl: ImageAssets.attackStar,
      starEmptyIconUrl: ImageAssets.emptyStar,
    },
    labels: legendsWidgetLabels(t, dayIndex),
  };
}

export function canonicalPlayerTag(tag: string): string {
  const normalized = tag.trim().replaceAll('#', '').toUpperCase();
  return normalized ? `#${normalized}` : '';
}

function legendDayIndex(seasonStart: string | null, day: string): number | undefined {
  const startDay = seasonStart?.slice(0, 10);
  if (!startDay || !/^\d{4}-\d{2}-\d{2}$/.test(startDay)) return undefined;
  const start = Date.parse(`${startDay}T00:00:00.000Z`);
  const current = Date.parse(`${day}T00:00:00.000Z`);
  if (!Number.isFinite(start) || !Number.isFinite(current) || current < start) return undefined;
  return Math.floor((current - start) / 86_400_000) + 1;
}

function latestTimedBattle(battles: readonly PlayerLegendBattle[]) {
  return battles.reduce<PlayerLegendBattle | null>((latest, battle) => {
    if (!battle.battleTime) return latest;
    if (!latest?.battleTime || battle.battleTime > latest.battleTime) return battle;
    return latest;
  }, null);
}

function optionalBattle<Key extends 'latestAttack' | 'latestDefense'>(
  key: Key,
  battle: PlayerLegendBattle | null,
): Partial<Record<Key, LegendsWidgetBattlePayload>> {
  if (!battle?.battleTime) return {};
  return {
    [key]: {
      trophies: battle.trophies,
      battleTime: battle.battleTime.toISOString(),
      ...(battle.opponentName ? { opponentName: battle.opponentName } : undefined),
      ...(battle.opponentTownHallLevel > 0
        ? { opponentTownHallLevel: battle.opponentTownHallLevel }
        : undefined),
      ...(battle.stars === null ? undefined : { stars: battle.stars }),
      ...(battle.destructionPercentage === null
        ? undefined
        : { destructionPercentage: battle.destructionPercentage }),
    },
  } as Partial<Record<Key, LegendsWidgetBattlePayload>>;
}
