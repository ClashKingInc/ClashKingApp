import 'dart:convert';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/core/utils/debug_utils.dart';

class GameDataService {
  static const String _baseUrl = "${ApiService.assetUrl}/app-data";

  static Map<String, dynamic> _petsData = {};
  static Map<String, dynamic> _heroesData = {};
  static Map<String, dynamic> _troopsData = {};
  static Map<String, dynamic> _spellsData = {};
  static Map<String, dynamic> _gearsData = {};
  static Map<String, dynamic> _leagueData = {};
  static Map<String, dynamic> _playerLeagueData = {};
  static Map<String, dynamic> _gameData = {};

  static Future<void> loadGameData() async {
    await Future.wait([
      _fetchJson("pets_data.json", _petsData),
      _fetchJson("heroes_data.json", _heroesData),
      _fetchJson("troops_data.json", _troopsData),
      _fetchJson("spells_data.json", _spellsData),
      _fetchJson("gears_data.json", _gearsData),
      _fetchJson("league_data.json", _leagueData),
      _fetchJson("player_league_data.json", _playerLeagueData),
      _fetchJson("game_data.json", _gameData),
    ]);
  }

  static Future<void> _fetchJson(String fileName, Map<String, dynamic> storage) async {
    const int maxRetries = 3;
    const Duration initialDelay = Duration(seconds: 1);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await http.get(
          Uri.parse("$_baseUrl/$fileName"),
          headers: {
            'User-Agent': 'ClashKing-App/1.0',
          },
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          storage.clear(); // Clear existing data before adding new
          storage.addAll(jsonDecode(response.body));
          DebugUtils.debugSuccess("Loaded $fileName (attempt $attempt)");
          return; // Success, exit retry loop
        } else {
          DebugUtils.debugError("HTTP ${response.statusCode} for $fileName (attempt $attempt/$maxRetries)");
          if (attempt == maxRetries) {
            DebugUtils.debugError("Failed to load $fileName after $maxRetries attempts");
            return;
          }
        }
      } catch (e) {
        DebugUtils.debugError("Exception loading $fileName (attempt $attempt/$maxRetries): ${e.toString()}");
        
        if (attempt == maxRetries) {
          DebugUtils.debugError("Final failure for $fileName after $maxRetries attempts");
          return;
        }
        
        // Calculate exponential backoff delay (1s, 2s, 4s)
        final delay = Duration(
          milliseconds: initialDelay.inMilliseconds * (1 << (attempt - 1)),
        );
        
        DebugUtils.debugInfo("🔄 Retrying $fileName in ${delay.inSeconds}s...");
        await Future.delayed(delay);
      }
    }
  }

    static bool isSuperTroop(String name) {
    return troopsData["troops"]?[name]?["type"] == "super-troop";
  }

  static bool isSiegeMachine(String name) {
    return troopsData["troops"]?[name]?["type"] == "siege-machine";
  }

  static bool isPet(String name) {
    return petsData["pets"]?.containsKey(name) ?? false;
  }

  static int getMaxTownHallLevel() {
    return gameData["max_TownHall"] ?? 0;
  }

  static Map<String, dynamic> get petsData => _petsData;
  static Map<String, dynamic> get heroesData => _heroesData;
  static Map<String, dynamic> get troopsData => _troopsData;
  static Map<String, dynamic> get spellsData => _spellsData;
  static Map<String, dynamic> get gearsData => _gearsData;
  static Map<String, dynamic> get leagueData => _leagueData;
  static Map<String, dynamic> get playerLeagueData => _playerLeagueData;
  static Map<String, dynamic> get gameData => _gameData;
}
