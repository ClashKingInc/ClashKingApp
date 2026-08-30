export type JsonRecord = Record<string, unknown>;

/** Mutable shared views preserved for one-for-one compatibility with Flutter's GameDataService. */
export const gameDataState = {
  petsData: {} as JsonRecord,
  heroesData: {} as JsonRecord,
  troopsData: {} as JsonRecord,
  spellsData: {} as JsonRecord,
  gearsData: {} as JsonRecord,
  leagueData: {} as JsonRecord,
  warLeagueData: {} as JsonRecord,
  playerLeagueData: {} as JsonRecord,
  gameData: {} as JsonRecord,
  bundleData: {} as JsonRecord,
  translationsData: {} as Record<string, string>,
  translationLocale: 'EN',
  revision: 0,
};

const revisionListeners = new Set<(revision: number) => void>();

export function bumpGameDataRevision(): number {
  gameDataState.revision += 1;
  for (const listener of revisionListeners) listener(gameDataState.revision);
  return gameDataState.revision;
}

export function subscribeToGameDataRevision(listener: (revision: number) => void): () => void {
  revisionListeners.add(listener);
  return () => revisionListeners.delete(listener);
}

export function resetGameDataStateForTesting(): void {
  replaceGameDataSection(gameDataState.petsData, {});
  replaceGameDataSection(gameDataState.heroesData, {});
  replaceGameDataSection(gameDataState.troopsData, {});
  replaceGameDataSection(gameDataState.spellsData, {});
  replaceGameDataSection(gameDataState.gearsData, {});
  replaceGameDataSection(gameDataState.leagueData, {});
  replaceGameDataSection(gameDataState.warLeagueData, {});
  replaceGameDataSection(gameDataState.playerLeagueData, {});
  replaceGameDataSection(gameDataState.gameData, {});
  replaceGameDataSection(gameDataState.bundleData, {});
  for (const key of Object.keys(gameDataState.translationsData)) {
    delete gameDataState.translationsData[key];
  }
  gameDataState.translationLocale = 'EN';
  gameDataState.revision = 0;
  revisionListeners.clear();
}

export function replaceGameDataSection(target: JsonRecord, source: unknown): void {
  for (const key of Object.keys(target)) delete target[key];
  if (isRecord(source)) Object.assign(target, source);
}

export function isRecord(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}
