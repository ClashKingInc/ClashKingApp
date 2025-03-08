import 'dart:convert';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/services/token_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/services/api_service.dart';
import 'package:clashkingapp/features/coc_accounts/models/profile_info.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ProfileService extends ChangeNotifier {
  bool _isLoading = false;
  List<ProfileInfo> _profiles = [];
  List<Map<String, dynamic>> _clans = [];

  bool get isLoading => _isLoading;
  List<ProfileInfo> get profiles => _profiles;
  List<Map<String, dynamic>> get clans => _clans;

  /// Loads all stats for the saved accounts.
  Future<void> loadPlayerData(List<String> playerTags) async {
    _isLoading = true;
    notifyListeners();

    final token = await TokenService().getAccessToken();
    if (token == null) throw Exception("User not authenticated");

    final response = await http.post(
      Uri.parse("${ApiService.apiUrl}/players/full-stats"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"player_tags": playerTags}),
    );

    try {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        _profiles = (data["items"] as List)
            .whereType<Map<String, dynamic>>() // Filtre les éléments valides
            .map((account) => ProfileInfo.fromJson(account))
            .toList();
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

  Future<void> loadClanData(List<String> clanTags) async {
    try {
      print("Loading clan data for tags: $clanTags");
      final token = await TokenService().getAccessToken();
      if (token == null) throw Exception("User not authenticated");

      final response = await http.post(
        Uri.parse("${ApiService.apiUrl}/clans/full-stats"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"clan_tags": clanTags}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _clans = List<Map<String, dynamic>>.from(data["clans"]);
      } else {
        throw Exception("Error loading clan data");
      }

      notifyListeners();
    } catch (e) {
      Sentry.captureException(e);
      print("❌ Error loading clan data: $e");
    }
  }

  Future<void> loadPlayerAndClanData(CocAccountService cocService) async {
    // Get the CoC accounts
    await cocService.fetchCocAccounts();

    if (cocService.cocAccounts.isNotEmpty) {
      // Extract the player tags
      final List<String> playerTags = cocService.cocAccounts
          .map((account) => account["player_tag"].toString())
          .toList();

      // Load all player stats
      await loadPlayerData(playerTags);

      // Extract the clan tags
      final Set<String> clanTags = profiles
          .map((profile) => profile.clanTag)
          .where((tag) => tag.isNotEmpty)
          .toSet();

      // Load all clan stats
      if (clanTags.isNotEmpty) {
        await loadClanData(clanTags.toList());
      }
      cocService.initializeSelectedTag();
    }
  }
}
