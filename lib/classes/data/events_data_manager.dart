import 'dart:convert';
import 'package:http/http.dart' as http;

class EventsDataManager {
  static final EventsDataManager _instance = EventsDataManager._internal();
  Map<String, dynamic> eventsData = {}; // Stocke les données des événements
  bool _isLoaded = false;

  factory EventsDataManager() {
    return _instance;
  }

  EventsDataManager._internal();

  /// Charge les données depuis events_data.json
  Future<void> loadEventsData() async {
    if (!_isLoaded) {
      final response = await http
          .get(Uri.parse('https://assets.clashk.ing/app-data/events_data.json'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          eventsData = data;
          _isLoaded = true;
        } else {
          throw Exception('Events data is not properly formatted');
        }
      } else {
        throw Exception('Failed to fetch events data');
      }
    }
  }

  /// Vérifie si les données sont chargées
  bool isLoaded() {
    return _isLoaded;
  }

  /// Récupère les informations d'un événement spécifique (par ex., wrapped)
  Map<String, dynamic>? getEventData(String eventName) {
    if (eventsData.containsKey(eventName)) {
      return eventsData[eventName] as Map<String, dynamic>;
    }
    return null;
  }

  /// Récupère la date de début d'un événement
  DateTime? getEventStartDate(String eventName) {
    final event = getEventData(eventName);
    if (event != null && event['start-date'] != null) {
      return DateTime.tryParse(event['start-date']);
    }
    return null;
  }

  /// Récupère la date de fin d'un événement
  DateTime? getEventEndDate(String eventName) {
    final event = getEventData(eventName);
    if (event != null && event['end-date'] != null) {
      return DateTime.tryParse(event['end-date']);
    }
    return null;
  }
}