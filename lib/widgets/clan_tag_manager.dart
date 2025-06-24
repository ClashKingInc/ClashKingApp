import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/widgets/war_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Manages clan tag synchronization when user switches accounts
class ClanTagManager {
  static final ClanTagManager _instance = ClanTagManager._internal();
  factory ClanTagManager() => _instance;
  ClanTagManager._internal();

  /// Call this whenever the user switches to a different CoC account
  static Future<void> onAccountChanged(String newPlayerTag) async {
    try {
      print("🔄 Account changed to: $newPlayerTag");
      
      // Get the new player's clan tag
      final newClanTag = await _getPlayerClanTag(newPlayerTag);
      
      if (newClanTag != null && newClanTag.isNotEmpty) {
        // Store the new clan tag
        await storePrefs('clanTag', newClanTag);
        print("✅ Updated clan tag to: $newClanTag");
        
        // Update the war widget immediately
        await WarWidgetService.handleWidgetRefresh();
      } else {
        // Player is not in a clan
        await storePrefs('clanTag', '');
        print("⚠️ Player not in a clan, cleared clan tag");
        
        // Still update widget to show "not in clan" state
        await WarWidgetService.handleWidgetRefresh();
      }
      
    } catch (e) {
      print("❌ Error updating clan tag for new account: $e");
    }
  }

  /// Get clan tag from player data via API
  static Future<String?> _getPlayerClanTag(String playerTag) async {
    try {
      final token = await TokenService().getAccessToken();
      if (token == null) {
        print("⚠️ User not authenticated");
        return null;
      }

      final cleanTag = playerTag.replaceAll('#', '');
      final response = await http.get(
        Uri.parse("${ApiService.apiUrlV2}/player/$cleanTag/basic"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clanTag = data['clan_tag'];
        return clanTag;
      } else {
        print("⚠️ Failed to get player data: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching player clan tag: $e");
      return null;
    }
  }

  /// Call this to manually sync clan tag for current selected player
  static Future<void> syncClanTag() async {
    try {
      final selectedPlayerTag = await getPrefs('selectedTag');
      if (selectedPlayerTag != null && selectedPlayerTag.isNotEmpty) {
        await onAccountChanged(selectedPlayerTag);
      }
    } catch (e) {
      print("❌ Error syncing clan tag: $e");
    }
  }
}