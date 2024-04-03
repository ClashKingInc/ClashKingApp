import 'dart:convert';
import 'package:http/http.dart' as http;

class PlayerLegendService{
  static Future<Map<String, dynamic>> fetchLegendData( String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/player/${tag.substring(1)}/legends'));
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      print(body);
      return json.decode(body);
    } else {
      throw Exception('Failed to load seasons data');
    }
  }}


class PlayerLegendSeasonsService {
  static Future<List<dynamic>> fetchSeasonsData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/player/${tag.substring(1)}/legend_rankings'));
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      print(body);
      return json.decode(body);
    } else {
      throw Exception('Failed to load seasons data');
    }
  }
}