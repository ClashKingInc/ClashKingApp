import 'dart:convert';
import 'package:http/http.dart' as http;

class PetsDataManager {
  static final PetsDataManager _instance = PetsDataManager._internal();
  Map<String, Map<String, String>> petUrlsAndTypes = {};
  bool _loaded = false;

  factory PetsDataManager() {
    return _instance;
  }

  PetsDataManager._internal();

  Future<void> loadPetsData() async {
    if (!_loaded) {
      final response = await http.get(Uri.parse('https://assets.clashk.ing/app-data/pets_data.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['pets'] != null && data['pets'] is Map) {
          var pet = data['pets'] as Map<String, dynamic>;
          petUrlsAndTypes = { for (var name in pet.keys) name: {'url': pet[name]['url'], 'type': pet[name]['type']} };
          _loaded = true;
        } else {
          throw Exception('pet data is missing or not properly formatted');
        }
      } else {
        throw Exception('Failed to fetch troop data');
      }
    }
  }

  Map<String, String> getPetInfo(String gearName) {
    return petUrlsAndTypes[gearName] ?? {'url': 'https://assets.clashk.ing/icons/Unknown_person.jpg', 'type': 'unknown', 'hero': 'unknown'};
  }
}
