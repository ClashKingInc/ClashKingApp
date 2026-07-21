import 'dart:convert';

import 'package:clashkingapp/features/game_assets/models/game_asset_manifest.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class GameAssetManifestRepository {
  Future<GameAssetManifest> load({bool forceRefresh = false});
}

class GameAssetManifestService implements GameAssetManifestRepository {
  GameAssetManifestService({
    http.Client? client,
    GameAssetManifestCache? cache,
    DateTime Function()? now,
    this.cacheDuration = const Duration(minutes: 30),
    this.requestTimeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       _cache = cache ?? SharedPreferencesGameAssetManifestCache(),
       _now = now ?? DateTime.now;

  static final GameAssetManifestService shared = GameAssetManifestService();
  static final Uri manifestUri = Uri.parse(
    'https://assets.clashk.ing/manifest.json',
  );

  final http.Client _client;
  final GameAssetManifestCache _cache;
  final DateTime Function() _now;
  final Duration cacheDuration;
  final Duration requestTimeout;

  GameAssetManifest? _memoryManifest;
  DateTime? _memoryFetchedAt;

  @override
  Future<GameAssetManifest> load({bool forceRefresh = false}) async {
    final now = _now();
    if (!forceRefresh &&
        _memoryManifest != null &&
        _isFresh(_memoryFetchedAt, now)) {
      return _memoryManifest!;
    }

    CachedGameAssetManifest? cached;
    try {
      cached = await _cache.read();
      if (!forceRefresh && cached != null && _isFresh(cached.fetchedAt, now)) {
        return _remember(_decode(cached.json), cached.fetchedAt);
      }
    } catch (_) {
      await _discardInvalidCache();
      cached = null;
    }

    try {
      final response = await _client.get(manifestUri).timeout(requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GameAssetManifestLoadException(
          'Manifest request failed (${response.statusCode})',
        );
      }

      final rawJson = utf8.decode(response.bodyBytes);
      final manifest = _decode(rawJson);
      final fetchedAt = _now();
      _remember(manifest, fetchedAt);
      try {
        await _cache.write(
          CachedGameAssetManifest(json: rawJson, fetchedAt: fetchedAt),
        );
      } catch (_) {
        // Cache persistence is best effort after a successful network load.
      }
      return manifest;
    } catch (error) {
      final memoryManifest = _memoryManifest;
      if (memoryManifest != null) return memoryManifest;
      if (cached != null) {
        try {
          return _remember(_decode(cached.json), cached.fetchedAt);
        } catch (_) {
          await _discardInvalidCache();
        }
      }
      if (error is GameAssetManifestLoadException) rethrow;
      throw GameAssetManifestLoadException(
        'Could not load the game asset manifest',
        cause: error,
      );
    }
  }

  bool _isFresh(DateTime? fetchedAt, DateTime now) {
    return fetchedAt != null && now.difference(fetchedAt) <= cacheDuration;
  }

  GameAssetManifest _remember(GameAssetManifest manifest, DateTime fetchedAt) {
    _memoryManifest = manifest;
    _memoryFetchedAt = fetchedAt;
    return manifest;
  }

  GameAssetManifest _decode(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) {
      throw const FormatException('Game asset manifest must be an object');
    }
    return GameAssetManifest.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> _discardInvalidCache() async {
    try {
      await _cache.clear();
    } catch (_) {
      // A broken cache must not prevent a fresh network request.
    }
  }
}

class GameAssetManifestLoadException implements Exception {
  const GameAssetManifestLoadException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class CachedGameAssetManifest {
  const CachedGameAssetManifest({required this.json, required this.fetchedAt});

  final String json;
  final DateTime fetchedAt;
}

abstract interface class GameAssetManifestCache {
  Future<CachedGameAssetManifest?> read();

  Future<void> write(CachedGameAssetManifest manifest);

  Future<void> clear();
}

class SharedPreferencesGameAssetManifestCache
    implements GameAssetManifestCache {
  static const _jsonKey = 'game_asset_manifest_v1';
  static const _fetchedAtKey = 'game_asset_manifest_v1_fetched_at';

  @override
  Future<CachedGameAssetManifest?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final json = preferences.getString(_jsonKey);
    final fetchedAt = preferences.getInt(_fetchedAtKey);
    if (json == null || fetchedAt == null) return null;
    return CachedGameAssetManifest(
      json: json,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(fetchedAt),
    );
  }

  @override
  Future<void> write(CachedGameAssetManifest manifest) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_jsonKey, manifest.json);
    await preferences.setInt(
      _fetchedAtKey,
      manifest.fetchedAt.millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_jsonKey);
    await preferences.remove(_fetchedAtKey);
  }
}
