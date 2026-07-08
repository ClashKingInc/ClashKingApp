import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/player/models/war_stats_filter.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class PlayerService extends ChangeNotifier {
  PlayerService({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  final ApiService _apiService;
  bool _isLoading = false;
  List<Player> _profiles = [];
  List<Map<String, dynamic>> _clans = [];

  bool get isLoading => _isLoading;
  List<Player> get profiles => _profiles;
  List<Map<String, dynamic>> get clans => _clans;

  Player? getSelectedProfile(CocAccountService cocAccountService) {
    String? selectedTag = cocAccountService.selectedTag;
    DebugUtils.debugInfo("🔍 SelectedTag: $selectedTag");
    DebugUtils.debugInfo(
      "📊 Available profiles: ${profiles.map((p) => p.tag).toList()}",
    );

    if (selectedTag == null) return null;
    try {
      return profiles.firstWhere((profile) => profile.tag == selectedTag);
    } catch (e) {
      DebugUtils.debugWarning("⚠️ Profile not found for tag: $selectedTag");
      return null;
    }
  }

  Future<void> loadPublicPlayerData(
    List<String> playerTags, {
    bool notify = true,
  }) async {
    await loadOfficialPlayerData(playerTags, notify: notify);
  }

  Future<Map<String, String>> loadOfficialPlayerData(
    List<String> playerTags, {
    bool notify = true,
    bool throwOnError = false,
  }) async {
    _isLoading = true;
    if (notify) {
      _safeNotify();
    }

    final clanTagsByPlayer = <String, String>{};

    try {
      final loadedProfiles = await Future.wait(
        playerTags.map((rawTag) async {
          final playerTag = _canonicalTag(rawTag);
          if (playerTag.isEmpty) return null;
          try {
            final player = await _fetchOfficialPlayer(playerTag);
            final clanTag = player.clanOverview.tag;
            if (clanTag.isNotEmpty) {
              clanTagsByPlayer[player.tag] = clanTag;
              await storePrefs('player_${player.tag}_clan_tag', clanTag);
            }
            return player;
          } catch (e) {
            DebugUtils.debugWarning(
              "⚠️ Failed to load official player profile for $playerTag: $e",
            );
            if (throwOnError) {
              rethrow;
            }
            return null;
          }
        }),
      );

      final profiles = loadedProfiles.whereType<Player>().toList();
      final loadedTags = profiles.map((player) => player.tag).toSet();
      final preserved = _profiles.where(
        (player) => !loadedTags.contains(player.tag),
      );
      _profiles = [...profiles, ...preserved];
      DebugUtils.debugSuccess(
        "Loaded public player profiles: ${_profiles.map((p) => p.tag).toList()}",
      );
      return clanTagsByPlayer;
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError(" Error loading official player data: $e");
      if (throwOnError) {
        rethrow;
      }
      return clanTagsByPlayer;
    } finally {
      _isLoading = false;
      if (notify) {
        _safeNotify();
      }
    }
  }

  Future<Player> _fetchOfficialPlayer(String playerTag) async {
    final encodedTag = Uri.encodeComponent(playerTag);
    final response = await _apiService.proxyGet('/players/$encodedTag');

    if (response.statusCode != 200) {
      throw HttpException(
        "Failed to fetch player data (${response.statusCode})",
        uri: response.request?.url,
      );
    }

    final data =
        jsonDecode(ApiService.decodeResponseBody(response))
            as Map<String, dynamic>;
    return Player.fromJson(data);
  }

  static String _canonicalTag(String tag) {
    final normalized = tag.trim().toUpperCase();
    if (normalized.isEmpty || normalized.startsWith('#')) {
      return normalized;
    }
    return '#$normalized';
  }

  /// Init basic stats for the saved accounts.
  Future<Map<String, String>> initPlayerData(
    List<String> playerTags, { // NOSONAR
    bool notify = true,
    bool throwOnError = false,
  }) async {
    return loadOfficialPlayerData(
      playerTags,
      notify: notify,
      throwOnError: throwOnError,
    );
  }

  /// Loads all stats for the saved accounts.
  Future<void> loadPlayerData(
    // NOSONAR
    List<String> playerTags,
    Map<String, String> clanTagsByPlayer, {
    bool notify = true,
    bool throwOnError = false,
  }) async {
    await loadOfficialPlayerData(
      playerTags,
      notify: notify,
      throwOnError: throwOnError,
    );
  }

  Future<Player> getPlayerAndClanData(String playerTag) async {
    // NOSONAR
    _isLoading = true;
    _safeNotify();

    try {
      final normalizedTag = _canonicalTag(playerTag);
      await loadOfficialPlayerData(
        [normalizedTag],
        notify: false,
        throwOnError: true,
      );
      final player = _profiles.firstWhere((p) => p.tag == normalizedTag);

      DebugUtils.debugSuccess(
        "Successfully loaded player: ${player.name} (${player.tag})",
      );
      return player;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      DebugUtils.debugError(" Error in getPlayerAndClanData: $e");
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Hydrates full profiles for bookmarked player tags in parallel (each
  /// failure is swallowed independently so one bad tag doesn't block the
  /// rest - the local bookmark snapshot stays visible for it instead).
  Future<void> hydrateBookmarkedPlayers(List<String> tags) async {
    await Future.wait(
      tags.map((tag) async {
        try {
          await getPlayerAndClanData(tag);
        } catch (_) {
          // Keep the local bookmark snapshot visible if the full profile
          // cannot load.
        }
      }),
    );
  }

  void linkClansToPlayer(List<Player> players, List<Clan> clans) {
    final clansByTag = {for (final clan in clans) clan.tag: clan};
    for (var profile in players) {
      if (profile.clanTag.isEmpty) continue;
      final clan = clansByTag[profile.clanTag];
      if (clan != null) {
        profile.clan = clan;
        DebugUtils.debugInfo(
          "🔗 Linked ${profile.tag} to ${profile.clan?.name}",
        );
      }
    }
  }

  Future<void> loadPlayerWarStats(
    List<String> playerTags, { // NOSONAR
    bool notify = true,
    bool throwOnError = false,
  }) async {
    DebugUtils.debugApi("🏰 Loading player data for tags: $playerTags");

    try {
      final response = await _apiService.postResponse(
        '/war/players/warhits',
        body: {"player_tags": playerTags, "limit": 50},
        requiresAuth: true,
      );
      if (response.statusCode == 200) {
        final responseBody = ApiService.decodeResponseBody(response);
        final data = jsonDecode(responseBody);

        if (data.containsKey("items") && data["items"] is List) {
          final profilesByTag = {
            for (final player in _profiles) player.tag: player,
          };
          for (final item in data["items"]) {
            final String tag = item["tag"];
            try {
              final player = profilesByTag[tag];
              if (player == null) {
                continue;
              }
              player.warStats = PlayerWarStats.fromJson(
                item,
                tag,
                data["wars"],
              );
            } catch (e) {
              DebugUtils.debugError(" Error loading war stats for $tag: $e");
              continue;
            }
          }
          DebugUtils.debugSuccess(
            "Loaded & linked war stats for $playerTags players",
          );
        } else {
          Sentry.captureMessage(
            "Error loading war stats: $data",
            level: SentryLevel.error,
          );
        }
      } else {
        Sentry.captureMessage(
          "Error loading war stats",
          level: SentryLevel.error,
        );
        throw Exception("Error loading war stats");
      }
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError(" Error loading war stats: $e");
      if (throwOnError) {
        rethrow;
      }
    } finally {
      if (notify) {
        _safeNotify();
      }
    }
  }

  /// Load war stats with custom filters
  Future<PlayerWarStats?> loadPlayerWarStatsWithFilter(
    String playerTag,
    WarStatsFilter filter,
  ) async {
    DebugUtils.debugApi("🎯 Loading filtered war stats for: $playerTag");
    DebugUtils.debugInfo("🔍 Filter: ${filter.getFilterSummary()}");

    final requestBody = {
      "player_tags": [playerTag],
      ...filter.toJson(),
    };

    // Debug logging to see what's being sent
    DebugUtils.debugInfo(
      "🔍 War Stats Request Body: ${jsonEncode(requestBody)}",
    );

    try {
      final response = await _apiService.postResponse(
        '/war/players/warhits',
        body: requestBody,
        requiresAuth: true,
      );

      // Debug logging for response
      DebugUtils.debugInfo(
        "📡 War Stats Response Status: ${response.statusCode}",
      );

      if (response.statusCode == 200) {
        final responseBody = ApiService.decodeResponseBody(response);
        final data = jsonDecode(responseBody);

        if (data.containsKey("items") && data["items"] is List) {
          final items = data["items"] as List;
          if (items.isNotEmpty) {
            final item = items.first;
            final String tag = item["tag"];

            if (tag == playerTag) {
              DebugUtils.debugSuccess(
                "✅ Loaded filtered war stats for $playerTag",
              );
              return PlayerWarStats.fromJson(item, tag, data["wars"]);
            }
          }
        }

        DebugUtils.debugWarning(
          "⚠️ No filtered war stats found for $playerTag",
        );
        return null;
      } else {
        DebugUtils.debugError(
          "❌ Failed to load filtered war stats: ${response.statusCode}",
        );
        if (response.statusCode == 422) {
          final errorBody = ApiService.decodeResponseBody(response);
          DebugUtils.debugError("❌ Validation Error Details: $errorBody");
        }
        Sentry.captureMessage(
          "Error loading filtered war stats: ${response.statusCode}",
          level: SentryLevel.error,
        );
        throw Exception("Error loading filtered war stats");
      }
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError("❌ Error loading filtered war stats: $e");
      rethrow;
    }
  }

  String getRoleText(String role, BuildContext context) {
    switch (role) {
      case 'leader':
        return AppLocalizations.of(context)?.clanRoleLeader ?? 'Leader';
      case 'coLeader':
        return AppLocalizations.of(context)?.clanRoleCoLeader ?? 'Co-Leader';
      case 'admin':
        return AppLocalizations.of(context)?.clanRoleElder ?? 'Elder';
      case 'member':
        return AppLocalizations.of(context)?.clanRoleMember ?? 'Member';
      default:
        return 'No clan';
    }
  }

  String getMinimalisticPlayerByTag(String tag) {
    final player = _profiles.cast<Player?>().firstWhere(
      (p) => p?.tag == tag,
      orElse: () => null,
    );
    if (player != null) {
      return jsonEncode({
        "player_tag": player.tag,
        "name": player.name,
        "townHallLevel": player.townHallLevel,
      });
    }
    return "{}";
  }

  Future<void> refreshOfficialPlayerSummary(Player player) async {
    try {
      final encodedTag = Uri.encodeComponent(player.tag);
      final response = await _apiService.proxyGet('/players/$encodedTag');
      if (response.statusCode != 200) {
        DebugUtils.debugWarning(
          "⚠️ Official player summary refresh failed for ${player.tag}: ${response.statusCode}",
        );
        return;
      }

      final data = jsonDecode(ApiService.decodeResponseBody(response));
      if (data is Map<String, dynamic>) {
        player.updateFromOfficialProfile(data);
      }
    } catch (e) {
      DebugUtils.debugWarning(
        "⚠️ Official player summary refresh failed for ${player.tag}: $e",
      );
    }
  }

  /// Process bulk player data from the optimized API endpoint
  void processBulkPlayerData(
    List<dynamic> playersExtended,
    List<dynamic> playersBasic, {
    bool notify = true,
  }) {
    DebugUtils.debugInfo(
      "🔄 Processing bulk player data: ${playersExtended.length} extended, ${playersBasic.length} basic",
    );

    // First, create basic player profiles from basic data
    final linkedProfiles = playersBasic.whereType<Map<String, dynamic>>().map((
      account,
    ) {
      DebugUtils.debugInfo("🔄 Processing basic player: ${account['tag']}");
      final player = Player.fromJson(account);
      if (player.clanOverview.tag.isNotEmpty) {
        // Cache clan tag for widget use
        storePrefs('player_${player.tag}_clan_tag', player.clanOverview.tag);
      }
      return player;
    }).toList();

    // This can run concurrently with hydrateBookmarkedPlayers() at startup
    // (both are kicked off via Future.wait). Replacing _profiles outright
    // would silently drop a bookmarked player added while this was in
    // flight, depending on which finishes last — so keep anything already
    // present that isn't one of this batch's linked accounts.
    final linkedTags = linkedProfiles.map((player) => player.tag).toSet();
    final preserved = _profiles.where(
      (player) => !linkedTags.contains(player.tag),
    );
    _profiles = [...linkedProfiles, ...preserved];

    DebugUtils.debugSuccess(
      "Created ${_profiles.length} basic player profiles",
    );
    final profilesByTag = {
      for (final profile in _profiles) profile.tag: profile,
    };

    // Then enrich with extended data
    for (final extendedData
        in playersExtended.whereType<Map<String, dynamic>>()) {
      final tag = extendedData["tag"];
      try {
        final existing = profilesByTag[tag];
        if (existing == null) {
          DebugUtils.debugWarning(
            "⚠️ Skipping player $tag - not found in basic data and extended data is incomplete",
          );
          continue;
        }
        existing.enrichWithFullStats(extendedData);
        DebugUtils.debugSuccess(
          "Enriched player: ${existing.name} (${existing.tag})",
        );
      } catch (e) {
        DebugUtils.debugError(" Error enriching player $tag: $e");
      }
    }

    DebugUtils.debugSuccess(
      "Processed all bulk player data: ${_profiles.map((p) => p.tag).toList()}",
    );
    if (notify) {
      _safeNotify();
    }
  }

  /// Process bulk war statistics data
  void processBulkWarStats(List<dynamic> warStatsData, {bool notify = true}) {
    DebugUtils.debugInfo(
      "🔄 Processing bulk war stats for ${warStatsData.length} players",
    );
    final profilesByTag = {for (final player in _profiles) player.tag: player};

    for (final item in warStatsData.whereType<Map<String, dynamic>>()) {
      final String tag = item["tag"];
      try {
        final player = profilesByTag[tag];
        if (player == null) {
          continue;
        }
        player.warStats = PlayerWarStats.fromJson(item, tag, item["wars"]);
        DebugUtils.debugSuccess("Linked war stats for ${player.name} ($tag)");
      } catch (e) {
        DebugUtils.debugError(" Error processing war stats for $tag: $e");
        continue;
      }
    }

    DebugUtils.debugSuccess("Processed all bulk war stats");
    if (notify) {
      _safeNotify();
    }
  }

  void notifyDataChanged() {
    _safeNotify();
  }
}
