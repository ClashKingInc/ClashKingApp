import 'dart:convert';
import 'package:http/http.dart' as http;

class SpellsDataManager {
  static final SpellsDataManager _instance = SpellsDataManager._internal();
  Map<String, Map<String, String>> spellUrlsAndTypes = {};
  bool _loaded = false;

  factory SpellsDataManager() {
    return _instance;
  }

  SpellsDataManager._internal();

  Future<void> loadSpellsData() async {
    if (!_loaded) {
      final response = await http.get(Uri.parse('https://clashkingfiles.b-cdn.net/app-data/spells_data.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['spells'] != null && data['spells'] is Map) {
          var spell = data['spells'] as Map<String, dynamic>;
          spellUrlsAndTypes = { for (var name in spell.keys) name: {'url': spell[name]['url'], 'type': spell[name]['type']} };
          _loaded = true;
        } else {
          throw Exception('sell data is missing or not properly formatted');
        }
      } else {
        throw Exception('Failed to fetch troop data');
      }
    }
  }

  Map<String, String> getSpellInfo(String spellName) {
    return spellUrlsAndTypes[spellName] ?? {'url': 'https://clashkingfiles.b-cdn.net/icons/Unknown_person.jpg', 'type': 'unknown', 'hero': 'unknown'};
  }
}
