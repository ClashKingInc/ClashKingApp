import 'dart:convert';

import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/upgrade_tracker/data/upgrade_tracker_parser.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpgradeTrackerRepository {
  UpgradeTrackerRepository({
    UpgradeTrackerParser parser = const UpgradeTrackerParser(),
    // Retained for callers created before freshness moved to app startup.
    bool checkStaticDataFreshness = false,
  }) : _parser = parser;

  static const _snapshotPrefix = 'upgrade_tracker_snapshot_v1_';
  static const _snapshotIndexKey = 'upgrade_tracker_snapshot_index_v1';
  static const _preferencesPrefix = 'upgrade_tracker_preferences_v2_';

  final UpgradeTrackerParser _parser;

  Future<UpgradeTrackerSnapshot?> load(String playerTag) async {
    await _ensureStaticData();
    final normalized = normalizeTag(playerTag);
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('$_snapshotPrefix$normalized');
    if (saved != null) {
      final decoded = jsonDecode(saved);
      if (decoded is Map) {
        return _parser.parse(Map<String, dynamic>.from(decoded));
      }
    }
    return null;
  }

  Future<void> saveRawSnapshot(
    String playerTag,
    Map<String, dynamic> snapshot,
  ) async {
    final normalized = normalizeTag(playerTag);
    if (normalized.isEmpty) {
      throw const FormatException('Account JSON must include a player tag');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_snapshotPrefix$normalized', jsonEncode(snapshot));
    final parsed = _parser.parse(snapshot);
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
    await saveRawSnapshot(tag, raw);
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
      final saved = prefs.getString(
        '$_snapshotPrefix${normalizeTag(playerTag)}',
      );
      if (saved == null) continue;
      final decoded = jsonDecode(saved);
      if (decoded is Map) {
        snapshots.add(_parser.parse(Map<String, dynamic>.from(decoded)));
      }
    }
    return snapshots;
  }

  Future<Map<String, dynamic>?> loadPlanPreferences(String playerTag) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(
      '$_preferencesPrefix${normalizeTag(playerTag)}',
    );
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_preferencesPrefix${normalizeTag(playerTag)}',
      jsonEncode({
        'gold_pass_percent': goldPassPercent,
        'strategy': strategy,
        'heuristics': preferences.toJson(),
      }),
    );
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
