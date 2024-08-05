import 'package:clashkingapp/classes/profile/todo/to_do_list.dart';
import 'package:clashkingapp/classes/account/accounts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ToDoService {
  static Future<void> fetchPlayerToDoData(List<String> tags, Accounts accounts) async {
    final tagsParameter = tags.asMap().entries.map((entry) {
      String encodedTag = entry.value.replaceAll('#', '%23');
      return '${entry.key == 0 ? '' : '&'}player_tags=$encodedTag';
    }).join('');
    final response = await http.get(
        Uri.parse('https://api.clashking.xyz/player/to-do?$tagsParameter'));

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      Map<String, dynamic> jsonBody = json.decode(body);
      accounts.toDoList = await ToDoList.fromJson(jsonBody);
      accounts.isTodoInitialized = true;
    } else {
      throw Exception('Failed to load player data');
    }
  }
}
