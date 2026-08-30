import { GameAsset, GameAssetManifest, filterGameAssets, formatGameAssetCategory } from './models';

function raw(path: string, overrides: Record<string, unknown> = {}) {
  const extension = path.split('.').at(-1)!;
  return {
    path,
    category: path.split('/')[0],
    display_name: path.split('/').at(-1)!.replace(`.${extension}`, ''),
    extension,
    url: `https://assets.test/${path}`,
    ...overrides,
  };
}

describe('game asset manifest models', () => {
  it('validates version and assets then applies Flutter natural path sorting', () => {
    const manifest = GameAssetManifest.fromJson({
      version: 1,
      assets: [raw('troops/unit_10.png'), raw('troops/unit_2.png'), raw('heroes/king.png')],
    });
    expect(manifest.assets.map((asset) => asset.path)).toEqual([
      'heroes/king.png',
      'troops/unit_2.png',
      'troops/unit_10.png',
    ]);
    expect(manifest.categories.map((category) => category.id)).toEqual(['heroes', 'troops']);
  });

  it.each([
    [{ version: 2, assets: [] }, 'Unsupported game asset manifest version'],
    [{ version: 1, assets: 'bad' }, 'assets must be a list'],
    [{ version: 1, assets: [raw('bot/icon.png')] }, 'bot asset folder'],
    [
      { version: 1, assets: [raw('heroes/king.png', { category: 'troops' })] },
      'category does not match',
    ],
    [
      { version: 1, assets: [raw('heroes/king.png', { extension: 'svg' })] },
      'extension does not match',
    ],
    [{ version: 1, assets: [raw('heroes/king.bmp')] }, 'Unsupported game asset extension'],
    [
      { version: 1, assets: [raw('heroes/king.png', { url: 'file:///king.png' })] },
      'Invalid game asset URL',
    ],
  ])('rejects malformed manifests', (value, message) => {
    expect(() => GameAssetManifest.fromJson(value)).toThrow(message as string);
  });

  it('builds category metadata, picks a non-SVG representative, and filters search/format', () => {
    const manifest = GameAssetManifest.fromJson({
      version: 1,
      assets: [raw('heroes/a.svg'), raw('heroes/b.webp'), raw('heroes/c.png')],
    });
    const category = manifest.categories[0]!;
    expect(category.representativeAsset.path).toBe('heroes/b.webp');
    expect(category.extensions).toEqual(['png', 'svg', 'webp']);
    expect(filterGameAssets(category.assets, { query: ' C.PNG ', extension: 'png' })).toHaveLength(
      1,
    );
    expect(filterGameAssets(category.assets, { query: 'missing' })).toEqual([]);
  });

  it('uses building parent folder names for tiles and decodes hosted filenames', () => {
    const asset = GameAsset.fromJson({
      ...raw('buildings/home-village/town_hall/level_2.png'),
      display_name: 'level_2',
      url: 'https://assets.test/buildings/Town%20Hall.png',
    });
    expect(asset.tileDisplayName).toBe('Town Hall · Level 2');
    expect(asset.fileName).toBe('Town Hall.png');
    expect(formatGameAssetCategory('capital_house-parts')).toBe('Capital House Parts');
  });
});
