import { createContext } from 'react';
import { ImageAssets } from '../../core/assets/image-assets';
import { displayGameName, localizedNameForItem } from '../../core/game-data/game-data-localization';
import { gameDataState, isRecord, type JsonRecord } from '../../core/game-data/game-data-state';
import {
  UpgradeCategory,
  UpgradeQueue,
  UpgradeTrackerItem,
  UpgradeVillage,
} from '../upgrade-tracker/models';
import type { MessageKey } from '../../i18n';
import type { GameAssetManifest } from './models';

export const wikiSections: readonly { id: string; label: MessageKey }[] = [
  { id: 'troops', label: 'gameTroops' },
  { id: 'heroes', label: 'gameHeroes' },
  { id: 'spells', label: 'gameAssetsCategorySpells' },
  { id: 'equipment', label: 'gameAssetsCategoryEquipment' },
  { id: 'pets', label: 'gameAssetsCategoryPets' },
  { id: 'guardians', label: 'gameAssetsCategoryGuardians' },
  { id: 'buildings', label: 'gameAssetsCategoryBuildings' },
  { id: 'traps', label: 'upgradeTrackerPlanCategoryTraps' },
  { id: 'helpers', label: 'upgradeTrackerHelpers' },
  { id: 'league_tiers', label: 'rankingsRankedLeague' },
  { id: 'war_leagues', label: 'cwlClanWarLeague' },
  { id: 'builder_leagues', label: 'gameBaseBuilder' },
  { id: 'capital_leagues', label: 'wikiClanCapital' },
  { id: 'star_bonus', label: 'wikiStarBonus' },
  { id: 'battle_modifiers', label: 'wikiBattleModes' },
  { id: 'magic_items', label: 'wikiMagicItems' },
  { id: 'magic_snacks', label: 'wikiMagicSnacks' },
  { id: 'sceneries', label: 'upgradeTrackerSceneries' },
  { id: 'decorations', label: 'gameAssetsCategoryDecorations' },
  { id: 'obstacles', label: 'upgradeTrackerObstacles' },
];
export interface WikiEntry {
  key: string;
  section: string;
  name: string;
  meta: JsonRecord;
  image: string;
  tracker: UpgradeTrackerItem | null;
}
/** One visit uses one complete catalogue, including its artwork choices. */
export const WikiCatalogueContext = createContext<readonly WikiEntry[] | null>(null);

const categoryMap: Record<string, (typeof UpgradeCategory)[keyof typeof UpgradeCategory]> = {
  troops: UpgradeCategory.troops,
  heroes: UpgradeCategory.heroes,
  spells: UpgradeCategory.spells,
  equipment: UpgradeCategory.equipment,
  pets: UpgradeCategory.pets,
  guardians: UpgradeCategory.guardians,
  helpers: UpgradeCategory.builders,
  buildings: UpgradeCategory.defenses,
  traps: UpgradeCategory.traps,
};
const catalogues = new WeakMap<GameAssetManifest, { revision: number; entries: WikiEntry[] }>();

export function wikiCatalogue(manifest: GameAssetManifest | null): WikiEntry[] {
  const cached = manifest ? catalogues.get(manifest) : null;
  if (cached?.revision === gameDataState.revision) return cached.entries;
  // Index once. A catalogue render must not rescan thousands of images for
  // every item; that stalls the JS thread just as the Wiki screen opens.
  const byPath = new Map(manifest?.assets.map((asset) => [asset.path, asset]) ?? []);
  const normalize = (value: string) =>
    displayGameName(value)
      .toLowerCase()
      .replace(/[.’]/g, '')
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_|_$/g, '');
  const byItem = new Map<string, NonNullable<typeof manifest>['assets'][number]>();
  const leveled = new Map<string, NonNullable<typeof manifest>['assets'][number][]>();
  for (const asset of manifest?.assets ?? []) {
    const parts = asset.path.split('/');
    if (parts[0] === 'buildings' || parts[0] === 'traps') {
      if (parts.length === 4) {
        const key = `${parts[0]}:${parts[1]}:${normalize(parts[2]!)}`;
        leveled.set(key, [...(leveled.get(key) ?? []), asset]);
      }
      continue;
    }
    const leaf = parts.at(-1)!.replace(/\.[^.]+$/, '');
    const slug = normalize(/^(icon|portrait|full|render)$/.test(leaf) ? parts.at(-2)! : leaf);
    if (['decorations', 'obstacles'].includes(asset.category) && parts.length === 3)
      byItem.set(`${asset.category}:${parts[1]}:${slug}`, asset);
    const key = `${asset.category}:${slug}`;
    const score = (path: string) =>
      /\/(portrait|full|render)\./.test(path) ? 3 : /\/icon\./.test(path) ? 2 : 1;
    const current = byItem.get(key);
    if (!current || score(asset.path) > score(current.path)) byItem.set(key, asset);
  }
  const entries = wikiSections.flatMap((section) => {
    const raw = gameDataState.bundleData[section.id];
    const records = Array.isArray(raw)
      ? raw.filter(isRecord)
      : isRecord(raw) && Array.isArray(raw.items)
        ? raw.items.filter(isRecord)
        : [];
    // Retired training items are intentionally hidden from this reference, even
    // when an older game snapshot still contains their definitions.
    return records
      .filter(
        (meta) =>
          meta.available !== false &&
          !['Training Potion', 'Training Treat'].includes(String(meta.name)),
      )
      .map((meta) => {
        const name = localizedNameForItem(meta);
        const original = String(meta.name ?? '');
        const key = `${section.id}:${String(meta._id ?? meta.name ?? meta.townhall_level)}`;
        const levels = Array.isArray(meta.levels) ? meta.levels.filter(isRecord) : [];
        const minimum = levels.length
          ? Math.min(...levels.map((level) => Number(level.level) || 1))
          : 1;
        const maximum = Math.max(1, ...levels.map((level) => Number(level.level) || 1));
        const initialLevel = ['buildings', 'traps'].includes(section.id) ? maximum : minimum;
        const village =
          meta.village === 'builder' || meta.village === 'builderBase'
            ? UpgradeVillage.builderBase
            : UpgradeVillage.home;
        const slug = normalize(original);
        // Use an actual manifest entry when available. Do not invent portrait paths.
        const leagueSlug = slug
          .replace(/^p_e_k_k_a_/, 'pekka_')
          .replace(
            /_(iii|ii|iv|v|i)$/,
            (_, roman: string) =>
              `_${({ i: 1, ii: 2, iii: 3, iv: 4, v: 5 } as Record<string, number>)[roman]}`,
          );
        const folder = (
          {
            league_tiers: 'league-tier',
            war_leagues: 'cwl',
            builder_leagues: 'builder-base',
            capital_leagues: 'capital-leagues',
          } as Record<string, string>
        )[section.id];
        // Full path and village are part of identity. Never let a builder-base
        // Wall or an arbitrary level overwrite the home-village item's artwork.
        const buildingAssets =
          leveled.get(
            `${section.id}:${village === UpgradeVillage.home ? 'home-village' : 'builder-base'}:${slug}`,
          ) ?? [];
        // Metadata owns the opening level. If an export has no image at that
        // level, choose the newest available art, not filesystem ordering.
        const desired = [...buildingAssets]
          .filter((asset) => Number(asset.path.match(/\/level_(\d+)/)?.[1]) <= initialLevel)
          .sort((a, b) => {
            const levelDifference =
              Number(b.path.match(/\/level_(\d+)/)?.[1]) -
              Number(a.path.match(/\/level_(\d+)/)?.[1]);
            return levelDifference || a.path.localeCompare(b.path);
          })[0];
        const art = folder
          ? byPath.get(`leagues/${folder}/${leagueSlug}.png`)
          : (desired ??
            byItem.get(
              `${section.id}:${village === UpgradeVillage.home ? 'home-village' : 'builder-base'}:${slug}`,
            ) ??
            byItem.get(`${section.id}:${slug}`));
        const sceneryIcon =
          section.id === 'sceneries' ? byPath.get(`sceneries/${slug}/icon.webp`) : undefined;
        const image =
          // Only show a scenery when the manifest actually publishes a picture.
          // A metadata thumbnail path alone can refer to deferred/unavailable art.
          (section.id === 'sceneries'
            ? ((typeof meta.thumbnail === 'string' ? byPath.get(meta.thumbnail)?.url : undefined) ??
              sceneryIcon?.url)
            : typeof meta.thumbnail === 'string'
              ? `${ImageAssets.baseUrl}/${meta.thumbnail.split('/').map(encodeURIComponent).join('/')}`
              : undefined) ??
          art?.url ??
          (section.id === 'troops'
            ? ImageAssets.getTroopImage(original)
            : section.id === 'heroes'
              ? ImageAssets.getHeroImage(original)
              : section.id === 'spells'
                ? ImageAssets.getSpellImage(original)
                : section.id === 'equipment'
                  ? ImageAssets.getGearImage(original)
                  : section.id === 'pets'
                    ? ImageAssets.getPetImage(original)
                    : section.id === 'guardians'
                      ? ImageAssets.getGuardianImage(original)
                      : section.id === 'helpers'
                        ? ImageAssets.getHelperImage(original)
                        : section.id === 'league_tiers'
                          ? ImageAssets.getLeagueImage(original)
                          : section.id === 'war_leagues'
                            ? ImageAssets.getWarLeagueImage(original)
                            : section.id === 'capital_leagues'
                              ? ImageAssets.getCapitalLeagueImage(original)
                              : section.id === 'builder_leagues'
                                ? ImageAssets.getBuilderBaseLeagueImage(meta)
                                : section.id === 'star_bonus'
                                  ? ImageAssets.townHall(Number(meta.townhall_level))
                                  : section.id === 'buildings'
                                    ? village === UpgradeVillage.home
                                      ? ImageAssets.getHomeVillageBuildingImage(original, maximum)
                                      : ImageAssets.getBuilderBaseBuildingImage(original, maximum)
                                    : section.id === 'traps'
                                      ? village === UpgradeVillage.home
                                        ? ImageAssets.getHomeVillageTrapImage(original, maximum)
                                        : ImageAssets.getBuilderBaseTrapImage(original, maximum)
                                      : '');
        const category = categoryMap[section.id];
        const tracker =
          category && levels.length
            ? new UpgradeTrackerItem({
                id: Number(meta._id),
                name: original,
                imageUrl: image,
                village,
                category,
                queue: UpgradeQueue.none,
                currentLevel: initialLevel,
                targetLevel: maximum,
                count: 1,
                steps: [],
                completedUpgradeSeconds: 0,
                totalUpgradeSeconds: 0,
                meta: {
                  ...meta,
                  wiki_image: image,
                  ...(art && /portrait|full|render/.test(art.path) ? { portrait: art.url } : {}),
                },
              })
            : null;
        return {
          key,
          section: section.id,
          name,
          meta: sceneryIcon ? { ...meta, icon: sceneryIcon.url } : meta,
          image,
          tracker,
        };
      })
      .filter((entry) => entry.section !== 'sceneries' || !!entry.image);
  });
  if (manifest) catalogues.set(manifest, { revision: gameDataState.revision, entries });
  return entries;
}
