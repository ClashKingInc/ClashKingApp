import { CwlLeague, WarCwl, WarInfo } from '../models';

/** Presentation-only geometry models. Never store or export these as game data. */
export function loadingWar(clanTag: string, name = 'Clan name', badge = ''): WarInfo {
  return WarInfo.fromJson({
    state: 'inWar',
    war_tag: '#LOADING',
    warType: 'cwl',
    teamSize: 15,
    attacksPerMember: 1,
    startTime: '20260101T000000.000Z',
    endTime: '20260102T000000.000Z',
    clan: {
      tag: clanTag,
      name,
      badgeUrls: { small: badge },
      clanLevel: 10,
      attacks: 10,
      stars: 30,
      destructionPercentage: 80,
      members: [0, 1, 2].map((index) => ({
        tag: `#PENDING${index}`,
        name: 'Player name',
        townhallLevel: 16,
        mapPosition: index + 1,
        attacks: [],
      })),
    },
    opponent: {
      tag: '#OPPONENT',
      name: 'Opponent clan',
      clanLevel: 10,
      attacks: 10,
      stars: 30,
      destructionPercentage: 80,
      members: [0, 1, 2].map((index) => ({
        tag: `#PENDING${index}`,
        name: 'Player name',
        townhallLevel: 16,
        mapPosition: index + 1,
        attacks: [],
      })),
    },
  });
}

export function loadingCwl(clanTag: string, season = '2026-01'): WarCwl {
  const war = loadingWar(clanTag);
  const members = [0, 1, 2].map((index) => ({
    tag: `#PENDING${index}`,
    name: 'Player name',
    townHallLevel: 16,
    attacks: { stars: 3, attack_count: 1, total_destruction: 100 },
  }));
  const league = CwlLeague.fromJson({
    state: 'inWar',
    season,
    clans: [clanTag, '#OPPONENT', '#PENDING'].map((tag) => ({
      tag,
      name: 'Clan name',
      members,
      total_stars: 100,
      total_destruction: 100,
      rank: 1,
      wars_played: 1,
    })),
    rounds: [{ warTags: ['#LOADING'] }],
  });
  return new WarCwl(clanTag, true, true, war, league, [war]);
}
