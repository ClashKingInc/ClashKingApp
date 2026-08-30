import { ClanWarLog, type WarLogDetails } from '../models';
import { filterClanWarLogItems } from './clan-activity-tabs';

const end = (day: number) => new Date(`2026-08-${String(day).padStart(2, '0')}T00:00:00Z`);
const item = (
  day: number,
  teamSize: number,
  clanStars: number,
  clanDestruction: number,
  opponentStars: number,
  opponentDestruction: number,
) =>
  ({
    endTime: end(day),
    teamSize,
    result: '',
    clanTag: '#OURS',
    clan: {
      tag: '#OURS',
      name: `Ours ${day}`,
      stars: clanStars,
      destructionPercentage: clanDestruction,
    },
    opponent: {
      tag: `#THEM${day}`,
      name: `Opponent ${day}`,
      stars: opponentStars,
      destructionPercentage: opponentDestruction,
    },
  }) as WarLogDetails;

const log = new ClanWarLog(
  [item(30, 15, 45, 100, 45, 100), item(29, 30, 80, 90, 79, 95), item(28, 10, 20, 80, 21, 70)],
  '#OURS',
  [
    { endTime: end(30), warType: 'random' },
    { endTime: end(29), warType: 'cwl' },
    { endTime: end(28), warType: 'friendly' },
  ] as never,
);

test('war-log filters match Flutter result, perfect-war, team-size, type, search, and ordering semantics', () => {
  const allTypes = { cwl: true, random: true, friendly: true };
  expect(filterClanWarLogItems(log, '#OURS', allTypes, '', 'perfectWar')).toEqual([log.items[0]]);
  expect(filterClanWarLogItems(log, '#OURS', allTypes, '', 'victory')).toEqual([log.items[1]]);
  expect(filterClanWarLogItems(log, '#OURS', allTypes, '', 'defeat')).toEqual([log.items[2]]);
  expect(filterClanWarLogItems(log, '#OURS', allTypes, '', '15')).toEqual([log.items[0]]);
  expect(filterClanWarLogItems(log, '#OURS', { ...allTypes, random: false }, '', 'newest')).toEqual(
    [log.items[1], log.items[2]],
  );
  expect(filterClanWarLogItems(log, '#OURS', allTypes, 'ours 28', 'newest')).toEqual([
    log.items[2],
  ]);
  expect(filterClanWarLogItems(log, '#OURS', allTypes, '', 'oldest')).toEqual([
    log.items[2],
    log.items[1],
    log.items[0],
  ]);
});
