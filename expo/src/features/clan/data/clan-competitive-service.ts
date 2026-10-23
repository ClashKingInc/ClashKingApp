import {
  expoEndpoints,
  LegendRanksEndpoint,
  LegendHistoricalRanksEndpoint,
} from '@clashking/api-contracts/expo';
import { Effect } from 'effect';
import type { ContractApiService } from '../../../core/api/contract-api';
import { canonicalTag } from '../../../core/domain/tags';
import { isLegendMember, type ClanCompetitiveDay } from '../models/clan-competitive';
import type { ClanMember } from '../models/clan-core';

export async function loadClanCompetitiveDay(
  api: ContractApiService,
  members: readonly ClanMember[],
  selectedDay?: string,
): Promise<ClanCompetitiveDay> {
  // One bounded batch per source, not a request per member. The same UTC
  // 05:10 boundary is used by the Legend battle endpoints and Discord bot.
  const today = new Date(Date.now() - (5 * 60 + 10) * 60_000).toISOString().slice(0, 10);
  const day = selectedDay ?? today;
  if (
    !/^\d{4}-\d{2}-\d{2}$/.test(day) ||
    day > today ||
    new Date(`${day}T00:00:00Z`).toISOString().slice(0, 10) !== day
  )
    throw new Error('Invalid Legend day');
  const legends = members.filter(isLegendMember).sort((a, b) => b.trophies - a.trophies);
  const tags = legends.map((member) => member.tag);
  if (!tags.length) return { day, legends: [] };
  const [ranks, summaries] = await Promise.all([
    day === today
      ? Effect.runPromise(api.execute(LegendRanksEndpoint, { path: {}, query: {}, body: { tags } }))
      : Effect.runPromise(
          api.execute(LegendHistoricalRanksEndpoint, { path: {}, query: {}, body: { day, tags } }),
        ),
    Effect.runPromise(
      api.execute(expoEndpoints.legendDaySummaries, { path: {}, query: {}, body: { day, tags } }),
    ),
  ]);
  const rankByTag = new Map(ranks.items.map((item) => [canonicalTag(item.tag), item]));
  const statsByTag = new Map(summaries.items.map((item) => [canonicalTag(item.tag), item]));
  return {
    day,
    legends: legends.map((member) => ({
      member,
      globalRank: rankByTag.get(canonicalTag(member.tag))?.globalRank,
      // A historical day must never show today's trophy count as its closing value.
      trophies: day === today ? member.trophies : rankByTag.get(canonicalTag(member.tag))?.trophies,
      stats: statsByTag.get(canonicalTag(member.tag)),
    })),
  };
}
