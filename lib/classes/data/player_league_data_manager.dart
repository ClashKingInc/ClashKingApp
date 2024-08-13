import 'dart:convert';
import 'package:http/http.dart' as http;

class PlayerLeagueDataManager {
  static final PlayerLeagueDataManager _instance = PlayerLeagueDataManager._internal();
  Map<String, String> leagueUrls = {};
  bool _loaded = false;

  factory PlayerLeagueDataManager() {
    return _instance;
  }

  PlayerLeagueDataManager._internal();

  Future<void> loadLeagueData() async {
    if (!_loaded) {
      final response = await http.get(Uri.parse('https://clashkingfiles.b-cdn.net/app-data/player_league_data.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Check if 'leagues' is not null and is a Map
        if (data['leagues'] != null && data['leagues'] is Map) {
          Map<String, dynamic> leagues = data['leagues'];
          leagueUrls = leagues.map((name, info) => MapEntry(name, info['url']));
          _loaded = true;
        } else {
          // Handle the case where 'leagues' is null or not a Map
          throw Exception('Leagues data is missing or not properly formatted');
        }
      } else {
        throw Exception('Failed to fetch league data');
      }
    }
  }

  String getLeagueUrl(String leagueName) {
    return leagueUrls[leagueName] ?? 'https://clashkingfiles.b-cdn.net/logos/crown-arrow-dark-bg/ClashKing-1.png';
  }
}
