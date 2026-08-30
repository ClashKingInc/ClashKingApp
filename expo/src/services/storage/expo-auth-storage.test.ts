import ClashKingNative from '@clashking/native';
import * as SecureStore from 'expo-secure-store';

import { SECURE_STORAGE_KEYS, STORAGE_KEYS } from '../../core/storage/storage';
import { ExpoSharedAuthSecureStore } from './expo-auth-storage';

jest.mock('@clashking/native', () => ({
  __esModule: true,
  default: {
    clearSharedAuthSession: jest.fn(async () => undefined),
    readSharedAuthSession: jest.fn(async () => 'flutter-session'),
    writeSharedAuthSession: jest.fn(async () => undefined),
  },
}));
jest.mock('expo-secure-store', () => ({
  AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY: 1,
  deleteItemAsync: jest.fn(async () => undefined),
  getItemAsync: jest.fn(async () => 'secure-value'),
  setItemAsync: jest.fn(async () => undefined),
}));
jest.mock('@react-native-async-storage/async-storage', () => ({
  __esModule: true,
  default: {
    clear: jest.fn(async () => undefined),
    getItem: jest.fn(async () => null),
    removeItem: jest.fn(async () => undefined),
    setItem: jest.fn(async () => undefined),
  },
}));

describe('ExpoSharedAuthSecureStore', () => {
  beforeEach(() => jest.clearAllMocks());

  it('routes the shared session through the exact Flutter native store', async () => {
    const store = new ExpoSharedAuthSecureStore();

    await expect(store.getItem(SECURE_STORAGE_KEYS.sharedAuthSession)).resolves.toBe(
      'flutter-session',
    );
    await store.setItem(SECURE_STORAGE_KEYS.sharedAuthSession, 'next-session');
    await store.removeItem(SECURE_STORAGE_KEYS.sharedAuthSession);

    expect(ClashKingNative.readSharedAuthSession).toHaveBeenCalledTimes(1);
    expect(ClashKingNative.writeSharedAuthSession).toHaveBeenCalledWith('next-session');
    expect(ClashKingNative.clearSharedAuthSession).toHaveBeenCalledTimes(1);
    expect(SecureStore.getItemAsync).not.toHaveBeenCalled();
  });

  it('keeps non-session secrets in Expo SecureStore', async () => {
    const store = new ExpoSharedAuthSecureStore();

    await expect(store.getItem(STORAGE_KEYS.deviceIdFallback)).resolves.toBe('secure-value');
    await store.setItem(STORAGE_KEYS.deviceIdFallback, 'device-id');
    await store.removeItem(STORAGE_KEYS.deviceIdFallback);

    expect(SecureStore.getItemAsync).toHaveBeenCalledWith(
      STORAGE_KEYS.deviceIdFallback,
      expect.any(Object),
    );
    expect(SecureStore.setItemAsync).toHaveBeenCalledWith(
      STORAGE_KEYS.deviceIdFallback,
      'device-id',
      expect.any(Object),
    );
    expect(SecureStore.deleteItemAsync).toHaveBeenCalledWith(
      STORAGE_KEYS.deviceIdFallback,
      expect.any(Object),
    );
  });
});
