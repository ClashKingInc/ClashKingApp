import { validateAssetManifest } from './asset-manifest';

const valid = () => ({ version: 2, assets: { buildings: [{ path: 'buildings/a.webp',
  sha: 'a'.repeat(64), animated: false }] }, data: { stats: [{ path: 'static_data/troops.json', sha: 'b'.repeat(64) }], translations: [] } });
test('reads category lists using full paths without redundant URL or extension', () => {
  expect(validateAssetManifest(valid()).get('buildings/a.webp')).toEqual({ sha: 'a'.repeat(64), animated: false });
});
test('requires separate data lists with the correct path families', () => {
  const manifest = valid();
  expect(() => validateAssetManifest({ ...manifest, data: manifest.data.stats })).toThrow();
  expect(() => validateAssetManifest({ ...manifest, data: { stats: manifest.data.stats, translations: manifest.data.stats } })).toThrow();
  expect(() => validateAssetManifest({ ...manifest, data: { stats: [...manifest.data.stats, ...manifest.data.stats], translations: [] } })).toThrow();
});
test('rejects old schema, object categories, duplicate and unsafe paths', () => {
  expect(() => validateAssetManifest({ ...valid(), version: 1 })).toThrow();
  expect(() => validateAssetManifest({ ...valid(), assets: [] })).toThrow();
  expect(() => validateAssetManifest({ ...valid(), assets: { buildings: {} } })).toThrow();
  const duplicate = valid();
  duplicate.assets.buildings.push(duplicate.assets.buildings[0]!);
  expect(() => validateAssetManifest(duplicate)).toThrow();
  const unsafe = valid();
  unsafe.assets.buildings[0]!.path = 'buildings/../a.webp';
  expect(() => validateAssetManifest(unsafe)).toThrow();
});
