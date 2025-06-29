import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/widgets/war_widget.dart';
import 'package:flutter/foundation.dart';

class CocAccountService extends ChangeNotifier {
  List<Map<String, dynamic>> _cocAccounts = [];
  bool _isLoading = false;
  String? _selectedTag;
  ValueNotifier<String?> selectedTagNotifier = ValueNotifier(null);
  List<Map<String, dynamic>> get cocAccounts => _cocAccounts;
  bool get isLoading => _isLoading;
  String? get selectedTag => _selectedTag;
  List<Player> profiles = [];
  List<String> get accounts =>
      _cocAccounts.map((account) => account["player_tag"].toString()).toList();

  /// Clears all cached account data (for logout)
  void clearAccountData() {
    _cocAccounts = [];
    _selectedTag = null;
    selectedTagNotifier.value = null;
    profiles = [];
    _isLoading = false;
    notifyListeners();
  }

  /// Fetches the user's linked Clash of Clans accounts from the backend.
  Future<void> fetchCocAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await TokenService().getAccessToken();
      if (token == null) throw Exception("User not authenticated");

      final response = await http.get(
        Uri.parse("${ApiService.apiUrlV2}/users/coc-accounts"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cocAccounts = List<Map<String, dynamic>>.from(data["coc_accounts"]);
      } else {
        Sentry.captureMessage(
            "Error fetching CoC accounts, status code: ${response.statusCode}, body: ${response.body}",
            level: SentryLevel.error);
      }
    } catch (exception) {
      Sentry.captureException(exception);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Adds a Clash of Clans account (without verification).
  Future<Map<String, dynamic>> addCocAccount(String playerTag) async {
    final token = await TokenService().getAccessToken();
    if (token == null) {
      return {"code": 401, "message": "User not authenticated"};
    }

    print("Adding CoC account with tag: $playerTag");

    try {
      final response = await http.post(
        Uri.parse("${ApiService.apiUrlV2}/users/add-coc-account"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"player_tag": playerTag}),
      );

      final data = jsonDecode(response.body);

      return {
        "code": response.statusCode,
        "message": data["detail"] ?? "Uknown error",
        "account": response.statusCode == 200 ? data["account"] : null
      };
    } catch (e) {
      return {"code": 500, "message": "Internal server error"};
    }
  }

  void addLocalAccount(Map<String, dynamic> account) {
    _cocAccounts.add(account);
    notifyListeners();
  }

  /// Adds a Clash of Clans account (with ownership verification).
  Future<Map<String, dynamic>> addCocAccountWithVerification(
      String playerTag, String playerToken) async {
    try {
      final token = await TokenService().getAccessToken();
      if (token == null) {
        return {"code": 401, "message": "User not authenticated"};
      }

      final response = await http.post(
        Uri.parse("${ApiService.apiUrlV2}/users/add-coc-account-with-token"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body:
            jsonEncode({"player_tag": playerTag, "player_token": playerToken}),
      );

      final data = jsonDecode(response.body);

      return {
        "code": response.statusCode,
        "message": data["detail"] ?? "Uknown error",
        "account": response.statusCode == 200 ? data["account"] : null
      };
    } catch (e) {
      return {"code": 500, "message": "Internal server error"};
    }
  }

  /// Removes a Clash of Clans account from the user's linked accounts.
  Future<void> removeCocAccount(String playerTag) async {
    try {
      final token = await TokenService().getAccessToken();
      if (token == null) throw Exception("User not authenticated");

      final response = await http.delete(
        Uri.parse("${ApiService.apiUrlV2}/users/remove-coc-account"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"player_tag": playerTag}),
      );

      if (response.statusCode == 200) {
        _cocAccounts.removeWhere((account) => account["player_tag"] == playerTag);
        notifyListeners();
      } else {
        Sentry.captureMessage(
            "Error removing CoC account, status code: ${response.statusCode}, body: ${response.body}",
            level: SentryLevel.error);
      }
    } catch (e) {
      Sentry.captureException(e);
    }
  }

  /// Reorder accounts and send the updated order to the API
  Future<void> updateAccountOrder(List<String> playerTags) async {
    final token = await TokenService().getAccessToken();
    if (token == null) throw Exception("User not authenticated");

    final response = await http.put(
      Uri.parse("${ApiService.apiUrlV2}/users/reorder-coc-accounts"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"ordered_tags": playerTags}),
    );

    if (response.statusCode != 200) {
      Sentry.captureMessage(
          "Failed to update account order, status code: ${response.statusCode}, body: ${response.body}",
          level: SentryLevel.error);
    }
  }

  void setSelectedTag(String? tag) async {
    final previousTag = _selectedTag;
    _selectedTag = tag;
    selectedTagNotifier.value = tag;
    
    // Persist to SharedPreferences for widget access
    if (tag != null) {
      try {
        await storePrefs('selectedTag', tag);
        
        // Check if we need to refresh the war widget due to clan change
        await _checkAndRefreshWarWidget(previousTag, tag);
      } catch (e) {
        print("⚠️ Could not store selected tag: $e");
        // Continue without storing - not critical for app functionality
      }
    }
    
    notifyListeners();
  }

  void initializeSelectedTag() {
    if (_cocAccounts.isNotEmpty && selectedTagNotifier.value == null) {
      setSelectedTag(_cocAccounts.first["player_tag"]);
    }
  }

  // Load selected tag from SharedPreferences on app start
  Future<void> loadSelectedTag() async {
    try {
      final storedTag = await getPrefs('selectedTag');
      if (storedTag != null && storedTag.isNotEmpty) {
        _selectedTag = storedTag;
        selectedTagNotifier.value = storedTag;
        print("🔄 Loaded selected tag from preferences: $storedTag");
      }
    } catch (e) {
      print("⚠️ Could not load selected tag from preferences: $e");
      // Continue without stored tag - will use first account as default
    }
  }

  Future<void> refreshSelectedAccountData() async {
    // To Do: Implement
  }

  List<String> getAccountTags() {
    return _cocAccounts
        .map((account) => account["player_tag"].toString())
        .toList();
  }

  Future<void> loadApiData(
    PlayerService playerService,
    ClanService clanService,
    WarCwlService warCwlService,
  ) async {
    final transaction = Sentry.startTransaction(
      "CocAccountService.loadApiData",
      "task",
      bindToScope: true,
    );

    try {
      final spanFetchAccounts = transaction.startChild("fetchCocAccounts");
      await fetchCocAccounts();
      spanFetchAccounts.finish();

      if (cocAccounts.isEmpty) {
        transaction.finish(status: SpanStatus.ok());
        return;
      }

      final List<String> playerTags = cocAccounts
          .map((account) => account["player_tag"].toString())
          .toList();

      transaction.setTag("playerTags", playerTags.toString());
      transaction.setTag("playerTagsCount", playerTags.length.toString());

      // Use the new optimized bulk endpoint
      final spanBulkLoad = transaction.startChild("bulkAccountInitialization");
      await _loadDataWithBulkEndpoint(playerTags, playerService, clanService, warCwlService);
      spanBulkLoad.finish();

      transaction.finish(status: SpanStatus.ok());
      initializeSelectedTag();
    } on HttpException catch (e) {
      if (e.message.contains("503")) {
        throw Exception("503");
      } else if (e.message.contains("500")) {
        throw Exception("500");
      } else {
        rethrow;
      }
    } catch (e, stack) {
      transaction.throwable = e;
      transaction.status = SpanStatus.internalError();
      transaction.finish();
      Sentry.captureException(e, stackTrace: stack);
      rethrow;
    }
  }

  /// Optimized bulk data loading using the new API endpoint
  Future<void> _loadDataWithBulkEndpoint(
    List<String> playerTags,
    PlayerService playerService,
    ClanService clanService,
    WarCwlService warCwlService,
  ) async {
    final token = await TokenService().getAccessToken();
    if (token == null) throw Exception("User not authenticated");

    print("🚀 Using optimized bulk endpoint for ${playerTags.length} players");

    try {
      final response = await http.post(
        Uri.parse("${ApiService.apiUrlV2}/app/initialization"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"player_tags": playerTags}),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);

        print("✅ Bulk data loaded successfully");
        
        // Debug: Print what data we received
        print("🔍 Debug - Data keys received: ${data.keys.toList()}");
        if (data["clans"] != null) {
          final clansData = data["clans"] as Map<String, dynamic>;
          print("🔍 Debug - Clans data keys: ${clansData.keys.toList()}");
          print("🔍 Debug - War data count: ${clansData['war_data']?.length ?? 0}");
          print("🔍 Debug - War log data count: ${clansData['war_log_data']?.length ?? 0}");
          print("🔍 Debug - Clan war stats count: ${clansData['clan_war_stats']?.length ?? 0}");
        }

        // Process player data
        if (data["players"] != null) {
          playerService.processBulkPlayerData(data["players"], data["players_basic"]);
        }

        // Process clan data
        if (data["clans"] != null && data["clan_tags"] != null) {
          final clanTags = List<String>.from(data["clan_tags"]);
          await clanService.processBulkClanData(data["clans"], clanTags);
        }

        // Process war stats
        if (data["war_stats"] != null) {
          playerService.processBulkWarStats(data["war_stats"]);
        }

        // Process war/CWL data
        if (data["clans"] != null && data["clans"]["war_data"] != null) {
          final warData = data["clans"]["war_data"] as List<dynamic>;
          print("🔄 Processing ${warData.length} war data items");
          warCwlService.processBulkWarData(warData);
        }

        print("🔗 Linking data relationships...");
        
        // Link relationships
        final clanTags = List<String>.from(data["clan_tags"] ?? []);
        if (clanTags.isNotEmpty) {
          playerService.linkClansToPlayer(
            playerService.profiles,
            clanService.clans.values.toList(),
          );

          clanService.linkWarsToClans(
            clanService.clans.values.toList(),
            warCwlService.summaries.values.toList(),
          );

          clanService.linkJoinLeaveToClans();
          clanService.linkCapitalToClans();
          clanService.linkWarLogToClans();
          clanService.linkWarStatsToClans();
        }

        print("✅ All data linked successfully");
      } else if (response.statusCode == 503 || response.statusCode == 500) {
        throw HttpException(response.statusCode.toString(), uri: response.request!.url);
      } else {
        print("❌ Bulk endpoint failed, falling back to individual calls");
        await _loadDataWithFallback(playerTags, playerService, clanService, warCwlService);
      }
    } catch (e) {
      print("❌ Bulk endpoint error: $e, falling back to individual calls");
      await _loadDataWithFallback(playerTags, playerService, clanService, warCwlService);
    }
  }

  /// Fallback to the original individual API calls if bulk endpoint fails
  Future<void> _loadDataWithFallback(
    List<String> playerTags,
    PlayerService playerService,
    ClanService clanService,
    WarCwlService warCwlService,
  ) async {
    print("🔄 Using fallback individual API calls");

    final clanTagsByPlayer = await playerService.initPlayerData(playerTags);

    final Set<String> clanTags = playerService.profiles
        .map((profile) => profile.clanTag)
        .where((tag) => tag.isNotEmpty)
        .toSet();

    await Future.wait([
      playerService.loadPlayerData(playerTags, clanTagsByPlayer),
      playerService.loadPlayerWarStats(playerTags),
      if (clanTags.isNotEmpty) clanService.loadAllClanData(clanTags.toList()),
      if (clanTags.isNotEmpty) clanService.loadClanJoinLeaveData(clanTags.toList()),
      if (clanTags.isNotEmpty) warCwlService.loadAllWarData(clanTags.toList()),
      if (clanTags.isNotEmpty) clanService.loadCapitalData(clanTags.toList(), 10),
      if (clanTags.isNotEmpty) clanService.loadWarLogData(clanTags.toList()),
      if (clanTags.isNotEmpty) clanService.loadClanWarStatsData(clanTags.toList()),
    ]);

    // Link relationships (same as before)
    if (clanTags.isNotEmpty) {
      playerService.linkClansToPlayer(
        playerService.profiles,
        clanService.clans.values.toList(),
      );

      clanService.linkWarsToClans(
        clanService.clans.values.toList(),
        warCwlService.summaries.values.toList(),
      );

      clanService.linkJoinLeaveToClans();
      clanService.linkCapitalToClans();
      clanService.linkWarLogToClans();
      clanService.linkWarStatsToClans();
    }
  }

  // Check if clan changed and refresh war widget if needed (non-blocking)
  Future<void> _checkAndRefreshWarWidget(String? previousTag, String newTag) async {
    try {
      // Only refresh widget on mobile platforms
      if (kIsWeb) return;
      
      // Skip if no previous tag (first time selection)
      if (previousTag == null) return;
      
      // Get clan tags for both players from cache
      final previousClanTag = await getPrefs('player_${previousTag}_clan_tag');
      final newClanTag = await getPrefs('player_${newTag}_clan_tag');
      
      print("🔄 Account switch - Previous: $previousTag (clan: $previousClanTag) → New: $newTag (clan: $newClanTag)");
      
      // If clan tags are different, refresh the war widget in background
      if (previousClanTag != newClanTag) {
        print("🔄 Clan changed! Refreshing war widget in background...");
        // Don't await - let it run in background
        WarWidgetService.handleWidgetRefresh().catchError((error) {
          print("❌ Background widget refresh error: $error");
        });
      } else {
        print("✅ Same clan, no widget refresh needed");
      }
    } catch (e) {
      print("⚠️ Error checking clan change: $e");
      // If there's an error, refresh anyway to be safe (in background)
      WarWidgetService.handleWidgetRefresh().catchError((error) {
        print("❌ Background widget refresh error: $error");
      });
    }
  }

  void clearAccounts() {
    _cocAccounts.clear();
    _isLoading = false;
    _selectedTag = null;
    selectedTagNotifier.value = null;
    profiles.clear();
    notifyListeners();
  }
}
