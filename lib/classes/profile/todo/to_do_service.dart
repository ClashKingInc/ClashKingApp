import 'package:clashkingapp/classes/profile/todo/to_do_list.dart';
import 'package:clashkingapp/classes/profile/todo/to_do.dart';
import 'package:clashkingapp/classes/account/accounts.dart';
import 'package:clashkingapp/classes/profile/profile_info.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ToDoService {
  static Future<void> fetchBulkPlayerToDoData(
      List<String> tags, Accounts accounts) async {
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

  static Future<void> fetchPlayerToDoData(
      String tag, ProfileInfo profileInfo) async {
    tag = tag.replaceAll('#', '%23');
    final response = await http.get(
        Uri.parse('https://api.clashking.xyz/player/to-do?player_tags=$tag'));

    if (response.statusCode == 200) {
      String body = utf8.decode(response.bodyBytes);
      Map<String, dynamic> jsonBody = json.decode(body);
      profileInfo.toDo = await ToDo.createToDoFromJson(jsonBody["items"][0]);
      profileInfo.toDo!.calculateTotals(profileInfo);
    } else {
      throw Exception('Failed to load player data');
    }
  }
}