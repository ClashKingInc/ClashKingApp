import 'dart:convert';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
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

  bool get isLoading => _isLoading;
  Map<String, Clan> get clans => _clans;

  Future<void> loadAllClanData(List<String> clanTags) async {
    if (clanTags.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      print("🏰 Loading clan data for tags: $clanTags");
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
      final token = await TokenService().getAccessToken();
      if (token == null) throw Exception("User not authenticated");

      final response = await http.get(
        Uri.parse("${ApiService.apiUrl}/clans/$clanTag"),
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

  Clan? getClanByTag(String clanTag) {
    return _clans[clanTag];
  }
}
