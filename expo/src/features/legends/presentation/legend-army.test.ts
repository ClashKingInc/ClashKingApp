import {
  isLegendSiege,
  legendArmyGroups,
  legendHeroLoadouts,
  popularLegendItems,
} from './legend-army';
import {
  PlayerBattlelogArmyCatalog,
  PlayerBattlelogArmyItem,
} from '../../player/models/player-battlelog';
import { currentLegendDay, PlayerLegendBattle } from '../../player/models/player-legend';

test('keeps heroes, pets and equipment with the hero section and separates Clan Castle', () => {
  const groups = Object.fromEntries(legendArmyGroups('h0p1e2_3i2x4d1x2u8x5s2x1'));
  expect(groups.Heroes).toEqual([
    { code: 'h_0', count: 1 },
    { code: 'p_1', count: 1 },
    { code: 'e_2', count: 1 },
    { code: 'e_3', count: 1 },
  ]);
  expect(groups['Clan Castle']).toHaveLength(2);
});

test('shows a siege encoded in both the main army and Clan Castle only once at the larger count', () => {
  const spy = jest
    .spyOn(PlayerBattlelogArmyCatalog, 'resolve')
    .mockImplementation(
      (code) => new PlayerBattlelogArmyItem(code, code, '', 1, code.endsWith('_3')),
    );

  expect(Object.fromEntries(legendArmyGroups('u1x3i2x3')).Siege).toEqual([
    { code: 'u_3', count: 2 },
  ]);
  spy.mockRestore();
});

test('recognizes real Workshop siege IDs when the bundle-first catalog item has no normalized type', () => {
  expect(isLegendSiege('u_4000051', false)).toBe(true);
  expect(isLegendSiege('i_4000188', false)).toBe(true);
  expect(isLegendSiege('u_4000061', false)).toBe(false);
});

test('normalizes full and short Workshop IDs into one siege outside the troop group', () => {
  const groups = Object.fromEntries(legendArmyGroups('u1x4000051-8x1i2x51'));
  expect(groups.Siege).toEqual([{ code: 'u_51', count: 2 }]);
  expect(groups.Troops).toEqual([{ code: 'u_1', count: 8 }]);
  expect(
    popularLegendItems(['u1x4000051i1x51']).find((item) => item.category === 'Siege'),
  ).toMatchObject({ item: { code: 'u_51' }, score: 1 });
});

test('models four hero portraits with one pet and at most two equipment items each', () => {
  expect(legendHeroLoadouts('h0p1e2_3-1p4e5_6-2p7e8_9-3p10e11_12')).toEqual([
    {
      hero: { code: 'h_0', count: 1 },
      pet: { code: 'p_1', count: 1 },
      equipment: [
        { code: 'e_2', count: 1 },
        { code: 'e_3', count: 1 },
      ],
    },
    {
      hero: { code: 'h_1', count: 1 },
      pet: { code: 'p_4', count: 1 },
      equipment: [
        { code: 'e_5', count: 1 },
        { code: 'e_6', count: 1 },
      ],
    },
    {
      hero: { code: 'h_2', count: 1 },
      pet: { code: 'p_7', count: 1 },
      equipment: [
        { code: 'e_8', count: 1 },
        { code: 'e_9', count: 1 },
      ],
    },
    {
      hero: { code: 'h_3', count: 1 },
      pet: { code: 'p_10', count: 1 },
      equipment: [
        { code: 'e_11', count: 1 },
        { code: 'e_12', count: 1 },
      ],
    },
  ]);
});

test('weights popular troops by housing space and excludes Clan Castle troops', () => {
  const spy = jest
    .spyOn(PlayerBattlelogArmyCatalog, 'resolve')
    .mockImplementation(
      (code) =>
        new PlayerBattlelogArmyItem(code, code, '', code === 'u_2' ? 30 : 1, code.endsWith('_3')),
    );
  expect(popularLegendItems(['u20x1-1x2-1x3s2x1i99x1']).map((v) => v.item.code)).toEqual([
    'u_2',
    's_1',
    'u_3',
  ]);
  spy.mockRestore();
});

test('normalizes Clan Castle siege with the matching selected siege and counts it once per army', () => {
  const spy = jest
    .spyOn(PlayerBattlelogArmyCatalog, 'resolve')
    .mockImplementation(
      (code) => new PlayerBattlelogArmyItem(code, code, '', 1, code.endsWith('_3')),
    );
  const result = popularLegendItems(['u1x3i1x3', 'i1x3']);
  expect(result.find((value) => value.category === 'Siege')).toMatchObject({
    item: { code: 'u_3' },
    score: 2,
  });
  spy.mockRestore();
});

test('uses the API Legend-day boundary and preserves known armies on unnamed automatic records', () => {
  expect(currentLegendDay(new Date('2026-09-21T05:09:59Z'))).toBe('2026-09-20');
  expect(currentLegendDay(new Date('2026-09-21T05:10:00Z'))).toBe('2026-09-21');
  expect(
    PlayerLegendBattle.fromJson({ automatic: true, trophies: -30, shareCode: 'u1x1' }).shareCode,
  ).toBe('u1x1');
});
