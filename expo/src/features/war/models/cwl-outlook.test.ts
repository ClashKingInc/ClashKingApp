import { CwlLeague, WarCwl, WarInfo } from './index';
import { cwlOutlook, cwlStandings, remainingCwlOpponents } from './cwl-outlook';
function war(left: string, right: string, stars: number, otherStars: number, state = 'warEnded') {
  return WarInfo.fromJson({
    state,
    war_tag: left + right,
    teamSize: 15,
    warType: 'cwl',
    clan: {
      tag: left,
      stars,
      destructionPercentage: stars * 2,
      attacks: state === 'preparation' ? 0 : 15,
    },
    opponent: {
      tag: right,
      stars: otherStars,
      destructionPercentage: otherStars * 2,
      attacks: state === 'preparation' ? 0 : 15,
    },
  });
}
function season(wars: WarInfo[], tags = ['#A', '#B', '#C', '#D']) {
  const group = CwlLeague.fromJson({
    season: '2026-09',
    clans: tags.map((tag) => ({ tag, name: tag })),
    rounds: [],
  });
  return new WarCwl('#A', false, true, new WarInfo('notInWar'), group, wars);
}
const completed = [
  war('#A', '#B', 40, 30),
  war('#A', '#C', 42, 29),
  war('#D', '#B', 35, 30),
  war('#D', '#C', 35, 28),
];
it('adds completed win bonuses to clan standings without mutating raw war stars', () => {
  const summary = season([...completed, war('#A', '#D', 10, 12, 'inWar')]);
  const a = cwlStandings(summary).find((row) => row.tag === '#A')!;
  expect(a).toMatchObject({ stars: 112, wins: 2, played: 2, destruction: 184 });
  expect(completed[0]!.clan!.stars).toBe(40);
});
it('does not invent preparation ranks or forecasts with too little history', () => {
  const rows = cwlOutlook(season([war('#A', '#B', 0, 0, 'preparation')]));
  expect(rows.every((row) => row.rank === 0 && row.firstChance === null)).toBe(true);
  expect(cwlOutlook(season([completed[0]!])).every((row) => row.topTwoChance === null)).toBe(true);
});
it('forecasts reproducibly and distributes finite first-place and top-two chances', () => {
  const summary = season(completed);
  const rows = cwlOutlook(summary);
  expect(rows).toEqual(cwlOutlook(summary));
  expect(rows.reduce((sum, row) => sum + row.firstChance!, 0)).toBeCloseTo(1);
  expect(rows.reduce((sum, row) => sum + row.topTwoChance!, 0)).toBeCloseTo(2);
  for (const row of rows) {
    expect(row.firstChance).toBeGreaterThanOrEqual(0);
    expect(row.topTwoChance).toBeLessThanOrEqual(1);
    expect(row.topTwoChance).toBeGreaterThanOrEqual(row.firstChance!);
  }
});
it('holds finished outcomes fixed and splits exact ties fairly', () => {
  const tags = ['#A', '#B', '#C'];
  const summary = season(
    [war('#A', '#B', 30, 30), war('#A', '#C', 30, 30), war('#B', '#C', 30, 30)],
    tags,
  );
  for (const row of cwlOutlook(summary)) {
    expect(row.rank).toBe(1);
    expect(row.firstChance).toBeCloseTo(1 / 3);
    expect(row.topTwoChance).toBeCloseTo(2 / 3);
  }
});
it('includes the current opponent in remaining results, but excludes completed opponents', () => {
  const summary = season([
    war('#A', '#B', 30, 25),
    war('#A', '#C', 3, 2, 'inWar'),
    war('#A', '#D', 0, 0, 'preparation'),
  ]);
  expect(remainingCwlOpponents(summary, '#A').map((clan) => clan.tag)).toEqual(['#C', '#D']);
});
