import 'dart:convert';

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/upgrade_tracker/data/upgrade_tracker_parser.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpgradeTrackerRepository {
  // Shared app-wide so accounts fetched once (e.g. at startup, or by the
  // Home dashboard) stay warm in memory for every other screen.
  static final UpgradeTrackerRepository shared = UpgradeTrackerRepository();

  UpgradeTrackerRepository({
    UpgradeTrackerParser parser = const UpgradeTrackerParser(),
    ApiService? apiService,
    // Retained for callers created before freshness moved to app startup.
    bool checkStaticDataFreshness = false,
  }) : _parser = parser,
       _apiService = apiService ?? ApiService.shared;

  static const _snapshotPrefix = 'upgrade_tracker_snapshot_v1_';
  static const _snapshotIndexKey = 'upgrade_tracker_snapshot_index_v1';
  static const _preferencesPrefix = 'upgrade_tracker_preferences_v2_';

  final UpgradeTrackerParser _parser;
  final ApiService _apiService;
  final Map<String, UpgradeTrackerSnapshot> _snapshotCache = {};
  String? _remoteAccountId;
  Set<String> _verifiedRemoteTags = const {};

  void configureRemote({
    required String? accountId,
    required Iterable<String> verifiedPlayerTags,
  }) {
    final normalizedId = accountId?.trim();
    _remoteAccountId = normalizedId == null || normalizedId.isEmpty
        ? null
        : normalizedId;
    _verifiedRemoteTags = verifiedPlayerTags
        .map(normalizeTag)
        .where((tag) => tag.isNotEmpty)
        .toSet();
  }

  Future<UpgradeTrackerSnapshot?> load(String playerTag) async {
    await _ensureStaticData();
    final normalized = normalizeTag(playerTag);
    if (_remoteAccountId != null && _verifiedRemoteTags.contains(normalized)) {
      try {
        final remote = await _loadRemoteSnapshot(normalized);
        if (remote != null) {
          final parsed = _parser.parse(remote);
          await _saveRawSnapshotLocally(
            normalized,
            remote,
            parsedSnapshot: parsed,
          );
          return parsed;
        }
      } catch (_) {
        // The on-device copy remains a deliberate offline fallback.
      }
    }
    final cached = _snapshotCache[normalized];
    if (cached != null) return cached;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('$_snapshotPrefix$normalized');
    if (saved != null) {
      final decoded = jsonDecode(saved);
      if (decoded is Map) {
        final parsed = _parser.parse(Map<String, dynamic>.from(decoded));
        _snapshotCache[normalized] = parsed;
        return parsed;
      }
    }
    return null;
  }

  Future<void> saveRawSnapshot(
    String playerTag,
    Map<String, dynamic> snapshot, {
    UpgradeTrackerSnapshot? parsedSnapshot,
  }) async {
    final normalized = normalizeTag(playerTag);
    if (normalized.isEmpty) {
      throw const FormatException('Account JSON must include a player tag');
    }
    await _replaceRemoteSnapshot(normalized, snapshot);
    await _saveRawSnapshotLocally(
      normalized,
      snapshot,
      parsedSnapshot: parsedSnapshot,
    );
  }

  Future<void> _saveRawSnapshotLocally(
    String normalized,
    Map<String, dynamic> snapshot, {
    UpgradeTrackerSnapshot? parsedSnapshot,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_snapshotPrefix$normalized', jsonEncode(snapshot));
    final parsed = parsedSnapshot ?? _parser.parse(snapshot);
    _snapshotCache[normalized] = parsed;
    final accounts = await savedSnapshotAccounts();
    final next = <String, Map<String, String>>{
      for (final account in accounts) account['tag']!: account,
      normalized: {
        'tag': normalized,
        'name': snapshot['name']?.toString().trim().isNotEmpty == true
            ? snapshot['name'].toString()
            : 'Imported player',
        'townHallLevel': parsed.townHallLevel.toString(),
        'builderHallLevel': parsed.builderHallLevel.toString(),
        'capturedAt': parsed.capturedAt.toUtc().toIso8601String(),
      },
    }.values.toList(growable: false);
    await prefs.setString(_snapshotIndexKey, jsonEncode(next));
  }

  Future<UpgradeTrackerSnapshot> importSnapshotBytes(
    List<int> bytes, {
    Map<String, String> linkedNamesByTag = const {},
    Set<String> allowedTags = const {},
  }) async {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) {
      throw const FormatException('Account JSON must be one JSON object');
    }
    final raw = _unwrapSnapshot(Map<String, dynamic>.from(decoded));
    final tag = normalizeTag(raw['tag']?.toString() ?? '');
    if (tag.isEmpty) {
      throw const FormatException('Account JSON is missing its player tag');
    }
    final normalizedAllowed = allowedTags
        .map(normalizeTag)
        .where((value) => value.isNotEmpty)
        .toSet();
    if (!normalizedAllowed.contains(tag)) {
      throw const FormatException(
        'This JSON does not match one of your linked accounts',
      );
    }
    raw['tag'] = tag;
    final normalizedLinkedNames = {
      for (final entry in linkedNamesByTag.entries)
        normalizeTag(entry.key): entry.value,
    };
    final linkedName = normalizedLinkedNames[tag];
    if (linkedName != null && linkedName.trim().isNotEmpty) {
      raw['name'] = linkedName.trim();
    }
    await _ensureStaticData();
    final parsed = _parser.parse(raw);
    if (parsed.townHallLevel == 0 && parsed.builderHallLevel == 0) {
      throw const FormatException(
        'This does not look like a raw Clash account snapshot',
      );
    }
    await saveRawSnapshot(tag, raw, parsedSnapshot: parsed);
    return parsed;
  }

  Future<List<Map<String, String>>> savedSnapshotAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_snapshotIndexKey);
    if (encoded == null) return const [];
    final decoded = jsonDecode(encoded);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((value) => Map<String, String>.from(value))
        .where((value) => value['tag']?.isNotEmpty == true)
        .toList(growable: false);
  }

  Future<List<UpgradeTrackerSnapshot>> loadSavedSnapshots(
    Iterable<String> playerTags,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final snapshots = <UpgradeTrackerSnapshot>[];
    for (final playerTag in playerTags) {
      final normalized = normalizeTag(playerTag);
      final cached = _snapshotCache[normalized];
      if (cached != null) {
        snapshots.add(cached);
        continue;
      }
      final saved = prefs.getString('$_snapshotPrefix$normalized');
      if (saved == null) continue;
      final decoded = jsonDecode(saved);
      if (decoded is Map) {
        final parsed = _parser.parse(Map<String, dynamic>.from(decoded));
        _snapshotCache[normalized] = parsed;
        snapshots.add(parsed);
      }
    }
    return snapshots;
  }

  Future<Map<String, dynamic>?> loadPlanPreferences(String playerTag) async {
    final normalized = normalizeTag(playerTag);
    if (_remoteAccountId != null && _verifiedRemoteTags.contains(normalized)) {
      try {
        final response = await _apiService.getResponse(
          _remoteEndpoint(normalized, 'upgrade-preferences'),
          requiresAuth: true,
        );
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(ApiService.decodeResponseBody(response));
          if (decoded is Map && decoded['preferences'] is Map) {
            final remote = Map<String, dynamic>.from(
              decoded['preferences'] as Map,
            );
            await _savePlanPreferencesLocally(normalized, remote);
            return remote;
          }
        }
      } catch (_) {
        // Fall through to the last on-device preferences.
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString('$_preferencesPrefix$normalized');
    if (encoded == null) return null;
    final decoded = jsonDecode(encoded);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }

  Future<void> savePlanPreferences(
    String playerTag, {
    required int goldPassPercent,
    required String strategy,
    UpgradePlanPreferences preferences = const UpgradePlanPreferences(),
  }) async {
    final normalized = normalizeTag(playerTag);
    final value = <String, dynamic>{
      'gold_pass_percent': goldPassPercent,
      'strategy': strategy,
      'heuristics': preferences.toJson(),
    };
    final accountId = _remoteAccountId;
    if (accountId != null) {
      _requireVerifiedRemoteTag(normalized);
      final response = await _apiService.patchResponse(
        _remoteEndpoint(normalized, 'upgrade-preferences'),
        body: {'preferences': value},
        requiresAuth: true,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'Could not save upgrade preferences (${response.statusCode})',
        );
      }
    }
    await _savePlanPreferencesLocally(normalized, value);
  }

  Future<Map<String, dynamic>?> _loadRemoteSnapshot(String normalized) async {
    final response = await _apiService.getResponse(
      _remoteEndpoint(normalized, 'upgrades'),
      requiresAuth: true,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final decoded = jsonDecode(ApiService.decodeResponseBody(response));
    if (decoded is! Map || decoded['data'] is! Map) return null;
    final data = Map<String, dynamic>.from(decoded['data'] as Map);
    return data.isEmpty ? null : data;
  }

  Future<void> _replaceRemoteSnapshot(
    String normalized,
    Map<String, dynamic> snapshot,
  ) async {
    final accountId = _remoteAccountId;
    if (accountId == null) return;
    _requireVerifiedRemoteTag(normalized);
    final response = await _apiService.putResponse(
      _remoteEndpoint(normalized, 'upgrades'),
      body: {'data': snapshot},
      requiresAuth: true,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Could not save upgrade data (${response.statusCode})');
    }
  }

  Future<void> _savePlanPreferencesLocally(
    String normalized,
    Map<String, dynamic> value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_preferencesPrefix$normalized', jsonEncode(value));
  }

  String _remoteEndpoint(String playerTag, String resource) =>
      '/links/${Uri.encodeComponent(_remoteAccountId!)}/${Uri.encodeComponent(playerTag)}/$resource';

  void _requireVerifiedRemoteTag(String tag) {
    if (!_verifiedRemoteTags.contains(tag)) {
      throw StateError('Upgrade data is limited to verified linked accounts');
    }
  }

  static String normalizeTag(String value) {
    final tag = value.replaceAll('#', '').trim().toUpperCase();
    return tag.isEmpty ? '' : '#$tag';
  }

  static Map<String, dynamic> _unwrapSnapshot(Map<String, dynamic> decoded) {
    if (decoded['tag'] != null) return decoded;
    for (final key in const ['player', 'account', 'data', 'snapshot']) {
      final nested = decoded[key];
      if (nested is Map && nested['tag'] != null) {
        return Map<String, dynamic>.from(nested);
      }
    }
    return decoded;
  }

  Future<void> _ensureStaticData() async {
    if (GameDataService.bundleData.isEmpty) {
      throw StateError('Static game data was not loaded during app startup');
    }
  }
}
