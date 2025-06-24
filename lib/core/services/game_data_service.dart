import 'dart:convert';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:http/http.dart' as http;

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
    try {
      final response = await http.get(Uri.parse("$_baseUrl/$fileName"));
      if (response.statusCode == 200) {
        storage.addAll(jsonDecode(response.body));
        print("✅ Loaded : $fileName");
      } else {
        print("❌ Erreur ${response.statusCode} lors du chargement de $fileName");
      }
    } catch (e) {
      print("❌ Exception dans _fetchJson pour $fileName : $e");
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
