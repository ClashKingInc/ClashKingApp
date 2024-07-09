import 'dart:convert';
import 'package:http/http.dart' as http;

class TroopDataManager {
  static final TroopDataManager _instance = TroopDataManager._internal();
  Map<String, Map<String, String>> troopUrlsAndTypes = {};
  bool _loaded = false;

  factory TroopDataManager() {
    return _instance;
  }

  TroopDataManager._internal();

  Future<void> loadTroopsData() async {
    if (!_loaded) {
      final response = await http.get(Uri.parse('https://clashkingfiles.b-cdn.net/app-data/troops_data.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['troops'] != null && data['troops'] is Map) {
          var troops = data['troops'] as Map<String, dynamic>;
          troopUrlsAndTypes = { for (var name in troops.keys) name: {'url': troops[name]['url'], 'type': troops[name]['type']} };
          _loaded = true;
        } else {
          throw Exception('Troops data is missing or not properly formatted');
        }
      } else {
        throw Exception('Failed to fetch troop data');
      }
    }
  }

  Map<String, String> getTroopInfo(String troopName) {
    return troopUrlsAndTypes[troopName] ?? {'url': 'https://clashkingfiles.b-cdn.net/icons/Unknown_person.jpg', 'type': 'unknown'};
  }
}
