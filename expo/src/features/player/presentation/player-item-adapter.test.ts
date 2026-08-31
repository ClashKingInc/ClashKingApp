import {
  PlayerBuilderBaseTroop,
  PlayerEquipment,
  PlayerHero,
  PlayerPet,
  PlayerSiegeMachine,
  PlayerSpell,
} from '../models/player-items';
import { UpgradeCategory, UpgradeQueue, UpgradeVillage } from '../../upgrade-tracker/models';
import { upgradeDetailsItem } from './player-item-detail-adapter';

const raw = (name: string, meta: Record<string, unknown> = {}) => ({
  name,
  level: 1,
  maxLevel: 2,
  isUnlocked: true,
  meta: {
    ...meta,
    levels: [{ level: 1, upgrade_cost: { ' Dark Elixir! ': 12 }, upgrade_time: 60 }],
  },
});

describe('player item upgrade-detail adapter', () => {
  it.each([
    [
      PlayerHero.fromRaw({ ...raw('Hero'), equipment: [] } as never),
      UpgradeCategory.heroes,
      UpgradeQueue.builders,
    ],
    [PlayerSpell.fromRaw(raw('Spell')), UpgradeCategory.spells, UpgradeQueue.laboratory],
    [
      PlayerEquipment.fromRaw(raw('Gear', { rarity: '2', warden_weight: '1.5', healer_weight: 2 })),
      UpgradeCategory.equipment,
      UpgradeQueue.builders,
    ],
    [PlayerPet.fromRaw(raw('Pet')), UpgradeCategory.pets, UpgradeQueue.pets],
    [PlayerSiegeMachine.fromRaw(raw('Siege')), UpgradeCategory.sieges, UpgradeQueue.laboratory],
  ])('maps subtype category and queue exactly', (source, category, queue) => {
    const item = upgradeDetailsItem(source);
    expect(item.category).toBe(category);
    expect(item.queue).toBe(queue);
    expect(item.steps[0]?.costs[0]?.resource).toBe('dark_elixir');
    expect(item.id).toBe(upgradeDetailsItem(source).id);
  });

  it('preserves weight rows and builder-base village', () => {
    const gear = upgradeDetailsItem(
      PlayerEquipment.fromRaw(raw('Gear', { warden_weight: '1.5', healer_weight: 2 })),
    );
    expect(gear.wardenWeight).toBe(1.5);
    expect(gear.healerWeight).toBe(2);
    expect(
      upgradeDetailsItem(PlayerBuilderBaseTroop.fromRaw(raw('BB', { village: 'builderBase' })))
        .village,
    ).toBe(UpgradeVillage.builderBase);
  });
});
