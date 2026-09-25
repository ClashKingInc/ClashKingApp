import { armyDisplayItems } from './army-presentation';

test('maps every structured army component to the existing game-data catalog codes', () => {
  expect(
    armyDisplayItems({
      mainTroops: [{ id: 1, quantity: 12 }],
      clanCastleTroops: [{ id: 2, quantity: 3 }],
      spells: [
        { id: 3, quantity: 2, clanCastle: false },
        { id: 4, quantity: 1, clanCastle: true },
      ],
      heroes: [28_000_000],
      equipment: [{ equipmentId: 90_000_000, heroId: 28_000_000 }],
      petAssignments: [{ petId: 73_000_000, heroId: 28_000_000 }],
      siegeMachineId: 70_000_000,
    }),
  ).toEqual([
    { code: 'u_1', quantity: 12 },
    { code: 'i_2', quantity: 3 },
    { code: 's_3', quantity: 2 },
    { code: 'd_4', quantity: 1 },
    { code: 'h_28000000', quantity: 1 },
    { code: 'e_90000000', quantity: 1 },
    { code: 'p_73000000', quantity: 1 },
    { code: 'u_70000000', quantity: 1 },
  ]);
});
