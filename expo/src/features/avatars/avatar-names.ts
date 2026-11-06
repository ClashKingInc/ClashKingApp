import { useSyncExternalStore } from 'react';
import {
  gameDataState,
  subscribeToGameDataRevision,
  isRecord,
  localizedNameForItem,
} from '../../core/game-data';
import catalog from './catalog.json';

export function useAvatarNames(): Record<string, string> {
  useSyncExternalStore(subscribeToGameDataRevision, () => gameDataState.revision);
  return Object.fromEntries(
    catalog.map((avatar) => {
      const source =
        avatar.category === 'Hero'
          ? gameDataState.heroesData.heroes
          : gameDataState.troopsData.troops;
      const entries = Array.isArray(source)
        ? source
        : isRecord(source)
          ? Object.values(source)
          : [];
      const item =
        isRecord(source) && isRecord(source[avatar.name])
          ? source[avatar.name]
          : entries.find((item) => isRecord(item) && item.name === avatar.name);
      return [avatar.id, isRecord(item) ? localizedNameForItem(item) || avatar.name : avatar.name];
    }),
  );
}
