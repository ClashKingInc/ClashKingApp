import 'package:clashkingapp/features/game_assets/data/game_asset_manifest_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final now = DateTime.utc(2026, 7, 21, 4);

  test('fetches a mocked manifest once and reuses the memory cache', () async {
    var requests = 0;
    final cache = _MemoryManifestCache();
    final service = GameAssetManifestService(
      client: MockClient((request) async {
        requests++;
        expect(request.url, GameAssetManifestService.manifestUri);
        return http.Response(_manifestJson, 200);
      }),
      cache: cache,
      now: () => now,
    );

    final first = await service.load();
    final second = await service.load();

    expect(first.assets.single.displayName, 'Archer');
    expect(identical(first, second), isTrue);
    expect(requests, 1);
    expect(cache.value?.json, _manifestJson);
  });

  test('uses a fresh persistent cache without a network request', () async {
    var requests = 0;
    final service = GameAssetManifestService(
      client: MockClient((_) async {
        requests++;
        return http.Response('', 500);
      }),
      cache: _MemoryManifestCache(
        CachedGameAssetManifest(
          json: _manifestJson,
          fetchedAt: now.subtract(const Duration(minutes: 5)),
        ),
      ),
      now: () => now,
    );

    final manifest = await service.load();

    expect(manifest.categories.single.id, 'troops');
    expect(requests, 0);
  });

  test('falls back to a stale valid cache when refresh fails', () async {
    final service = GameAssetManifestService(
      client: MockClient((_) async => http.Response('not found', 404)),
      cache: _MemoryManifestCache(
        CachedGameAssetManifest(
          json: _manifestJson,
          fetchedAt: now.subtract(const Duration(hours: 2)),
        ),
      ),
      now: () => now,
    );

    final manifest = await service.load();

    expect(manifest.assets.single.path, 'troops/archer.webp');
  });

  test('surfaces a typed load error when no cache is available', () async {
    final service = GameAssetManifestService(
      client: MockClient((_) async => http.Response('not found', 404)),
      cache: _MemoryManifestCache(),
      now: () => now,
    );

    expect(service.load(), throwsA(isA<GameAssetManifestLoadException>()));
  });

  test(
    'returns a valid network response when cache persistence fails',
    () async {
      final service = GameAssetManifestService(
        client: MockClient((_) async => http.Response(_manifestJson, 200)),
        cache: _MemoryManifestCache()..throwOnWrite = true,
        now: () => now,
      );

      final manifest = await service.load();

      expect(manifest.assets.single.displayName, 'Archer');
    },
  );
}

const _manifestJson = '''
{
  "version": 1,
  "assets": [
    {
      "path": "troops/archer.webp",
      "category": "troops",
      "display_name": "Archer",
      "extension": "webp",
      "url": "https://assets.clashk.ing/troops/archer.webp"
    }
  ]
}
''';

class _MemoryManifestCache implements GameAssetManifestCache {
  _MemoryManifestCache([this.value]);

  CachedGameAssetManifest? value;
  var throwOnWrite = false;

  @override
  Future<void> clear() async {
    value = null;
  }

  @override
  Future<CachedGameAssetManifest?> read() async => value;

  @override
  Future<void> write(CachedGameAssetManifest manifest) async {
    if (throwOnWrite) throw StateError('cache unavailable');
    value = manifest;
  }
}
