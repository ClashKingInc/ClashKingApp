import { bundledImageUrl } from '../../../core/assets/bundled-image-source';
import { ImageAssets } from '../../../core/assets/image-assets';
import { UpgradeVillage, type UpgradeVillageValue } from '../models';

/** Category artwork is stable across account levels, priorities and exported posters. */
export function trackerCategoryImage(key: string, village: UpgradeVillageValue): string {
  const home = village === UpgradeVillage.home;
  switch (key) {
    case 'buildings':
      return ImageAssets.getHomeVillageBuildingImage('Clan Castle', 3);
    case 'builders':
      // Builder Base has no Builder's Hut asset; this is the shared builders symbol.
      return ImageAssets.getHomeVillageBuildingImage("Builder's Hut", 1);
    case 'laboratory':
      return home
        ? ImageAssets.getHomeVillageBuildingImage('Laboratory', 1)
        : ImageAssets.getBuilderBaseBuildingImage('Star Laboratory', 1);
    case 'troops':
    case 'darkTroops':
      return ImageAssets.upgradeCategoryIcons.troops;
    case 'spells':
      return ImageAssets.upgradeCategoryIcons.spells;
    case 'sieges':
    case 'siege':
      return ImageAssets.upgradeCategoryIcons.siege;
    case 'equipment':
      return bundledImageUrl(require('../../../../assets/clashking/tracker/equipment-anvil.webp'));
    case 'supercharges':
    case 'supercharge':
      return bundledImageUrl(
        require('../../../../assets/clashking/calculators/supercharge-icon.webp'),
      );
    case 'craftedDefenses':
      return bundledImageUrl(require('../../../../assets/clashking/tracker/crafting-station.webp'));
    case 'defenses':
      return home
        ? ImageAssets.getHomeVillageBuildingImage('Cannon', 1)
        : ImageAssets.getBuilderBaseBuildingImage('Cannon', 1);
    case 'army':
      return home ? ImageAssets.townHall(1) : ImageAssets.builderHall(1);
    case 'resources':
      return home
        ? ImageAssets.getHomeVillageBuildingImage('Gold Storage', 1)
        : ImageAssets.getBuilderBaseBuildingImage('Gold Storage', 1);
    case 'traps':
      return home
        ? ImageAssets.getHomeVillageTrapImage('Air Bomb', 1)
        : ImageAssets.getBuilderBaseTrapImage('Push Trap', 1);
    case 'heroes':
      return home
        ? ImageAssets.upgradeCategoryIcons.heroes
        : ImageAssets.getBuilderBaseHeroImage('Battle Machine');
    case 'guardians':
      return `${ImageAssets.baseUrl}/guardians/smasher/icon.webp`;
    case 'pets':
      return ImageAssets.upgradeCategoryIcons.pets;
    case 'walls':
      return home
        ? ImageAssets.getHomeVillageBuildingImage('Wall', 1)
        : ImageAssets.getBuilderBaseBuildingImage('Wall', 1);
    default:
      return ImageAssets.getHomeVillageBuildingImage("Builder's Hut", 1);
  }
}

/** Some source images have more transparent margin; normalize their visible footprint. */
export function trackerCategoryImageScale(key: string) {
  return key === 'equipment' ? 0.9 : 1;
}
