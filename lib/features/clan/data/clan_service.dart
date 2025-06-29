import 'dart:convert';
import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';
import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';
import 'package:clashkingapp/features/clan/models/clan_war_stats.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/clan/models/clan_war_log.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ClanService extends ChangeNotifier {
  final Map<String, Clan> _clans = {};
  List<Clan> fetchedClans = [];
  bool _isLoading = false;
  List<ClanJoinLeave> joinLeaveList = [];
  List<CapitalHistoryItems> capitalHistory = [];
  List<ClanWarLog> warLogList = [];
  List<ClanWarStats> warStatsList = [];

  bool get isLoading => _isLoading;
  Map<String, Clan> get clans => _clans;

  Clan? getClanByTag(String clanTag) {
    return _clans[clanTag];
  }

  Future<void> loadAllClanData(List<String> clanTags) async {
    if (clanTags.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      print("🏰 Loading clan data for tags: $clanTags");
      final token = await TokenService().getAccessToken();
      if (token == null) throw Exception("User not authenticated");

      final response = await http.post(
        Uri.parse("${ApiService.apiUrlV2}/clans/details"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"clan_tags": clanTags}),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        if (data.containsKey("items") && data["items"] is List) {
          fetchedClans = (data["items"] as List)
              .whereType<Map<String, dynamic>>()
              .map((clan) => Clan.fromJson(clan))
              .toList();
        } else {
          Sentry.captureMessage("Error loading clan data: $data",
              level: SentryLevel.error);
        }

        for (var clan in fetchedClans) {
          _clans[clan.tag] = clan;
        }

        print("✅ Loaded clans: ${_clans.keys.toList()}");
      } else {
        Sentry.captureMessage("Error loading clan data",
            level: SentryLevel.error);
      }
    } catch (e) {
      Sentry.captureException(e);
      print("❌ Error loading clan data: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Clan> loadClanData(String clanTag) async {
    if (_clans.containsKey(clanTag)) {
      return _clans[clanTag]!;
    }

    _isLoading = true;
    notifyListeners();

    try {
      print("🏰 Loading clan data for tag: $clanTag");
      clanTag = clanTag.replaceAll("#", "%23");
      final token = await TokenService().getAccessToken();
      if (token == null) throw Exception("User not authenticated");

      final response = await http.get(
        Uri.parse("${ApiService.apiUrlV2}/clan/$clanTag/details"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        final clan = Clan.fromJson(data);

        _clans[clan.tag] = clan;
        print("✅ Loaded clan: ${clan.tag}");
        return clan;
      } else {
        Sentry.captureMessage("Error loading clan data",
            level: SentryLevel.error);
        throw Exception("Failed to load clan data");
      }
    } catch (e) {
      Sentry.captureException(e);
      print("❌ Error loading clan data: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void linkWarsToClans(List<Clan> clans, List<WarCwl> warCwls) {
    for (final warCwl in warCwls) {
      try {
        final clan = clans.firstWhere((clan) => clan.tag == warCwl.tag);

        clan.warCwl = warCwl;
        print("🔗 Linked ${clan.name} to war info (${warCwl.tag})");
      } catch (e) {
        print("❌ Error linking clan ${warCwl.tag} to war info: $e");
      }
    }
  }

  Future<List<ClanJoinLeave>> loadClanJoinLeaveData(
      List<String> clanTags) async {
    if (clanTags.isEmpty) return List<ClanJoinLeave>.empty();

    _isLoading = true;
    notifyListeners();

    try {
      print("🏰 Loading clan join/leave data for tags: $clanTags");
      final token = await TokenService().getAccessToken();
      if (token == null) throw Exception("User not authenticated");

      final response = await http.post(
        Uri.parse(
            "${ApiService.apiUrlV2}/clans/join-leave?current_season=true"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"clan_tags": clanTags}),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        if (data.containsKey("items") && data["items"] is List) {
          joinLeaveList = (data["items"] as List)
              .whereType<Map<String, dynamic>>()
              .map((clan) => ClanJoinLeave.fromJson(clan))
              .toList();
        } else {
          Sentry.captureMessage("Error loading clan data: $data",
              level: SentryLevel.error);
        }

        return joinLeaveList;
      } else {
        Sentry.captureMessage("Error loading clan data",
            level: SentryLevel.error);
      }
    } catch (e) {
      Sentry.captureException(e);
      print("❌ Error loading clan data: $e");
    }

    return List<ClanJoinLeave>.empty();
  }

  void linkJoinLeaveToClans() {
    for (var clan in _clans.values) {
      try {
        final joinLeave = joinLeaveList.firstWhere(
            (joinLeave) => joinLeave.clanTag == clan.tag,
            orElse: () => ClanJoinLeave.empty());
        clan.joinLeave = joinLeave;
        print(
            "🔗 Linked ${clan.tag} to join/leave data (${joinLeave.clanTag})");
      } catch (e) {
        print("❌ Error linking clan ${clan.tag} to join/leave data: $e");
      }
    }
  }

  Future<List<CapitalHistoryItems>> loadCapitalData(
      List<String> clanTags, int limit) async {
    if (clanTags.isEmpty) return List<CapitalHistoryItems>.empty();

    List<CapitalHistoryItems> history = [];
    _isLoading = true;
    notifyListeners();

    try {
      print("🏰 Loading capital data for tags: $clanTags");
      final token = await TokenService().getAccessToken();
      if (token == null) throw Exception("User not authenticated");

      for (var tag in clanTags) {
        final response = await http.get(
          Uri.parse(
              'https://proxy.clashk.ing/v1/clans/${tag.replaceAll('#', '%23')}/capitalraidseasons?limit=$limit'),
        );

        if (response.statusCode == 200) {
          final responseBody = utf8.decode(response.bodyBytes);
          final data = jsonDecode(responseBody);
          if (data.containsKey("items") && data["items"] is List) {
            // Convert API response format to expected format
            final historyData = {"history": data["items"]};
            final tagHistory = CapitalHistoryItems.fromJson(historyData, tag);
            history.add(tagHistory);
          } else {
            Sentry.captureMessage("Error loading clan data: $data",
                level: SentryLevel.error);
          }
        } else {
          Sentry.captureMessage("Error loading clan data",
              level: SentryLevel.error);
        }
      }

      capitalHistory = history;
      _isLoading = false;
      notifyListeners();
      print("✅ Loaded capital data: ${history.length} items");
      return history;
    } catch (e) {
      Sentry.captureException(e);
      print("❌ Error loading capital data: $e");
      return List<CapitalHistoryItems>.empty();
    }
  }

  void linkCapitalToClans() {
    print(capitalHistory.length);
    for (var clan in _clans.values) {
      try {
        print("🔗 Linking ${clan.tag} to capital data...");
        final capital = capitalHistory.firstWhere(
          (c) => c.clanTag == clan.tag,
          orElse: () => CapitalHistoryItems.empty(),
        );
        clan.clanCapitalRaid = capital;
        print("🔗 Linked ${clan.tag} to capital data (${capital.clanTag})");
      } catch (e) {
        print("❌ Error linking clan ${clan.tag} to capital data: $e");
      }
    }
  }

  Future<List<ClanWarLog>> loadWarLogData(List<String> clanTags) async {
    if (clanTags.isEmpty) return [];

    for (String tag in clanTags) {
      final response = await http.get(Uri.parse(
          '${ApiService.proxyUrl}/clans/${tag.replaceAll('#', '%23')}/warlog'));

      if (response.statusCode == 200) {
        String body = utf8.decode(response.bodyBytes);
        Map<String, dynamic> jsonBody = json.decode(body);
        ClanWarLog warLog = ClanWarLog.fromJson(jsonBody, tag);
        warLog.warLogStats =
            await WarLogStatsService.analyzeWarLogs(warLog.items);
        warLogList.add(warLog);
      } else if (response.statusCode == 403) {
        warLogList.add(ClanWarLog(items: [], clanTag: ""));
      } else {
        throw Exception('Failed to load war history data');
      }
    }
    return warLogList;
  }

  void linkWarLogToClans() {
    for (var clan in _clans.values) {
      try {
        final warLog = warLogList.firstWhere(
          (log) => log.clanTag == clan.tag,
          orElse: () => ClanWarLog(items: [], clanTag: ""),
        );
        clan.clanWarLog = warLog;
        print("🔗 Linked ${clan.tag} to war log data (${warLog.clanTag})");
      } catch (e) {
        print("❌ Error linking clan ${clan.tag} to war log data: $e");
      }
    }
  }

  Future<List<ClanWarStats>> loadClanWarStatsData(List<String> clanTags) async {
    if (clanTags.isEmpty) return [];

    final token = await TokenService().getAccessToken();
    if (token == null) throw Exception("User not authenticated");

    final response = await http.post(
      Uri.parse("${ApiService.apiUrlV2}/war/clans/warhits"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"clan_tags": clanTags, "limit": 50}),
    );

    if (response.statusCode == 200) {
      final responseBody = utf8.decode(response.bodyBytes);
      final data = jsonDecode(responseBody);
      if (data.containsKey("items") && data["items"] is List) {
        warStatsList = (data["items"] as List)
            .whereType<Map<String, dynamic>>()
            .map((clan) => ClanWarStats.fromJson(clan))
            .toList();
      }

      print("✅ Loaded war stats: ${warStatsList.length} items");
      return warStatsList;
    } else {
      print("❌ Error loading clan war stats data: ${response.statusCode}");
      Sentry.captureMessage("Error loading clan data",
          level: SentryLevel.error);
      return List<ClanWarStats>.empty();
    }
  }

  void linkWarStatsToClans() {
    for (var clan in _clans.values) {
      try {
        final warStats = warStatsList.firstWhere(
          (stats) => stats.clanTag == clan.tag,
          orElse: () => ClanWarStats(players: [], clanTag: "", wars: []),
        );
        clan.clanWarStats = warStats;
        print("🔗 Linked ${clan.tag} to war stats data (${warStats.clanTag})");
      } catch (e) {
        print("❌ Error linking clan ${clan.tag} to war stats data: $e");
      }
    }
  }

  /// Process bulk clan data from the optimized API endpoint
  Future<void> processBulkClanData(Map<String, dynamic> clanData, List<String> clanTags) async {
    print("🔄 Processing bulk clan data for ${clanTags.length} clans");
    
    // Process clan details
    if (clanData["clan_details"] != null) {
      final clanDetails = clanData["clan_details"] as Map<String, dynamic>;
      for (final entry in clanDetails.entries) {
        try {
          final clan = Clan.fromJson(entry.value);
          _clans[entry.key] = clan;
          print("✅ Processed clan: ${clan.name} (${clan.tag})");
        } catch (e) {
          print("❌ Error processing clan ${entry.key}: $e");
        }
      }
    }

    // Process join/leave data
    if (clanData["join_leave_data"] != null) {
      final joinLeaveData = clanData["join_leave_data"] as Map<String, dynamic>;
      joinLeaveList = joinLeaveData.entries
          .map((entry) {
            try {
              return ClanJoinLeave.fromJson(entry.value);
            } catch (e) {
              print("❌ Error processing join/leave data for ${entry.key}: $e");
              return null;
            }
          })
          .whereType<ClanJoinLeave>()
          .toList();
      print("✅ Processed ${joinLeaveList.length} join/leave records");
    }

    // Process capital data
    if (clanData["capital_data"] != null) {
      final capitalData = clanData["capital_data"] as List<dynamic>;
      capitalHistory = capitalData
          .whereType<Map<String, dynamic>>()
          .map((item) {
            try {
              final clanTag = item["clan_tag"]?.toString();
              if (clanTag == null || clanTag.isEmpty) {
                print("⚠️ Skipping capital data item with missing clan_tag");
                return null;
              }
              
              // The history data is in the 'history' field, not at the top level
              final historyData = {"history": item["history"] ?? []};
              final statsData = item["stats"] as Map<String, dynamic>?;
              return CapitalHistoryItems.fromJson(historyData, clanTag, statsData: statsData);
            } catch (e) {
              print("❌ Error processing capital data: $e");
              return null;
            }
          })
          .whereType<CapitalHistoryItems>()
          .toList();
      print("✅ Processed ${capitalHistory.length} capital history items");
    }

    // Process war log data
    if (clanData["war_log_data"] != null) {
      final warLogData = clanData["war_log_data"] as List<dynamic>;
      final futures = warLogData
          .whereType<Map<String, dynamic>>()
          .map((item) async {
            try {
              final warLog = ClanWarLog.fromJson(item, item["clan_tag"]);
              // Initialize warLogStats for bulk loaded data
              warLog.warLogStats = await WarLogStatsService.analyzeWarLogs(warLog.items);
              return warLog;
            } catch (e) {
              print("❌ Error processing war log data: $e");
              return null;
            }
          });
      
      final results = await Future.wait(futures);
      warLogList = results.whereType<ClanWarLog>().toList();
      print("✅ Processed ${warLogList.length} war log items");
    }

    // Process war data (current wars and CWL)
    if (clanData["war_data"] != null) {
      print("🔄 Processing war data...");
      // War data processing should be handled by WarCwlService
      // This is typically linked in the parent call
    }

    // Process clan war stats
    if (clanData["clan_war_stats"] != null) {
      final clanWarStatsData = clanData["clan_war_stats"] as List<dynamic>;
      warStatsList = clanWarStatsData
          .whereType<Map<String, dynamic>>()
          .map((item) {
            try {
              return ClanWarStats.fromJson(item);
            } catch (e) {
              print("❌ Error processing clan war stats: $e");
              return null;
            }
          })
          .whereType<ClanWarStats>()
          .toList();
      print("✅ Processed ${warStatsList.length} clan war stats items");
    }

    print("✅ Processed all bulk clan data");
    notifyListeners();
  }
}
