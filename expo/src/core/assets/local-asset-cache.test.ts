import { fetch } from 'expo/fetch';
import { File } from 'expo-file-system';
import { ManagedImageCache, type ImageFiles } from './managed-image-cache';
import './local-asset-cache';

jest.mock('@react-native-async-storage/async-storage', () => ({ __esModule: true, default: {} }));
jest.mock('./managed-image-cache', () => ({ ManagedImageCache: jest.fn() }));
jest.mock('expo/fetch', () => ({ fetch: jest.fn() }));
jest.mock('expo-crypto', () => ({ randomUUID: () => 'download' }));
jest.mock('expo-file-system', () => ({
  Paths: { cache: 'file:///cache' },
  Directory: class {
    uri = 'file:///cache/clashking-images-v2';
    create() {}
  },
  File: jest
    .fn()
    .mockImplementation(() => ({ uri: 'file:///download.avif', write: jest.fn(), exists: false })),
}));

const files = jest.mocked(ManagedImageCache).mock.calls[0]![1] as ImageFiles;
test('accepts first-time converted bytes without a source-SHA header and records the manifest SHA', async () => {
  let read = false;
  jest.mocked(fetch).mockResolvedValue({
    ok: true,
    headers: new Headers({ 'content-type': 'image/avif' }),
    body: {
      getReader: () => ({
        read: async () => {
          if (read) return { done: true };
          read = true;
          return { done: false, value: new Uint8Array([1, 2, 3]) };
        },
      }),
    },
  } as unknown as Awaited<ReturnType<typeof fetch>>);
  const sha = 'a'.repeat(64);
  expect(await files.download('https://assets.clashk.ing/pets/a.avif?size=128', sha)).toEqual({
    file: 'file:///download.avif',
    sha,
    bytes: 3,
  });
  expect(File).toHaveBeenCalled();
});

test('does not save failed HTTP responses as a successfully downloaded image', async () => {
  jest.mocked(fetch).mockResolvedValue({ ok: false } as Awaited<ReturnType<typeof fetch>>);
  const before = jest.mocked(File).mock.calls.length;
  await expect(
    files.download('https://assets.clashk.ing/pets/a.avif', 'a'.repeat(64)),
  ).rejects.toThrow('Image download failed');
  expect(jest.mocked(File).mock.calls).toHaveLength(before);
});
