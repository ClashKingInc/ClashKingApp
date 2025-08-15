import 'dart:convert';
import 'package:http/http.dart' as http;

class GameDataManager {
  static final GameDataManager _instance = GameDataManager._internal();
  int maxTownHallLevel = 0; // Stocke le niveau max de l'hôtel de ville
  bool _isLoaded = false;

  factory GameDataManager() {
    return _instance;
  }

  GameDataManager._internal();

  /// Charge les données depuis game_data.json
  Future<void> loadGameData() async {
    if (!_isLoaded) {
      final response = await http
          .get(Uri.parse('https://assets.clashk.ing/app-data/game_data.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['max_TownHall'] != null && data['max_TownHall'] is int) {
          maxTownHallLevel = data['max_TownHall'];
          _isLoaded = true;
        } else {
          throw Exception('Game data is missing or not properly formatted');
        }
      } else {
        throw Exception('Failed to fetch game data');
      }
    }
  }

  /// Récupère le niveau max de l'hôtel de ville
  int getMaxTownHallLevel() {
    return maxTownHallLevel;
  }
}
