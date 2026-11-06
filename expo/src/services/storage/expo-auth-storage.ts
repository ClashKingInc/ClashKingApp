import AsyncStorage from '@react-native-async-storage/async-storage';
import ClashKingNative from '@clashking/native';
import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

import { reportException } from '../../core/observability/observability';
import { SECURE_STORAGE_KEYS } from '../../core/storage/storage';
import type {
  LegacyFlutterStorageBridge,
  LegacyMigrationCapabilities,
  RuntimePlatform,
  StringStore,
} from './auth-storage';

export const SHARED_AUTH_KEYCHAIN_ACCESS_GROUP = 'MZYXD43RX5.group.com.clashking.apps';
export const SHARED_AUTH_KEYCHAIN_SERVICE = 'flutter_secure_storage_service';

const secureStoreOptions: SecureStore.SecureStoreOptions = {
  accessGroup: SHARED_AUTH_KEYCHAIN_ACCESS_GROUP,
  keychainService: SHARED_AUTH_KEYCHAIN_SERVICE,
  keychainAccessible: SecureStore.AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY,
};

const androidSessionOptions: SecureStore.SecureStoreOptions = {
  keychainService: 'clashking.auth.v2',
};
const ANDROID_SESSION_IMPORTED = 'legacy_session_imported';

function isUnreadableAndroidLegacyStorage(error: unknown): boolean {
  const message = String(error);
  return (
    Platform.OS === 'android' &&
    (message.includes('Migration failed after algorithm change') ||
      message.includes('Key mismatch after algorithm change'))
  );
}

export class ExpoSharedAuthSecureStore implements StringStore {
  getItem(key: string): Promise<string | null> {
    if (Platform.OS === 'web') return Promise.resolve(null);
    if (key === SECURE_STORAGE_KEYS.sharedAuthSession) {
      return Platform.OS === 'android'
        ? this.readAndroidSession()
        : ClashKingNative.readSharedAuthSession();
    }
    return SecureStore.getItemAsync(key, secureStoreOptions);
  }

  async setItem(key: string, value: string): Promise<void> {
    if (Platform.OS === 'web') return;
    if (key === SECURE_STORAGE_KEYS.sharedAuthSession) {
      if (Platform.OS === 'android') {
        await SecureStore.setItemAsync(key, value, androidSessionOptions);
        await SecureStore.setItemAsync(ANDROID_SESSION_IMPORTED, 'true', androidSessionOptions);
      } else await ClashKingNative.writeSharedAuthSession(value);
      return;
    }
    await SecureStore.setItemAsync(key, value, secureStoreOptions);
  }

  async removeItem(key: string): Promise<void> {
    if (Platform.OS === 'web') return;
    if (key === SECURE_STORAGE_KEYS.sharedAuthSession) {
      if (Platform.OS === 'android') {
        // Keep the import tombstone after logout. A surviving Flutter copy must
        // never silently sign this installation back into the previous account.
        await SecureStore.setItemAsync(ANDROID_SESSION_IMPORTED, 'true', androidSessionOptions);
        await SecureStore.setItemAsync(
          SECURE_STORAGE_KEYS.flutterAuthMigration,
          'true',
          secureStoreOptions,
        );
        await SecureStore.deleteItemAsync(key, androidSessionOptions);
      } else await ClashKingNative.clearSharedAuthSession();
      return;
    }
    await SecureStore.deleteItemAsync(key, secureStoreOptions);
  }

  private async readAndroidSession(): Promise<string | null> {
    const key = SECURE_STORAGE_KEYS.sharedAuthSession;
    const current = await SecureStore.getItemAsync(key, androidSessionOptions);
    if (current !== null) return current;
    if (
      (await SecureStore.getItemAsync(ANDROID_SESSION_IMPORTED, androidSessionOptions)) === 'true'
    ) {
      return null;
    }
    try {
      const legacy = await ClashKingNative.readSharedAuthSession();
      if (legacy !== null) await this.setItem(key, legacy);
      return legacy;
    } catch (error) {
      if (!isUnreadableAndroidLegacyStorage(error)) throw error;
      // The new store uses its own key alias. Do not reset the old cipher or
      // delete unrelated encrypted preferences when an upgrade cannot decrypt it.
      await SecureStore.setItemAsync(
        SECURE_STORAGE_KEYS.flutterAuthMigration,
        'true',
        secureStoreOptions,
      );
      await SecureStore.setItemAsync(ANDROID_SESSION_IMPORTED, 'true', androidSessionOptions);
      reportException(error, 'auth.legacySessionRecovery');
      return null;
    }
  }
}

export class ExpoPreferenceStore implements StringStore {
  getItem(key: string): Promise<string | null> {
    return AsyncStorage.getItem(key);
  }

  getString(key: string): Promise<string | null> {
    return this.getItem(key);
  }

  async setItem(key: string, value: string): Promise<void> {
    await AsyncStorage.setItem(key, value);
  }

  setString(key: string, value: string): Promise<void> {
    return this.setItem(key, value);
  }

  async removeItem(key: string): Promise<void> {
    await AsyncStorage.removeItem(key);
  }

  remove(key: string): Promise<void> {
    return this.removeItem(key);
  }

  async clear(): Promise<void> {
    await AsyncStorage.clear();
  }
}

export class ClashKingLegacyFlutterBridge implements LegacyFlutterStorageBridge {
  getCapabilities(): LegacyMigrationCapabilities {
    return ClashKingNative.getLegacyMigrationCapabilities();
  }

  readSecureValue(key: string, sharedAccessGroup = false): Promise<string | null> {
    return ClashKingNative.readLegacyFlutterSecureValue(key, sharedAccessGroup);
  }

  async readAllSecureValues(sharedAccessGroup = false): Promise<Record<string, string>> {
    try {
      return await ClashKingNative.readAllLegacyFlutterSecureValues(sharedAccessGroup);
    } catch (error) {
      if (!isUnreadableAndroidLegacyStorage(error)) throw error;
      // Plain Flutter preferences can still migrate when old encrypted data
      // cannot. Keep the old encrypted store intact for possible later recovery.
      return {};
    }
  }

  readPreferences(
    keys: readonly string[],
  ): Promise<Record<string, string | number | boolean | null>> {
    return ClashKingNative.readLegacyFlutterPreferences([...keys]);
  }

  readAllPreferences(): Promise<Record<string, string | number | boolean | null>> {
    return ClashKingNative.readAllLegacyFlutterPreferences();
  }
}

export function currentRuntimePlatform(): RuntimePlatform {
  if (Platform.OS === 'ios') return 'ios';
  if (Platform.OS === 'android') return 'android';
  return 'web';
}
