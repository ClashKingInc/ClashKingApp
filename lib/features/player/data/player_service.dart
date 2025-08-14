import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/player/models/war_stats_filter.dart';
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

      // Try bulk endpoint first
      DebugUtils.debugApi("🔄 Calling bulk initialization API for tag: $playerTag");
      try {
        final response = await http.post(
          Uri.parse("${ApiService.apiUrlV2}/app/initialization"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({"player_tags": [playerTag]}),
        );

        DebugUtils.debugApi("🔄 Bulk API response status: ${response.statusCode}");

        if (response.statusCode == 200) {
          final responseBody = utf8.decode(response.bodyBytes);
          final data = jsonDecode(responseBody);

          DebugUtils.debugApi("🔄 Bulk response data keys: ${data.keys.toList()}");

          // Process player data using the same method as loadApiData
          if (data["players"] != null && data["players_basic"] != null) {
            
            // Process the player data using the bulk method
            processBulkPlayerData(data["players"], data["players_basic"]);
            
            // Find the specific player we requested
            final requestedPlayer = _profiles.firstWhere(
              (p) => p.tag == playerTag,
              orElse: () => throw Exception("Player not found in response"),
            );
            
            // Load war stats if available in bulk response
            if (data["war_stats"] != null) {
              processBulkWarStats(data["war_stats"]);
            } else {
              // Load war stats separately if not in bulk response
              DebugUtils.debugInfo("🔄 Loading war stats separately for player: $playerTag");
              await loadPlayerWarStats([playerTag]);
            }
            
            DebugUtils.debugSuccess("Successfully loaded player via bulk: ${requestedPlayer.name} (${requestedPlayer.tag})");
            return requestedPlayer;
          } else {
            DebugUtils.debugWarning("⚠️ Bulk endpoint missing player data, falling back to individual calls");
            throw Exception("No player data in bulk endpoint response");
          }
        } else {
          DebugUtils.debugWarning("⚠️ Bulk endpoint failed with status ${response.statusCode}, falling back to individual calls");
          throw Exception("Bulk endpoint returned status ${response.statusCode}");
        }
      } catch (bulkError) {
        DebugUtils.debugWarning("⚠️ Bulk endpoint failed: $bulkError, falling back to individual calls");
        
        // Fallback to individual API calls
        DebugUtils.debugInfo("🔄 Using fallback individual API calls for player: $playerTag");
        
        // Call basic player endpoint
        final basicResponse = await http.post(
          Uri.parse("${ApiService.apiUrlV2}/players"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({"player_tags": [playerTag]}),
        );

        if (basicResponse.statusCode != 200) {
          throw Exception("Failed to fetch basic player data: ${basicResponse.statusCode}");
        }

        final basicResponseBody = utf8.decode(basicResponse.bodyBytes);
        final basicData = jsonDecode(basicResponseBody);

        if (!basicData.containsKey("items") || (basicData["items"] as List).isEmpty) {
          throw Exception("No player data found for tag: $playerTag");
        }

        final playerJson = (basicData["items"] as List).first as Map<String, dynamic>;
        final player = Player.fromJson(playerJson);

        // Get clan tag for extended call
        final clanTag = player.clanOverview.tag;
        final clanTagsByPlayer = {playerTag: clanTag};

        // Call extended player endpoint
        final extendedResponse = await http.post(
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

        if (extendedResponse.statusCode == 200) {
          final extendedResponseBody = utf8.decode(extendedResponse.bodyBytes);
          final extendedData = jsonDecode(extendedResponseBody);

          if (extendedData.containsKey("items") && (extendedData["items"] as List).isNotEmpty) {
            final extendedPlayerJson = (extendedData["items"] as List).first as Map<String, dynamic>;
            player.enrichWithFullStats(extendedPlayerJson);
          }
        }

        // Add the player to _profiles temporarily so loadPlayerWarStats can find it
        final existingIndex = _profiles.indexWhere((p) => p.tag == playerTag);
        if (existingIndex != -1) {
          _profiles[existingIndex] = player;
        } else {
          _profiles.add(player);
        }
        
        // Load war stats for the individual player
        DebugUtils.debugInfo("🔄 Loading war stats for individual player: $playerTag");
        await loadPlayerWarStats([playerTag]);

        DebugUtils.debugSuccess("Successfully loaded player via fallback: ${player.name} (${player.tag})");
        return player;
      }
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

  /// Load war stats with custom filters
  Future<PlayerWarStats?> loadPlayerWarStatsWithFilter(
    String playerTag,
    WarStatsFilter filter,
  ) async {
    final token = await TokenService().getAccessToken();
    if (token == null) throw Exception("User not authenticated");
    
    DebugUtils.debugApi("🎯 Loading filtered war stats for: $playerTag");
    DebugUtils.debugInfo("🔍 Filter: ${filter.getFilterSummary()}");

    final requestBody = {
      "player_tags": [playerTag],
      ...filter.toJson(),
    };

    // Debug logging to see what's being sent
    DebugUtils.debugInfo("🔍 War Stats Request Body: ${jsonEncode(requestBody)}");

    final response = await http.post(
      Uri.parse("${ApiService.apiUrlV2}/war/players/warhits"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(requestBody),
    );

    // Debug logging for response
    DebugUtils.debugInfo("📡 War Stats Response Status: ${response.statusCode}");

    try {
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);

        if (data.containsKey("items") && data["items"] is List) {
          final items = data["items"] as List;
          if (items.isNotEmpty) {
            final item = items.first;
            final String tag = item["tag"];
            
            if (tag == playerTag) {
              DebugUtils.debugSuccess("✅ Loaded filtered war stats for $playerTag");
              return PlayerWarStats.fromJson(item, tag, data["wars"]);
            }
          }
        }
        
        DebugUtils.debugWarning("⚠️ No filtered war stats found for $playerTag");
        return null;
      } else {
        DebugUtils.debugError("❌ Failed to load filtered war stats: ${response.statusCode}");
        if (response.statusCode == 422) {
          final errorBody = utf8.decode(response.bodyBytes);
          DebugUtils.debugError("❌ Validation Error Details: $errorBody");
        }
        Sentry.captureMessage("Error loading filtered war stats: ${response.statusCode}",
            level: SentryLevel.error);
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
        // Skip players not found in basic data - extended data alone is incomplete
        DebugUtils.debugWarning("⚠️ Skipping player $tag - not found in basic data and extended data is incomplete");
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
