import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/features/clan/models/clan_capital_history.dart';
import 'package:clashkingapp/features/clan/models/clan_join_leave.dart';
import 'package:clashkingapp/features/clan/models/clan_war_stats.dart';
import 'package:clashkingapp/features/clan/models/clan_war_stats_filter.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/clan/models/clan_war_log.dart';
import 'package:flutter/material.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class ClanService extends ChangeNotifier {
  ClanService({ApiService? apiService})
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
  final Map<String, Clan> _clans = {};
  List<Clan> fetchedClans = [];
  bool _isLoading = false;
  List<ClanJoinLeave> joinLeaveList = [];
  List<CapitalHistoryItems> capitalHistory = [];
  List<ClanWarLog> warLogList = [];
  List<ClanWarStats> warStatsList = [];
  final Map<String, Map<String, dynamic>> _clanRankings = {};

  static const String _errLoadingClanData = 'Error loading clan data';

  bool get isLoading=> _isLoading;
  Map<String, Clan> get clans => _clans;

  Clan? getClanByTag(String clanTag) {
    return _clans[clanTag];
  }

  Future<void> loadAllClanData(List<String> clanTags, // NOSONAR
      {bool notify = true, bool throwOnError = false}) async {
    if (clanTags.isEmpty) return;

    _isLoading = true;
    if (notify) {
      _safeNotify();
    }

    try {
      DebugUtils.debugApi("Loading clan data for tags: $clanTags");
      final response = await _apiService.postResponse(
        '/clans/details',
        body: {"clan_tags": clanTags},
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final responseBody = ApiService.decodeResponseBody(response);
        final data = jsonDecode(responseBody);
        if (data.containsKey("items") && data["items"] is List) {
          fetchedClans = [];
          for (final clan
              in (data["items"] as List).whereType<Map<String, dynamic>>()) {
            try {
              fetchedClans.add(Clan.fromJson(clan));
            } catch (e) {
              DebugUtils.debugError(
                "Error parsing clan ${clan["tag"] ?? "unknown"}: $e",
              );
            }
          }
        } else {
          Sentry.captureMessage("$_errLoadingClanData: $data",
              level: SentryLevel.error);
        }

        for (var clan in fetchedClans) {
          _clans[clan.tag] = clan;
        }

        DebugUtils.debugSuccess("Loaded clans: ${_clans.keys.toList()}");
      } else {
        Sentry.captureMessage(_errLoadingClanData,
            level: SentryLevel.error);
        if (throwOnError) {
          throw HttpException(
            "Failed to load clan data (${response.statusCode})",
            uri: response.request?.url,
          );
        }
      }
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError("$_errLoadingClanData: $e");
      if (throwOnError) {
        rethrow;
      }
    } finally {
      _isLoading = false;
      if (notify) {
        _safeNotify();
      }
    }
  }

  Future<Clan> loadClanData(String clanTag) async {
    if (_clans.containsKey(clanTag)) {
      return _clans[clanTag]!;
    }

    _isLoading = true;
    _safeNotify();

    try {
      DebugUtils.debugApi("Loading clan data for tag: $clanTag");
      clanTag = clanTag.replaceAll("#", "%23");
      final response = await _apiService.getResponse(
        '/clan/$clanTag/details',
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final responseBody = ApiService.decodeResponseBody(response);
        final data = jsonDecode(responseBody);
        final clan = Clan.fromJson(data);

        _clans[clan.tag] = clan;
        DebugUtils.debugSuccess("Loaded clan: ${clan.tag}");
        return clan;
      } else {
        Sentry.captureMessage(_errLoadingClanData,
            level: SentryLevel.error);
        throw Exception("Failed to load clan data");
      }
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError("$_errLoadingClanData: $e");
      rethrow;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  /// Loads clan data including war statistics for clan search functionality
  Future<Clan> getClanAndWarData(String clanTag) async {
    // First load basic clan data
    final clan = await loadClanData(clanTag);

    // Then load war statistics data
    try {
      final warStats = await loadClanWarStatsData([clan.tag]);
      if (warStats.isNotEmpty) {
        linkWarStatsToClans();
        DebugUtils.debugSuccess(
            "Loaded war stats for searched clan: ${clan.tag}");
      }
    } catch (warStatsError) {
      DebugUtils.debugWarning(
          "Failed to load war stats for searched clan ${clan.tag}: $warStatsError");
      // Don't fail the entire operation if war stats loading fails
    }

    return _clans[clan.tag]!; // Return the updated clan with war stats
  }

  void linkWarsToClans(List<Clan> clans, List<WarCwl> warCwls) {
    final clansByTag = {for (final clan in clans) clan.tag: clan};
    for (final warCwl in warCwls) {
      final clan = clansByTag[warCwl.tag];
      if (clan != null) {
        clan.warCwl = warCwl;
        DebugUtils.debugInfo(
            "🔗 Linked ${clan.name} to war info (${warCwl.tag})");
      }
    }
  }

  Future<List<ClanJoinLeave>> loadClanJoinLeaveData(List<String> clanTags,
      {bool notify = true, bool throwOnError = false}) async {
    if (clanTags.isEmpty) return List<ClanJoinLeave>.empty();

    _isLoading = true;
    if (notify) {
      _safeNotify();
    }

    try {
      DebugUtils.debugApi("Loading clan join/leave data for tags: $clanTags");

      // The old bulk POST /clans/join-leave doesn't exist in the Go API.
      // Call GET /clan/:tag/join-leave and /clan/:tag/join-leave/stats in
      // parallel for each clan, then combine into ClanJoinLeave objects.
      final results = await Future.wait(
        clanTags.map((tag) => _fetchSingleClanJoinLeave(tag)),
      );

      joinLeaveList =
          results.whereType<ClanJoinLeave>().toList();
      return joinLeaveList;
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError("$_errLoadingClanData: $e");
      if (throwOnError) {
        rethrow;
      }
    } finally {
      _isLoading = false;
      if (notify) {
        _safeNotify();
      }
    }

    return List<ClanJoinLeave>.empty();
  }

  Future<ClanJoinLeave?> _fetchSingleClanJoinLeave(String tag) async {
    final encodedTag = Uri.encodeComponent(tag);
    final base = '/clan/$encodedTag/join-leave';

    try {
      final responses = await Future.wait([
        _apiService.getResponse(
          '$base?current_season=true',
          requiresAuth: true,
        ),
        _apiService.getResponse(
          '$base/stats?current_season=true',
          requiresAuth: true,
        ),
      ]);

      final eventsResponse = responses[0];
      final statsResponse = responses[1];

      if (eventsResponse.statusCode != 200 || statsResponse.statusCode != 200) {
        DebugUtils.debugWarning(
          "⚠️ Join-leave fetch failed for $tag "
          "(events: ${eventsResponse.statusCode}, stats: ${statsResponse.statusCode})",
        );
        return null;
      }

      final eventsData =
          jsonDecode(ApiService.decodeResponseBody(eventsResponse))
              as Map<String, dynamic>;
      final statsData =
          jsonDecode(ApiService.decodeResponseBody(statsResponse))
              as Map<String, dynamic>;

      // Go v2 uses event_type/player_tag/player_name/townhall_level.
      // Map to the field names ClanJoinLeave.fromJson / JoinLeaveEvent.fromJson expect.
      final items = (eventsData['items'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((e) => <String, dynamic>{
                'type': e['event_type'] ?? '',
                'clan': tag,
                'time': e['time'] ?? '',
                'tag': e['player_tag'] ?? '',
                'name': e['player_name'] ?? '',
                'th': (e['townhall_level'] as num?)?.toInt() ?? 0,
              })
          .toList();

      return ClanJoinLeave.fromJson({
        'clan_tag': tag,
        'timestamp_start': eventsData['timestamp_start'] ?? 0,
        'timestamp_end': eventsData['timestamp_end'] ?? 0,
        'stats': statsData['stats'] ?? {},
        'join_leave_list': items,
      });
    } catch (e) {
      DebugUtils.debugError("Join-leave fetch error for $tag: $e");
      return null;
    }
  }

  void linkJoinLeaveToClans() {
    final joinLeaveByTag = {
      for (final joinLeave in joinLeaveList) joinLeave.clanTag: joinLeave,
    };
    for (var clan in _clans.values) {
      final joinLeave = joinLeaveByTag[clan.tag] ?? ClanJoinLeave.empty();
      clan.joinLeave = joinLeave;
      DebugUtils.debugInfo(
          "🔗 Linked ${clan.tag} to join/leave data (${joinLeave.clanTag})");
    }
  }

  Future<List<CapitalHistoryItems>> loadCapitalData(
      List<String> clanTags, int limit,
      {bool notify = true, bool throwOnError = false}) async {
    if (clanTags.isEmpty) return List<CapitalHistoryItems>.empty();

    List<CapitalHistoryItems> history = [];
    _isLoading = true;
    if (notify) {
      _safeNotify();
    }

    try {
      DebugUtils.debugApi("Loading capital data for tags: $clanTags");
      final historyResults = await Future.wait(clanTags.map((tag) async {
        final response = await _apiService.getResponse(
          '',
          url:
              '${ApiService.proxyUrl}/clans/${tag.replaceAll('#', '%23')}/capitalraidseasons?limit=$limit',
        );

        if (response.statusCode == 200) {
          final responseBody = ApiService.decodeResponseBody(response);
          final data = jsonDecode(responseBody);
          if (data.containsKey("items") && data["items"] is List) {
            final historyData = {"history": data["items"]};
            return CapitalHistoryItems.fromJson(historyData, tag);
          }
          Sentry.captureMessage("$_errLoadingClanData: $data",
              level: SentryLevel.error);
          return null;
        }

        Sentry.captureMessage(_errLoadingClanData,
            level: SentryLevel.error);
        if (throwOnError) {
          throw HttpException(
            "Failed to load capital data (${response.statusCode})",
            uri: response.request?.url,
          );
        }
        return null;
      }));

      history = historyResults.whereType<CapitalHistoryItems>().toList();

      capitalHistory = history;
      DebugUtils.debugSuccess("Loaded capital data: ${history.length} items");
      return history;
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError("Error loading capital data: $e");
      if (throwOnError) {
        rethrow;
      }
      return List<CapitalHistoryItems>.empty();
    } finally {
      _isLoading = false;
      if (notify) {
        _safeNotify();
      }
    }
  }

  void linkCapitalToClans() {
    DebugUtils.debugInfo("Capital history items: ${capitalHistory.length}");
    final capitalByTag = {
      for (final capital in capitalHistory) capital.clanTag: capital,
    };
    for (var clan in _clans.values) {
      DebugUtils.debugInfo("🔗 Linking ${clan.tag} to capital data...");
      final capital = capitalByTag[clan.tag] ?? CapitalHistoryItems.empty();
      clan.clanCapitalRaid = capital;
      DebugUtils.debugInfo(
          "🔗 Linked ${clan.tag} to capital data (${capital.clanTag})");
    }
  }

  Future<List<ClanWarLog>> loadWarLogData(List<String> clanTags,
      {bool throwOnError = false}) async {
    if (clanTags.isEmpty) return [];

    try {
      final warLogs = await Future.wait(clanTags.map((tag) async {
        final response = await _apiService.getResponse(
          '',
          url:
              '${ApiService.proxyUrl}/clans/${tag.replaceAll('#', '%23')}/warlog',
        );

        if (response.statusCode == 200) {
          String body = ApiService.decodeResponseBody(response);
          Map<String, dynamic> jsonBody = json.decode(body);
          ClanWarLog warLog = ClanWarLog.fromJson(jsonBody, tag);
          warLog.warLogStats =
              await WarLogStatsService.analyzeWarLogs(warLog.items);
          return warLog;
        } else if (response.statusCode == 403) {
          return ClanWarLog(items: [], clanTag: tag);
        } else {
          throw HttpException(
            'Failed to load war history data (${response.statusCode})',
            uri: response.request?.url,
          );
        }
      }));
      warLogList = warLogs;
      return warLogList;
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError("Error loading war log data: $e");
      if (throwOnError) {
        rethrow;
      }
      return [];
    }
  }

  void linkWarLogToClans() {
    final warLogsByTag = {
      for (final warLog in warLogList) warLog.clanTag: warLog,
    };
    for (var clan in _clans.values) {
      final warLog =
          warLogsByTag[clan.tag] ?? ClanWarLog(items: [], clanTag: "");
      clan.clanWarLog = warLog;
      DebugUtils.debugInfo(
          "🔗 Linked ${clan.tag} to war log data (${warLog.clanTag})");
    }
  }

  Future<List<ClanWarStats>> loadClanWarStatsData(List<String> clanTags,
      {bool throwOnError = false}) async {
    if (clanTags.isEmpty) return [];

    try {
      final response = await _apiService.postResponse(
        '/war/clans/warhits',
        body: {"clan_tags": clanTags, "limit": 50},
        requiresAuth: true,
      );

      if (response.statusCode == 200) {
        final responseBody = ApiService.decodeResponseBody(response);
        final data = jsonDecode(responseBody);
        if (data.containsKey("items") && data["items"] is List) {
          warStatsList = (data["items"] as List)
              .whereType<Map<String, dynamic>>()
              .map((clan) => ClanWarStats.fromJson(clan))
              .toList();
        }

        DebugUtils.debugSuccess(
            "Loaded war stats: ${warStatsList.length} items");
        return warStatsList;
      } else {
        DebugUtils.debugError(
            "Error loading clan war stats data: ${response.statusCode}");
        Sentry.captureMessage(_errLoadingClanData,
            level: SentryLevel.error);
        if (throwOnError) {
          throw HttpException(
            "Failed to load clan war stats data (${response.statusCode})",
            uri: response.request?.url,
          );
        }
        return List<ClanWarStats>.empty();
      }
    } catch (e) {
      DebugUtils.debugError("Error loading clan war stats data: $e");
      if (throwOnError) rethrow;
      return List<ClanWarStats>.empty();
    }
  }

  /// Load clan war stats with custom filters
  Future<ClanWarStats?> loadClanWarStatsWithFilter(
    String clanTag,
    ClanWarStatsFilter filter,
  ) async {
    DebugUtils.debugApi("🎯 Loading filtered clan war stats for: $clanTag");
    DebugUtils.debugInfo("🔍 Filter: ${filter.getFilterSummary()}");

    final requestBody = {
      "clan_tags": [clanTag],
      ...filter.toJson(),
    };

    try {
      final response = await _apiService.postResponse(
        '/war/clans/warhits',
        body: requestBody,
        requiresAuth: true,
      );
      if (response.statusCode == 200) {
        final responseBody = ApiService.decodeResponseBody(response);
        final data = jsonDecode(responseBody);

        if (data.containsKey("items") && data["items"] is List) {
          final items = data["items"] as List;
          if (items.isNotEmpty) {
            final item = items.first as Map<String, dynamic>;
            final String tag = item["tag"];

            if (tag == clanTag) {
              DebugUtils.debugSuccess(
                  "✅ Loaded filtered clan war stats for $clanTag");
              return ClanWarStats.fromJson(item);
            }
          }
        }

        DebugUtils.debugWarning(
            "⚠️ No filtered clan war stats found for $clanTag");
        return null;
      } else {
        DebugUtils.debugError(
            "❌ Failed to load filtered clan war stats: ${response.statusCode}");
        Sentry.captureMessage(
            "Error loading filtered clan war stats: ${response.statusCode}",
            level: SentryLevel.error);
        throw Exception("Error loading filtered clan war stats");
      }
    } catch (e) {
      Sentry.captureException(e);
      DebugUtils.debugError("❌ Error loading filtered clan war stats: $e");
      rethrow;
    }
  }

  void linkWarStatsToClans() {
    final warStatsByTag = {
      for (final warStats in warStatsList) warStats.clanTag: warStats,
    };
    for (var clan in _clans.values) {
      final warStats = warStatsByTag[clan.tag] ??
          ClanWarStats(players: [], clanTag: "", wars: []);
      clan.clanWarStats = warStats;
      DebugUtils.debugInfo(
          "🔗 Linked ${clan.tag} to war stats data (${warStats.clanTag})");
    }
  }

  /// Process bulk clan data from the optimized API endpoint
  Future<void> processBulkClanData( // NOSONAR
      Map<String, dynamic> clanData, List<String> clanTags,
      {bool notify = true}) async {
    DebugUtils.debugInfo(
        "🔄 Processing bulk clan data for ${clanTags.length} clans");

    // Process clan details
    if (clanData["clan_details"] != null) {
      final clanDetails = clanData["clan_details"] as Map<String, dynamic>;
      for (final entry in clanDetails.entries) {
        try {
          final clan = Clan.fromJson(entry.value);
          _clans[entry.key] = clan;
          DebugUtils.debugSuccess("Processed clan: ${clan.name} (${clan.tag})");
        } catch (e) {
          DebugUtils.debugError("Error processing clan ${entry.key}: $e");
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
              DebugUtils.debugError(
                  "Error processing join/leave data for ${entry.key}: $e");
              return null;
            }
          })
          .whereType<ClanJoinLeave>()
          .toList();
      DebugUtils.debugSuccess(
          "Processed ${joinLeaveList.length} join/leave records");
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
                DebugUtils.debugWarning(
                    "Skipping capital data item with missing clan_tag");
                return null;
              }

              // The history data is in the 'history' field, not at the top level
              final historyData = {"history": item["history"] ?? []};
              final statsData = item["stats"] as Map<String, dynamic>?;
              return CapitalHistoryItems.fromJson(historyData, clanTag,
                  statsData: statsData);
            } catch (e) {
              DebugUtils.debugError("Error processing capital data: $e");
              return null;
            }
          })
          .whereType<CapitalHistoryItems>()
          .toList();
      DebugUtils.debugSuccess(
          "Processed ${capitalHistory.length} capital history items");
    }

    // Process war log data
    if (clanData["war_log_data"] != null) {
      final warLogData = clanData["war_log_data"] as List<dynamic>;
      final futures =
          warLogData.whereType<Map<String, dynamic>>().map((item) async {
        try {
          final warLog = ClanWarLog.fromJson(item, item["clan_tag"]);
          // Initialize warLogStats for bulk loaded data
          warLog.warLogStats =
              await WarLogStatsService.analyzeWarLogs(warLog.items);
          return warLog;
        } catch (e) {
          DebugUtils.debugError("Error processing war log data: $e");
          return null;
        }
      });

      final results = await Future.wait(futures);
      warLogList = results.whereType<ClanWarLog>().toList();
      DebugUtils.debugSuccess("Processed ${warLogList.length} war log items");
    }

    // Process war data (current wars and CWL)
    if (clanData["war_data"] != null) {
      DebugUtils.debugInfo("🔄 Processing war data...");
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
              DebugUtils.debugError("Error processing clan war stats: $e");
              return null;
            }
          })
          .whereType<ClanWarStats>()
          .toList();
      DebugUtils.debugSuccess(
          "Processed ${warStatsList.length} clan war stats items");
    }

    DebugUtils.debugSuccess("Processed all bulk clan data");
    if (notify) {
      _safeNotify();
    }
  }

  void notifyDataChanged() {
    _safeNotify();
  }

  Map<String, dynamic>? getClanRanking(String clanTag) => _clanRankings[clanTag];

  Future<void> fetchClanRanking(String clanTag) async {
    try {
      final response = await _apiService.getResponse(
        '/clan/$clanTag/ranking',
        requiresAuth: true,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(ApiService.decodeResponseBody(response));
        _clanRankings[clanTag] = data as Map<String, dynamic>;
        _safeNotify();
      }
    } catch (e) {
      Sentry.captureException(e);
    }
  }
}
