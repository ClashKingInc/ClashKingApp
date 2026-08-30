import AsyncStorage from '@react-native-async-storage/async-storage';
import { Directory, File, Paths } from 'expo-file-system';
import { getLocales } from 'expo-localization';
import { Platform } from 'react-native';

import {
  GameDataService,
  type GameDataFileStore,
  type GameDataPlatform,
  type GameDataPreferences,
} from './game-data-service';

/**
 * Expo exposes a persistent document sandbox rather than Flutter's application-support directory.
 * Keeping the same `game_data` child and filenames preserves lifecycle and cache behavior.
 */
export class ExpoGameDataFileStore implements GameDataFileStore {
  private readonly directory = new Directory(Paths.document, 'game_data');

  async read(fileName: string): Promise<string | null> {
    const file = new File(this.directory, fileName);
    if (!file.exists) return null;
    return file.text();
  }

  async write(fileName: string, contents: string): Promise<void> {
    this.directory.create({ intermediates: true, idempotent: true });
    const file = new File(this.directory, fileName);
    file.write(contents);
  }
}

export class AsyncStorageGameDataPreferences implements GameDataPreferences {
  getString(key: string): Promise<string | null> {
    return AsyncStorage.getItem(key);
  }

  async setString(key: string, value: string): Promise<void> {
    await AsyncStorage.setItem(key, value);
  }
}

export function createExpoGameDataService(): GameDataService {
  const platform: GameDataPlatform = Platform.OS === 'web' ? 'web' : 'native';
  return new GameDataService({
    platform,
    files: new ExpoGameDataFileStore(),
    preferences: new AsyncStorageGameDataPreferences(),
    systemLocales: () =>
      getLocales().map((locale) => ({
        languageCode: locale.languageCode ?? 'en',
        countryCode: locale.regionCode,
        scriptCode: locale.languageScriptCode,
      })),
  });
}
