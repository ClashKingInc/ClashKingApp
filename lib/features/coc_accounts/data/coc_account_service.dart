import 'dart:convert';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  /// Fetches the user's linked Clash of Clans accounts from the backend.
  Future<void> fetchCocAccounts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await TokenService().getAccessToken();
      if (token == null) throw Exception("User not authenticated");

      final response = await http.get(
        Uri.parse("${ApiService.apiUrl}/users/coc-accounts"),
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
        Uri.parse("${ApiService.apiUrl}/users/add-coc-account"),
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
        Uri.parse("${ApiService.apiUrl}/users/add-coc-account-with-token"),
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
        Uri.parse("${ApiService.apiUrl}/users/remove-coc-account"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"player_tag": playerTag}),
      );

      if (response.statusCode == 200) {
        _cocAccounts.removeWhere((account) => account["tag"] == playerTag);
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
      Uri.parse("${ApiService.apiUrl}/users/reorder-coc-accounts"),
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

  void setSelectedTag(String? tag) {
    _selectedTag = tag;
    selectedTagNotifier.value = tag;
    notifyListeners();
  }

  void initializeSelectedTag() {
    if (_cocAccounts.isNotEmpty && selectedTagNotifier.value == null) {
      setSelectedTag(_cocAccounts.first["player_tag"]);
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

  Future<void> loadApiData(PlayerService playerService, ClanService clanService,
      WarCwlService warCwlService) async {
    // Get the CoC accounts
    await fetchCocAccounts();

    if (cocAccounts.isNotEmpty) {
      // Extract the player tags
      final List<String> playerTags = cocAccounts
          .map((account) => account["player_tag"].toString())
          .toList();

      // Load all player stats
      await playerService.loadPlayerData(playerTags);

      print(
          "📋 Profiles list from PlayerService: ${playerService.profiles.map((p) => p.tag).toList()}");

      final Set<String> clanTags = playerService.profiles
          .map((profile) => profile.clanTag)
          .where((tag) => tag.isNotEmpty)
          .toSet();

      if (clanTags.isNotEmpty) {
        await Future.wait([
          clanService.loadAllClanData(clanTags.toList()),
          warCwlService.loadAllWarData(clanTags.toList()),
        ]);
      }

      playerService.linkProfilesToClans(
          playerService.profiles, clanService.clans.values.toList());

      clanService.linkWarsToClans(clanService.clans.values.toList(),
          warCwlService.summaries.values.toList());

      initializeSelectedTag();
    }
  }
}
