import 'dart:convert';

import 'package:clashkingapp/features/achievements/data/achievement_model_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'downloads each model once and reuses its in-memory data source',
    () async {
      var requests = 0;
      final cache = AchievementModelCache(
        client: MockClient((request) async {
          requests++;
          return http.Response.bytes(<int>[1, 2, 3, 4], 200);
        }),
      );

      final sources = await Future.wait([
        cache.resolve('https://assets.example/badge.glb'),
        cache.resolve('https://assets.example/badge.glb'),
      ]);
      final reopened = await cache.resolve('https://assets.example/badge.glb');

      expect(requests, 1);
      expect(sources[0], sources[1]);
      expect(reopened, sources[0]);
      expect(
        sources[0],
        'data:model/gltf-binary;base64,${base64Encode(<int>[1, 2, 3, 4])}',
      );
      expect(cache.peek('https://assets.example/badge.glb'), sources[0]);
    },
  );

  test('falls back to the remote URL when preloading fails', () async {
    final cache = AchievementModelCache(
      client: MockClient((request) async => http.Response('', 503)),
    );
    const url = 'https://assets.example/badge.glb';

    expect(await cache.resolve(url), url);
  });

  test('falls back to the remote URL when the download times out', () async {
    final cache = AchievementModelCache(
      timeout: const Duration(milliseconds: 1),
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return http.Response('', 200);
      }),
    );

    expect(
      await cache.resolve('https://assets.example/slow-badge.glb'),
      'https://assets.example/slow-badge.glb',
    );
  });
}
