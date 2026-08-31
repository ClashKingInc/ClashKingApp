import { GameAsset } from './models';
import { GameAssetActionError, PlatformGameAssetActions, mimeTypeForExtension } from './actions';

jest.mock('@clashking/native', () => ({ __esModule: true, default: { saveFile: jest.fn() } }));

const asset = new GameAsset({
  path: 'heroes/king.png',
  category: 'heroes',
  displayName: 'King',
  extension: 'png',
  url: 'https://assets.test/king.png',
});

describe('game asset actions', () => {
  it('maps every supported format to its exact MIME type', () => {
    expect(mimeTypeForExtension('svg')).toBe('image/svg+xml');
    expect(mimeTypeForExtension('jpeg')).toBe('image/jpeg');
    expect(mimeTypeForExtension('jpg')).toBe('image/jpeg');
    expect(mimeTypeForExtension('gif')).toBe('image/gif');
    expect(mimeTypeForExtension('webp')).toBe('image/webp');
    expect(mimeTypeForExtension('png')).toBe('image/png');
  });

  it('rejects failed downloads before invoking a platform saver', async () => {
    const actions = new PlatformGameAssetActions({
      platform: 'web',
      fetchImplementation: jest.fn(
        async (_input: RequestInfo | URL, _init?: RequestInit) =>
          ({ ok: false, status: 404 }) as Response,
      ) as typeof fetch,
    });
    await expect(actions.save(asset)).rejects.toEqual(
      new GameAssetActionError('Asset download failed (404)'),
    );
  });

  it('downloads bytes and opens the native save picker with the Flutter filename and MIME type', async () => {
    const saveFile = jest.fn(async () => 'content://saved/king.png');
    const actions = new PlatformGameAssetActions({
      platform: 'android',
      fetchImplementation: jest.fn(
        async (_input: RequestInfo | URL, _init?: RequestInit) =>
          ({
            ok: true,
            arrayBuffer: async () => new Uint8Array([1, 2, 3]).buffer,
          }) as Response,
      ) as typeof fetch,
      saveFile,
    });

    await expect(actions.save(asset)).resolves.toBe('content://saved/king.png');
    expect(saveFile).toHaveBeenCalledWith({
      fileUri: expect.stringMatching(/king\.png$/),
      fileName: 'king.png',
      mimeType: 'image/png',
    });
  });
});
