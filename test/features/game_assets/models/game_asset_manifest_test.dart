import 'package:clashkingapp/features/game_assets/models/game_asset_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameAssetManifest', () {
    test('decodes, sorts, and groups the typed v1 contract', () {
      final manifest = GameAssetManifest.fromJson({
        'version': 1,
        'assets': [
          _assetJson(
            path: 'troops/wizard.webp',
            category: 'troops',
            name: 'Wizard',
          ),
          _assetJson(
            path: 'capital_house_parts/roof.png',
            category: 'capital_house_parts',
            name: 'Roof',
            extension: 'png',
          ),
          _assetJson(
            path: 'troops/archer.svg',
            category: 'troops',
            name: 'Archer',
            extension: 'svg',
          ),
        ],
      });

      expect(manifest.version, 1);
      expect(manifest.assets.map((asset) => asset.path), [
        'capital_house_parts/roof.png',
        'troops/archer.svg',
        'troops/wizard.webp',
      ]);
      expect(manifest.categories.map((category) => category.id), [
        'capital_house_parts',
        'troops',
      ]);
      expect(manifest.categories.last.count, 2);
      expect(manifest.categories.last.extensions, ['svg', 'webp']);
      expect(manifest.assets.last.fileName, 'wizard.webp');
    });

    test('rejects unsupported or inconsistent entries', () {
      expect(
        () => GameAssetManifest.fromJson({
          'version': 1,
          'assets': [
            _assetJson(
              path: 'troops/readme.txt',
              category: 'troops',
              name: 'Readme',
              extension: 'txt',
            ),
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => GameAssetManifest.fromJson({
          'version': 1,
          'assets': [
            _assetJson(
              path: 'troops/archer.png',
              category: 'heroes',
              name: 'Archer',
              extension: 'png',
            ),
          ],
        }),
        throwsFormatException,
      );
    });
  });

  test('category labels and asset filters are deterministic', () {
    final assets = [
      GameAsset(
        path: 'country-flags/united_states.png',
        category: 'country-flags',
        displayName: 'United States',
        extension: 'png',
        url: Uri.parse(
          'https://assets.clashk.ing/country-flags/united_states.png',
        ),
      ),
      GameAsset(
        path: 'country-flags/united_kingdom.svg',
        category: 'country-flags',
        displayName: 'United Kingdom',
        extension: 'svg',
        url: Uri.parse(
          'https://assets.clashk.ing/country-flags/united_kingdom.svg',
        ),
      ),
    ];

    expect(
      formatGameAssetCategory('capital_house-parts'),
      'Capital House Parts',
    );
    expect(
      filterGameAssets(assets, query: 'king', extension: 'svg').single.path,
      'country-flags/united_kingdom.svg',
    );
    expect(filterGameAssets(assets, query: 'missing'), isEmpty);
  });
}

Map<String, dynamic> _assetJson({
  required String path,
  required String category,
  required String name,
  String extension = 'webp',
}) {
  return {
    'path': path,
    'category': category,
    'display_name': name,
    'extension': extension,
    'url': 'https://assets.clashk.ing/$path',
  };
}
