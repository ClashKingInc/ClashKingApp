import { flutterCompatibleAndroidDeviceId, loadMigratedIosFallbackId } from './device-identity';

describe('ExpoDeviceIdentity', () => {
  it('preserves Flutter AndroidInfo.id continuity by using the OS build ID', () => {
    expect(flutterCompatibleAndroidDeviceId('UP1A.231005.007')).toBe('UP1A.231005.007');
    expect(flutterCompatibleAndroidDeviceId(null)).toBe('unknown-device');
  });

  it('moves the rare legacy iOS fallback id into the shared keychain before generating one', async () => {
    const values = new Map<string, string>();
    const store = {
      getItem: async (key: string) => values.get(key) ?? null,
      setItem: async (key: string, value: string) => {
        values.set(key, value);
      },
      removeItem: async (key: string) => {
        values.delete(key);
      },
    };
    const readSecureValue = jest.fn(async () => 'flutter-fallback-id');
    await expect(
      loadMigratedIosFallbackId(store, { readSecureValue }, () => 'new-id'),
    ).resolves.toBe('flutter-fallback-id');
    expect(readSecureValue).toHaveBeenCalledWith('device_id_fallback', false);
    expect(values.get('device_id_fallback')).toBe('flutter-fallback-id');
  });
});
