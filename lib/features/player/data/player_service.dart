import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/player/models/player_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';

class PlayerService extends ChangeNotifier {
  bool _isLoading = false;
  List<Player> _profiles = [];
  List<Map<String, dynamic>> _clans = [];

  bool get isLoading => _isLoading;
  List<Player> get profiles => _profiles;
  List<Map<String, dynamic>> get clans => _clans;

  Player? getSelectedProfile(CocAccountService cocAccountService) {
    String? selectedTag = cocAccountService.selectedTag;
    print("🔍 SelectedTag: $selectedTag");
    print("📊 Available profiles: ${profiles.map((p) => p.tag).toList()}");

    if (selectedTag == null) return null;
    return profiles.firstWhere(
      (profile) => profile.tag == selectedTag,
    );
  }

  /// Init basic stats for the saved accounts.
  Future<Map<String, String>> initPlayerData(List<String> playerTags) async {
    _isLoading = true;
    notifyListeners();

    final token = await TokenService().getAccessToken();
    if (token == null) throw Exception("User not authenticated");

    final response = await http.post(
      Uri.parse("${ApiService.apiUrlV2}/players"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"player_tags": playerTags}),
    );

    final Map<String, String> clanTagsByPlayer = {};

    try {
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);

        if (data.containsKey("items") && data["items"] is List) {
          _profiles = (data["items"] as List)
              .whereType<Map<String, dynamic>>()
              .map((account) {
            final player = Player.fromJson(account);
            if (player.clanOverview.tag.isNotEmpty) {
              clanTagsByPlayer[player.tag] = player.clanOverview.tag;
            }
            return player;
          }).toList();
          print(
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
      print("❌ Error initializing accounts data: $e");
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

          print("✅ Enriched profiles: ${_profiles.map((p) => p.tag).toList()}");
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
      print("❌ Error loading accounts data: $e");
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

      playerTag = playerTag.replaceAll("#", "%23");

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

      final String clanTag = player.clanTag;

      if (clanTag.isEmpty) {
        return player;
      }

      String clanTagUrl = clanTag.replaceAll("#", "%23");

      final responses = await Future.wait([
        http.get(
          Uri.parse("${ApiService.apiUrlV2}/player/$playerTag/extended")
              .replace(queryParameters: {
            "clan_tag": clanTag,
          }),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
        http.get(
          Uri.parse("${ApiService.apiUrlV2}/clan/$clanTagUrl/details"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
        http.get(
          Uri.parse("${ApiService.apiUrlV2}/war/$clanTagUrl/war-summary"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        ),
        http.post(
          Uri.parse("${ApiService.apiUrlV2}/players/warhits"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "player_tags": [playerTag],
            "limit": 50
          }),
        )
      ]);

      final responseExtended = responses[0];
      final responseClan = responses[1];
      final responseWar = responses[2];
      final responseWarHits = responses[3];

      if (responseExtended.statusCode == 200) {
        final extendedData =
            jsonDecode(utf8.decode(responseExtended.bodyBytes));
        player.enrichWithFullStats(extendedData);
      }

      if (responseClan.statusCode == 200) {
        final clanData = jsonDecode(utf8.decode(responseClan.bodyBytes));
        player.clan = Clan.fromJson(clanData);
      }

      if (responseWar.statusCode == 200) {
        player.clan?.warCwl = WarCwl.fromJson(
            jsonDecode(utf8.decode(responseWar.bodyBytes)), player.clan?.tag);
      }

      if (responseWarHits.statusCode == 200) {
        final warStatsData = jsonDecode(utf8.decode(responseWarHits.bodyBytes));
        player.warStats = PlayerWarStats.fromJson(warStatsData["items"][0]);
      }

      return player;
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      print("❌ Error in getPlayerAndClanData: $e");
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
        print("🔗 Linked ${profile.tag} to ${profile.clan?.name}");
      } catch (e) {
        print("❌ Error linking ${profile.tag} to clan: $e");
      }
    }
  }

  Future<void> loadPlayerWarStats(List<String> playerTags) async {
    final token = await TokenService().getAccessToken();
    if (token == null) throw Exception("User not authenticated");
    print("🏰 Loading player data for tags: $playerTags");

    final response = await http.post(
      Uri.parse("${ApiService.apiUrlV2}/players/warhits"),
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
              player.warStats = PlayerWarStats.fromJson(item);
            } catch (e) {
              print("❌ Error loading war stats for $tag: $e");
              continue;
            }
          }
          print("✅ Loaded & linked war stats for $playerTags players");
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
      print("❌ Error loading war stats: $e");
    }
  }

  String getRoleText(String role, BuildContext context) {
    switch (role) {
      case 'leader':
        return AppLocalizations.of(context)?.leader ?? 'Leader';
      case 'coLeader':
        return AppLocalizations.of(context)?.coLeader ?? 'Co-Leader';
      case 'admin':
        return AppLocalizations.of(context)?.elder ?? 'Elder';
      case 'member':
        return AppLocalizations.of(context)?.member ?? 'Member';
      default:
        return 'No clan';
    }
  }
}
