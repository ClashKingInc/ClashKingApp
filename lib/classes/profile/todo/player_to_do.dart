import 'package:clashkingapp/classes/profile/todo/player_data.dart';

class PlayerToDoData {
  final List<PlayerData> items;

  PlayerToDoData({required this.items});

  factory PlayerToDoData.fromJson(Map<String, dynamic> json) {
    var itemList = json['items'] != null
      ? (json['items'] as List).map((itemJson) => PlayerData.fromJson(itemJson as Map<String, dynamic>)).toList()
      : [];
    return PlayerToDoData(items: itemList.cast<PlayerData>());
  }

  @override
  String toString() {
    return 'PlayerToDoData: ${items.toString()}';
  }
}