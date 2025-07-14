import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class PlayerService extends ChangeNotifier {
  bool _isLoading = false;
  List<Player> _profiles = [];
  List<Map<String, dynamic>> _clans = [];

  bool get isLoading => _isLoading;
  List<Player> get profiles => _profiles;
  List<Map<String, dynamic>> get clans => _clans;

  Player? getSelectedProfile(CocAccountService cocAccountService) {
    String? selectedTag = cocAccountService.selectedTag;
    DebugUtils.debugInfo("🔍 SelectedTag: $selectedTag");
    DebugUtils.debugInfo("📊 Available profiles: ${profiles.map((p) => p.tag).toList()}");

    if (selectedTag == null) return null;
    try {
      return profiles.firstWhere(
        (profile) => profile.tag == selectedTag,
      );
    } catch (e) {
      DebugUtils.debugWarning("⚠️ Profile not found for tag: $selectedTag");
      return null;
    }
  }

  /// Init basic stats for the saved accounts.
  Future<Map<String, String>> initPlayerData(List<String> playerTags) async {
    _isLoading = true;
    notifyListeners();

    final token = await TokenService().getAccessToken();
    if (token == null) throw Exception("User not authenticated");

    DebugUtils.debugApi("🔄 Calling players API with tags: $playerTags");
    final response = await http.post(
      Uri.parse("${ApiService.apiUrlV2}/players"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"player_tags": playerTags}),
    );
    
    DebugUtils.debugApi("🔄 Players API response status: ${response.statusCode}");

    final Map<String, String> clanTagsByPlayer = {};

    try {
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        DebugUtils.debugApi("🔄 Players API response body: $responseBody");
        final data = jsonDecode(responseBody);

        if (data.containsKey("items") && data["items"] is List) {
          _profiles = (data["items"] as List)
              .whereType<Map<String, dynamic>>()
              .map((account) {
            DebugUtils.debugInfo("🔄 Processing player JSON: $account");
            final player = Player.fromJson(account);
            DebugUtils.debugInfo("🔄 Created player: ${player.name} (${player.tag})");
            if (player.clanOverview.tag.isNotEmpty) {
              clanTagsByPlayer[player.tag] = player.clanOverview.tag;
              // Cache clan tag for widget use
              storePrefs('player_${player.tag}_clan_tag', player.clanOverview.tag);
            }
            return player;
          }).toList();
          DebugUtils.debugSuccess(
              "✅ Initialized profiles: ${profiles.map((p) => p.tag).toList()}");
        } else if (response.statusCode == 503) {
          throw HttpException("503", uri: response.request!.url);
        } else if (response.statusCode == 500) {
          throw HttpException("500", uri: response.request!.url);
        } else {
          Sentry.captureMessage("Error initializing player data: $data",
              level: SentryLevel.error);
        }
      } else {
        Sentry.captureMessage("Error initializing accounts data",
            level: SentryLevel.error);
        throw Exception("Error initializing accounts data");
      }
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError(" Error initializing accounts data: $e");
    }

    _isLoading = false;
    notifyListeners();
    return clanTagsByPlayer;
  }

  /// Loads all stats for the saved accounts.
  Future<void> loadPlayerData(
      List<String> playerTags, Map<String, String> clanTagsByPlayer) async {
    _isLoading = true;
    notifyListeners();

    final token = await TokenService().getAccessToken();
    if (token == null) throw Exception("User not authenticated");

    final response = await http.post(
      Uri.parse("${ApiService.apiUrlV2}/players/extended"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "player_tags": playerTags,
        "clan_tags": clanTagsByPlayer,
      }),
    );

    try {
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);

        if (data.containsKey("items") && data["items"] is List) {
          final items =
              (data["items"] as List).whereType<Map<String, dynamic>>();

          for (final item in items) {
            final tag = item["tag"];
            final existing = _profiles.firstWhere(
              (p) => p.tag == tag,
              orElse: () => Player.fromJson(item), // fallback
            );
            existing.enrichWithFullStats(item);
          }

          DebugUtils.debugSuccess("Enriched profiles: ${_profiles.map((p) => p.tag).toList()}");
        } else {
          Sentry.captureMessage("Error loading player data: $data",
              level: SentryLevel.error);
        }
      } else {
        Sentry.captureMessage("Error loading accounts data",
            level: SentryLevel.error);
        throw Exception("Error loading accounts data");
      }
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError(" Error loading accounts data: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Player> getPlayerAndClanData(String playerTag) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await TokenService().getAccessToken();
      if (token == null) throw Exception("User not authenticated");

      // First, get basic player data
      DebugUtils.debugApi("🔄 Calling players API for tag: $playerTag");
      final responseInit = await http.post(
        Uri.parse("${ApiService.apiUrlV2}/players"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "player_tags": [playerTag]
        }),
      );

      if (responseInit.statusCode != 200) {
        throw Exception("Failed to fetch initial player data");
      }

      final initData = jsonDecode(utf8.decode(responseInit.bodyBytes));
      final Player player = Player.fromJson(initData["items"][0]);
      
      // Build clan tags map like loadPlayerData does
      final Map<String, String> clanTagsByPlayer = {};
      if (player.clanTag.isNotEmpty) {
        clanTagsByPlayer[player.tag] = player.clanTag;
      }

      // If player has no clan, return basic player data
      if (clanTagsByPlayer.isEmpty) {
        return player;
      }

      // Use the same extended endpoint as loadPlayerData
      DebugUtils.debugApi("🔄 Calling extended players API for tag: $playerTag");
      final responseExtended = await http.post(
        Uri.parse("${ApiService.apiUrlV2}/players/extended"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "player_tags": [playerTag],
          "clan_tags": clanTagsByPlayer,
        }),
      );

      if (responseExtended.statusCode == 200) {
        final responseBody = utf8.decode(responseExtended.bodyBytes);
        final data = jsonDecode(responseBody);

        if (data.containsKey("items") && data["items"] is List) {
          final items = (data["items"] as List).whereType<Map<String, dynamic>>();
          
          for (final item in items) {
            final tag = item["tag"];
            if (tag == playerTag) {
              player.enrichWithFullStats(item);
              break;
            }
          }
          
          DebugUtils.debugSuccess("Enriched player: ${player.name} (${player.tag})");
        } else {
          Sentry.captureMessage("Error loading player extended data: $data",
              level: SentryLevel.error);
        }
      } else {
        Sentry.captureMessage("Error loading player extended data",
            level: SentryLevel.error);
        throw Exception("Error loading player extended data");
      }

      return player;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      DebugUtils.debugError(" Error in getPlayerAndClanData: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void linkClansToPlayer(List<Player> players, List<Clan> clans) {
    for (var profile in players) {
      if (profile.clanTag.isEmpty) continue;
      try {
        profile.clan = clans.firstWhere((clan) => clan.tag == profile.clanTag);
        DebugUtils.debugInfo("🔗 Linked ${profile.tag} to ${profile.clan?.name}");
      } catch (e) {
        DebugUtils.debugError(" Error linking ${profile.tag} to clan: $e");
      }
    }
  }

  Future<void> loadPlayerWarStats(List<String> playerTags) async {
    final token = await TokenService().getAccessToken();
    if (token == null) throw Exception("User not authenticated");
    DebugUtils.debugApi("🏰 Loading player data for tags: $playerTags");

    final response = await http.post(
      Uri.parse("${ApiService.apiUrlV2}/war/players/warhits"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"player_tags": playerTags, "limit": 50}),
    );

    try {
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);

        if (data.containsKey("items") && data["items"] is List) {
          for (final item in data["items"]) {
            final String tag = item["tag"];
            try {
              final Player player = _profiles.firstWhere((p) => p.tag == tag);
              player.warStats =
                  PlayerWarStats.fromJson(item, tag, data["wars"]);
            } catch (e) {
              DebugUtils.debugError(" Error loading war stats for $tag: $e");
              continue;
            }
          }
          DebugUtils.debugSuccess("Loaded & linked war stats for $playerTags players");
        } else {
          Sentry.captureMessage("Error loading war stats: $data",
              level: SentryLevel.error);
        }
      } else {
        Sentry.captureMessage("Error loading war stats",
            level: SentryLevel.error);
        throw Exception("Error loading war stats");
      }
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError(" Error loading war stats: $e");
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
    final player = _profiles.cast<Player?>().firstWhere((p) => p?.tag == tag, orElse: () => null);
    if (player != null) {
      return jsonEncode({
        "player_tag": player.tag,
        "name": player.name,
        "townHallLevel": player.townHallLevel,
      });
    }
    return "{}";
  }

  /// Process bulk player data from the optimized API endpoint
  void processBulkPlayerData(List<dynamic> playersExtended, List<dynamic> playersBasic) {
    DebugUtils.debugInfo("🔄 Processing bulk player data: ${playersExtended.length} extended, ${playersBasic.length} basic");
    
    // First, create basic player profiles from basic data
    _profiles = playersBasic
        .whereType<Map<String, dynamic>>()
        .map((account) {
      DebugUtils.debugInfo("🔄 Processing basic player: ${account['tag']}");
      final player = Player.fromJson(account);
      if (player.clanOverview.tag.isNotEmpty) {
        // Cache clan tag for widget use
        storePrefs('player_${player.tag}_clan_tag', player.clanOverview.tag);
      }
      return player;
    }).toList();

    DebugUtils.debugSuccess("Created ${_profiles.length} basic player profiles");

    // Then enrich with extended data
    for (final extendedData in playersExtended.whereType<Map<String, dynamic>>()) {
      final tag = extendedData["tag"];
      try {
        final existing = _profiles.firstWhere((p) => p.tag == tag);
        existing.enrichWithFullStats(extendedData);
        DebugUtils.debugSuccess("Enriched player: ${existing.name} (${existing.tag})");
      } catch (e) {
        DebugUtils.debugError(" Error enriching player $tag: $e");
        // Create a new player if not found in basic data
        try {
          final player = Player.fromJson(extendedData);
          player.enrichWithFullStats(extendedData);
          _profiles.add(player);
          DebugUtils.debugSuccess("Created & enriched new player: ${player.name} (${player.tag})");
        } catch (e2) {
          DebugUtils.debugError(" Error creating player from extended data $tag: $e2");
        }
      }
    }

    DebugUtils.debugSuccess("Processed all bulk player data: ${_profiles.map((p) => p.tag).toList()}");
    notifyListeners();
  }

  /// Process bulk war statistics data
  void processBulkWarStats(List<dynamic> warStatsData) {
    DebugUtils.debugInfo("🔄 Processing bulk war stats for ${warStatsData.length} players");
    
    for (final item in warStatsData.whereType<Map<String, dynamic>>()) {
      final String tag = item["tag"];
      try {
        final Player player = _profiles.firstWhere((p) => p.tag == tag);
        player.warStats = PlayerWarStats.fromJson(item, tag, item["wars"]);
        DebugUtils.debugSuccess("Linked war stats for ${player.name} ($tag)");
      } catch (e) {
        DebugUtils.debugError(" Error processing war stats for $tag: $e");
        continue;
      }
    }
    
    DebugUtils.debugSuccess("Processed all bulk war stats");
    notifyListeners();
  }
}
