export interface ArmyCompositionLike {
  readonly mainTroops: readonly { readonly id: number; readonly quantity: number }[];
  readonly clanCastleTroops: readonly { readonly id: number; readonly quantity: number }[];
  readonly spells: readonly {
    readonly id: number;
    readonly quantity: number;
    readonly clanCastle: boolean;
  }[];
  readonly heroes: readonly number[];
  readonly equipment: readonly {
    readonly equipmentId: number;
    readonly heroId: number;
  }[];
  readonly petAssignments: readonly { readonly petId: number; readonly heroId: number }[];
  readonly siegeMachineId: number | null;
}

export interface ArmyDisplayItem {
  readonly code: string;
  readonly quantity: number;
}

export function armyDisplayItems(army: ArmyCompositionLike): ArmyDisplayItem[] {
  return [
    ...army.mainTroops.map((item) => ({ code: `u_${item.id}`, quantity: item.quantity })),
    ...army.clanCastleTroops.map((item) => ({ code: `i_${item.id}`, quantity: item.quantity })),
    ...army.spells.map((item) => ({
      code: `${item.clanCastle ? 'd' : 's'}_${item.id}`,
      quantity: item.quantity,
    })),
    ...army.heroes.map((id) => ({ code: `h_${id}`, quantity: 1 })),
    ...army.equipment.map((item) => ({ code: `e_${item.equipmentId}`, quantity: 1 })),
    ...army.petAssignments.map((item) => ({ code: `p_${item.petId}`, quantity: 1 })),
    ...(army.siegeMachineId === null ? [] : [{ code: `u_${army.siegeMachineId}`, quantity: 1 }]),
  ];
}
