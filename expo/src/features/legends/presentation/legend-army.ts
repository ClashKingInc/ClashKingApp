import { parseArmyCounts, PlayerBattlelogArmyCatalog } from '../../player/models/player-battlelog';

export type LegendArmyItem = { readonly code: string; readonly count: number };
export type LegendHeroLoadout = {
  readonly hero: LegendArmyItem;
  readonly pet: LegendArmyItem | null;
  readonly equipment: readonly LegendArmyItem[];
};

const LEGEND_SIEGE_IDS = new Set([51, 52, 62, 75, 87, 91, 92, 135, 188]);

function armyPayload(shareCode: string) {
  try {
    return new URL(shareCode).searchParams.get('army') ?? shareCode;
  } catch {
    const encoded = shareCode.match(/[?&]army=([^&]+)/)?.[1];
    return encoded ? decodeURIComponent(encoded) : shareCode;
  }
}

export function legendHeroLoadouts(shareCode: string): readonly LegendHeroLoadout[] {
  const heroes = /(?:^|[?&])?h([^idsu]*)/.exec(armyPayload(shareCode))?.[1] ?? '';
  return heroes
    .split('-')
    .map((part) => /^(\d+)(?:m\d+)?(?:p(\d+))?(?:e(\d+(?:_\d+)*))?$/.exec(part))
    .filter((match): match is RegExpExecArray => match !== null)
    .slice(0, 4)
    .map((match) => ({
      hero: { code: `h_${match[1]}`, count: 1 },
      pet: match[2] ? { code: `p_${match[2]}`, count: 1 } : null,
      equipment: (match[3]?.split('_') ?? []).slice(0, 2).map((id) => ({
        code: `e_${id}`,
        count: 1,
      })),
    }));
}

export function legendArmyGroups(shareCode: string) {
  const groups: Record<string, LegendArmyItem[]> = {
    Troops: [],
    Spells: [],
    'Clan Castle': [],
    Siege: [],
    Heroes: [],
  };
  const siegeCounts = new Map<string, number>();
  for (const [code, count] of Object.entries(parseArmyCounts(shareCode))) {
    const item = PlayerBattlelogArmyCatalog.resolve(code);
    if (isLegendSiege(code, item.siege)) {
      const canonical = `u_${Number(code.split('_')[1]) % 1_000_000}`;
      siegeCounts.set(canonical, Math.max(siegeCounts.get(canonical) ?? 0, count));
      continue;
    }
    const group =
      code.startsWith('i_') || code.startsWith('d_')
        ? 'Clan Castle'
        : code.startsWith('s_')
          ? 'Spells'
          : 'Troops';
    groups[group]!.push({ code, count });
  }
  groups.Siege!.push(...[...siegeCounts].map(([code, count]) => ({ code, count })));
  for (const loadout of legendHeroLoadouts(shareCode)) {
    groups.Heroes!.push(loadout.hero);
    if (loadout.pet) groups.Heroes!.push(loadout.pet);
    groups.Heroes!.push(...loadout.equipment);
  }
  return Object.entries(groups).filter(([, items]) => items.length);
}

export function popularLegendItems(codes: readonly string[]) {
  const totals = new Map<string, number>();
  for (const share of codes) {
    const siegeInArmy = new Set<string>();
    for (const [code, count] of Object.entries(parseArmyCounts(share))) {
      if (!code.startsWith('u_') && !code.startsWith('i_') && !code.startsWith('s_')) continue;
      const item = PlayerBattlelogArmyCatalog.resolve(code);
      if (isLegendSiege(code, item.siege)) {
        const canonical = `u_${Number(code.split('_')[1]) % 1_000_000}`;
        if (siegeInArmy.has(canonical)) continue;
        siegeInArmy.add(canonical);
        totals.set(canonical, (totals.get(canonical) ?? 0) + 1);
      } else if (code.startsWith('u_')) {
        totals.set(code, (totals.get(code) ?? 0) + count * item.housingSpace);
      } else if (code.startsWith('s_')) {
        totals.set(code, (totals.get(code) ?? 0) + count);
      }
    }
  }
  return ['Troop', 'Spell', 'Siege'].flatMap((category) => {
    const entry = [...totals]
      .filter(([code, value]) => {
        const item = PlayerBattlelogArmyCatalog.resolve(code);
        const siege = isLegendSiege(code, item.siege);
        return (
          value > 0 &&
          (category === 'Siege'
            ? siege
            : category === 'Spell'
              ? code.startsWith('s_')
              : code.startsWith('u_') && !siege)
        );
      })
      .sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]))[0];
    return entry
      ? [{ category, item: PlayerBattlelogArmyCatalog.resolve(entry[0]), score: entry[1] }]
      : [];
  });
}

export function isLegendSiege(code: string, catalogSiege = false) {
  if (catalogSiege) return true;
  const id = Number.parseInt(code.split('_')[1] ?? '', 10);
  return Number.isFinite(id) && LEGEND_SIEGE_IDS.has(id % 1_000_000);
}
