import 'dart:convert';
import 'package:http/http.dart' as http;

class WarHistoryService {
  static Future<List<dynamic>> fetchWarHistoryData(String tag) async {
    final response = await http.get(Uri.parse(
        'https://api.clashking.xyz/war/${tag.substring(1)}/previous'));
    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      return json.decode(body);
    } else {
      throw Exception('Failed to load war history data');
    }
  }
}