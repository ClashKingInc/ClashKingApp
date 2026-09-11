import { webGameDataFileStore } from './web-game-data-file-store';

describe('web game-data persistence', () => {
  const original = Object.getOwnPropertyDescriptor(globalThis, 'caches');
  afterEach(() => {
    if (original) Object.defineProperty(globalThis, 'caches', original);
    else Reflect.deleteProperty(globalThis, 'caches');
  });

  it('supports environments without Cache Storage', async () => {
    Reflect.deleteProperty(globalThis, 'caches');
    expect(await webGameDataFileStore.read('units.json')).toBeNull();
    await expect(webGameDataFileStore.write('units.json', '{}')).rejects.toThrow();
  });

  it('reads only its own public-metadata cache and encoded key', async () => {
    const match = jest.fn(async () => ({ text: async () => '{"units":[]}' }));
    const open = jest.fn(async () => ({ match }));
    Object.defineProperty(globalThis, 'caches', { configurable: true, value: { open } });
    expect(await webGameDataFileStore.read('units/en.json')).toBe('{"units":[]}');
    expect(open).toHaveBeenCalledWith('clashking-game-data-v1');
    expect(match).toHaveBeenCalledWith('/__game-data/units%2Fen.json');
  });

  it('treats an unreadable cached body as a miss', async () => {
    Object.defineProperty(globalThis, 'caches', {
      configurable: true,
      value: {
        open: async () => ({
          match: async () => ({
            text: async () => {
              throw new Error('unreadable');
            },
          }),
        }),
      },
    });
    expect(await webGameDataFileStore.read('units.json')).toBeNull();
  });

  it('reports storage failure so the service does not commit a missing body', async () => {
    Object.defineProperty(globalThis, 'caches', {
      configurable: true,
      value: {
        open: async () => {
          throw new Error('quota');
        },
      },
    });
    expect(await webGameDataFileStore.read('units.json')).toBeNull();
    await expect(webGameDataFileStore.write('units.json', '{}')).rejects.toThrow('quota');
  });
});
