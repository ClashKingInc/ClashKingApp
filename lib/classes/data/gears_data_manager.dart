import 'dart:convert';
import 'package:http/http.dart' as http;

class GearDataManager {
  static final GearDataManager _instance = GearDataManager._internal();
  Map<String, Map<String, String>> gearUrlsAndTypes = {};
  bool _loaded = false;

  factory GearDataManager() {
    return _instance;
  }

  GearDataManager._internal();

  Future<void> loadGearsData() async {
    if (!_loaded) {
      final response = await http.get(Uri.parse('https://assets.clashk.ing/app-data/gears_data.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['gears'] != null && data['gears'] is Map) {
          var gear = data['gears'] as Map<String, dynamic>;
          gearUrlsAndTypes = { for (var name in gear.keys) name: {'url': gear[name]['url'], 'type': gear[name]['type'], 'hero': gear[name]['hero'], 'rarity': gear[name]['rarity']} };
          _loaded = true;
        } else {
          throw Exception('gear data is missing or not properly formatted');
        }
      } else {
        throw Exception('Failed to fetch troop data');
      }
    }
  }

  Map<String, String> getGearInfo(String gearName) {
    return gearUrlsAndTypes[gearName] ?? {'url': 'https://assets.clashk.ing/icons/Unknown_person.jpg', 'type': 'unknown', 'hero': 'unknown', 'rarity': '1'};
  }
}
