import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/functions.dart';

class JoinLeaveItem {
  final String name;
  final String tag;
  final int th;
  final DateTime time;
  final String clan;
  final String type;
  String townHallPic = "";

  JoinLeaveItem({
    required this.name,
    required this.tag,
    required this.th,
    required this.time,
    required this.clan,
    required this.type,
  });

  factory JoinLeaveItem.fromJson(Map<String, dynamic> json) {
    return JoinLeaveItem(
      name: json['name'],
      tag: json['tag'],
      th: json['th'],
      time: DateTime.parse(json['time']),
      clan: json['clan'],
      type: json['type'],
    );
  }
}

class JoinLeaveClan {
  final List<JoinLeaveItem> items;
  late int joinNumber = 0;
  late int leaveNumber = 0;

  JoinLeaveClan({required this.items});

  factory JoinLeaveClan.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List;
    List<JoinLeaveItem> itemsList =
        list.map((i) => JoinLeaveItem.fromJson(i)).toList();
    return JoinLeaveClan(items: itemsList);
  }
}

class JoinLeaveClanService {
  static Future<JoinLeaveClan> fetchJoinLeaveData(String clanTag, String startTime) async {
    clanTag = clanTag.replaceAll('#', '!');
    final response = await http
        .get(Uri.parse('https://api.clashking.xyz/clan/$clanTag/join-leave?timestamp_start=$startTime&time_stamp_end=9999999999&limit=1500'));
    if (response.statusCode == 200) {
      JoinLeaveClan joinLeaveClan =
          JoinLeaveClan.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      for (var item in joinLeaveClan.items) {
        item.townHallPic = await fetchPlayerTownHallByTownHallLevel(item.th);
        if (item.type == 'join') {
          joinLeaveClan.joinNumber+=1;
        } else {
          joinLeaveClan.leaveNumber+=1;
        }
      }
      return joinLeaveClan;
    } else {
      throw Exception('Failed to load join leave data');
    }
  }
}
