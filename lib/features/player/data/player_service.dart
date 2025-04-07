import 'dart:convert';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
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
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);

        if (data.containsKey("items") && data["items"] is List) {
          _profiles = (data["items"] as List)
              .whereType<Map<String, dynamic>>()
              .map((account) => Player.fromJson(account))
              .toList();
          print("✅ Loaded profiles: ${profiles.map((p) => p.tag).toList()}");
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

  Future<Player> getPlayerData(String playerTag) async {
    _isLoading = true;
    notifyListeners();

    final token = await TokenService().getAccessToken();
    if (token == null) throw Exception("User not authenticated");

    playerTag = playerTag.replaceAll("#", "%23");

    final response = await http.get(
      Uri.parse("${ApiService.apiUrl}/player/$playerTag/full-stats"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    try {
      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = jsonDecode(responseBody);
        return Player.fromJson(data);
      } else {
        Sentry.captureMessage("Error loading player data",
            level: SentryLevel.error);
        throw Exception("Error loading player data");
      }
    } catch (e) {
      Sentry.captureException(e);
      print("❌ Error loading player data: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void linkProfilesToClans(List<Player> profiles, List<Clan> clans) {
    for (var profile in profiles) {
      if (profile.clanTag.isEmpty) continue;
      profile.clan = clans.firstWhere((clan) => clan.tag == profile.clanTag);
      print("🔗 Linked ${profile.tag} to ${profile.clan?.name}");
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
