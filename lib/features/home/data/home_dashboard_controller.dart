import 'package:clashkingapp/features/home/data/home_dashboard_service.dart';
import 'package:clashkingapp/features/home/models/home_dashboard_models.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:flutter/foundation.dart';

class HomeDashboardController extends ChangeNotifier {
  HomeDashboardController({HomeDashboardService? service})
    : _service = service ?? HomeDashboardService();

  final HomeDashboardService _service;
  bool _lastLoginAttemptedThisLaunch = false;
  bool _priorLoginCapturedThisLaunch = false;
  bool _loading = false;
  bool _loaded = false;
  Object? _error;
  DateTime? _priorLastLogin;
  List<HomeActivityItem> _activity = const [];
  Map<String, HomeUpgradeRecord> _upgrades = const {};
  Set<String> _upgradeFailures = const {};

  bool get loading => _loading;
  bool get loaded => _loaded;
  Object? get error => _error;
  DateTime? get priorLastLogin => _priorLastLogin;
  List<HomeActivityItem> get activity => _activity;
  Map<String, HomeUpgradeRecord> get upgrades => _upgrades;
  Set<String> get upgradeFailures => _upgradeFailures;

  Future<void> load({
    required String accountId,
    required List<Map<String, dynamic>> linkedAccounts,
    required List<Player> players,
  }) async {
    final verified = linkedAccounts
        .where((account) => account['is_verified'] == true)
        .toList(growable: false);
    if (verified.isEmpty) {
      _loading = false;
      _loaded = true;
      _error = null;
      _activity = const [];
      _upgrades = const {};
      _upgradeFailures = const {};
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    final playersByTag = {
      for (final player in players) _normalizeTag(player.tag): player,
    };
    if (!_priorLoginCapturedThisLaunch) {
      _priorLoginCapturedThisLaunch = true;
      _priorLastLogin = _latestPriorLogin(verified);
    }
    final mappings = verified
        .map((account) {
          final playerTag = account['player_tag']?.toString() ?? '';
          final clanTag = playersByTag[_normalizeTag(playerTag)]?.clanTag
              .trim();
          return <String, Object?>{
            'player_tag': playerTag,
            'clan_tag': clanTag == null || clanTag.isEmpty ? null : clanTag,
          };
        })
        .toList(growable: false);

    try {
      final response = await _service.getActivity(
        accountId: accountId,
        mappings: mappings,
      );
      final upgradeRecords = <String, HomeUpgradeRecord>{};
      final upgradeFailures = <String>{};
      await Future.wait(
        verified.map((account) async {
          final tag = account['player_tag']?.toString() ?? '';
          try {
            final record = await _service.getUpgrades(
              accountId: accountId,
              playerTag: tag,
            );
            upgradeRecords[_normalizeTag(tag)] = record;
          } catch (_) {
            upgradeFailures.add(_normalizeTag(tag));
          }
        }),
      );

      _activity = response.items;
      _upgrades = Map.unmodifiable(upgradeRecords);
      _upgradeFailures = Set.unmodifiable(upgradeFailures);
      _loaded = true;
      _loading = false;
      notifyListeners();

      if (!_lastLoginAttemptedThisLaunch) {
        _lastLoginAttemptedThisLaunch = true;
        try {
          await _service.updateLastLogin(accountId);
        } catch (_) {
          // Home content remains usable. The next cold launch gets one new
          // attempt, while this launch keeps the original comparison point.
        }
      }
    } catch (error) {
      _error = error;
      _loading = false;
      _loaded = false;
      notifyListeners();
    }
  }

  static String normalizeTag(String value) => _normalizeTag(value);

  static DateTime? _latestPriorLogin(List<Map<String, dynamic>> accounts) {
    DateTime? latest;
    for (final account in accounts) {
      final raw = account['last_login'] ?? account['lastLogin'];
      final parsed = DateTime.tryParse(raw?.toString() ?? '')?.toUtc();
      if (parsed != null && (latest == null || parsed.isAfter(latest))) {
        latest = parsed;
      }
    }
    return latest;
  }

  static String _normalizeTag(String value) =>
      value.replaceAll('#', '').trim().toUpperCase();
}
