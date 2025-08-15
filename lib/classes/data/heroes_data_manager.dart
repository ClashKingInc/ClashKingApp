import 'dart:convert';
import 'package:http/http.dart' as http;

class HeroesDataManager {
  static final HeroesDataManager _instance = HeroesDataManager._internal();
  Map<String, Map<String, String>> heroUrlsAndTypes = {};
  bool _loaded = false;

  factory HeroesDataManager() {
    return _instance;
  }

  HeroesDataManager._internal();

  Future<void> loadHeroesData() async {
    if (!_loaded) {
      final response = await http.get(Uri.parse('https://assets.clashk.ing/app-data/heroes_data.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['heroes'] != null && data['heroes'] is Map) {
          var hero = data['heroes'] as Map<String, dynamic>;
          heroUrlsAndTypes = { for (var name in hero.keys) name: {'url': hero[name]['url'], 'type': hero[name]['type']} };
          _loaded = true;
        } else {
          throw Exception('hero data is missing or not properly formatted');
        }
      } else {
        throw Exception('Failed to fetch troop data');
      }
    }
  }

  Map<String, String> getHeroInfo(String heroName) {
    return heroUrlsAndTypes[heroName] ?? {'url': 'https://assets.clashk.ing/icons/Unknown_person.jpg', 'type': 'unknown', 'hero': 'unknown'};
  }
}
