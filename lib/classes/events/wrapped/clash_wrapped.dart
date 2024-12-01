import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ClashWrappedData {
  final PlayerInfo playerInfo;
  final WarsData wars;
  final CWLData cwl;
  final CapitalData capital;
  final ClanActivityData clanActivity;
  final ProgressionData progression;
  final DiscordData discord;
  final CurrentClanComparison currentClanComparison;

  ClashWrappedData({
    required this.playerInfo,
    required this.wars,
    required this.cwl,
    required this.capital,
    required this.clanActivity,
    required this.progression,
    required this.discord,
    required this.currentClanComparison,
  });

  factory ClashWrappedData.fromJson(Map<String, dynamic> json) {
    return ClashWrappedData(
      playerInfo: PlayerInfo.fromJson(json['player_info']),
      wars: WarsData.fromJson(json['wars']),
      cwl: CWLData.fromJson(json['cwl']),
      capital: CapitalData.fromJson(json['capital']),
      clanActivity: ClanActivityData.fromJson(json['clan_activity']),
      progression: ProgressionData.fromJson(json['progression']),
      discord: DiscordData.fromJson(json['discord']),
      currentClanComparison:
          CurrentClanComparison.fromJson(json['current_clan_comparison']),
    );
  }
}

class PlayerInfo {
  final Map<String, dynamic> player;
  final Map<String, dynamic> comparisonPercentage;

  PlayerInfo({required this.player, required this.comparisonPercentage});

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    return PlayerInfo(
      player: json['player'],
      comparisonPercentage: json['comparison_percentage'],
    );
  }
}

class WarsData {
  final Map<String, dynamic> player;
  final Map<String, dynamic> comparisonPercentage;

  WarsData({required this.player, required this.comparisonPercentage});

  factory WarsData.fromJson(Map<String, dynamic> json) {
    return WarsData(
      player: json['player'],
      comparisonPercentage: json['comparison_percentage'],
    );
  }
}

class CWLData {
  final Map<String, dynamic> player;
  final Map<String, dynamic> comparisonPercentage;

  CWLData({required this.player, required this.comparisonPercentage});

  factory CWLData.fromJson(Map<String, dynamic> json) {
    return CWLData(
      player: json['player'],
      comparisonPercentage: json['comparison_percentage'],
    );
  }
}

class CapitalData {
  final Map<String, dynamic> player;
  final Map<String, dynamic> comparisonPercentage;

  CapitalData({required this.player, required this.comparisonPercentage});

  factory CapitalData.fromJson(Map<String, dynamic> json) {
    return CapitalData(
      player: json['player'],
      comparisonPercentage: json['comparison_percentage'],
    );
  }
}

class ClanActivityData {
  final Map<String, dynamic> player;
  final Map<String, dynamic> comparisonPercentage;

  ClanActivityData({required this.player, required this.comparisonPercentage});

  factory ClanActivityData.fromJson(Map<String, dynamic> json) {
    return ClanActivityData(
      player: json['player'],
      comparisonPercentage: json['comparison_percentage'],
    );
  }
}

class ProgressionData {
  final Map<String, dynamic> player;
  final Map<String, dynamic> comparisonPercentage;

  ProgressionData({required this.player, required this.comparisonPercentage});

  factory ProgressionData.fromJson(Map<String, dynamic> json) {
    return ProgressionData(
      player: json['player'],
      comparisonPercentage: json['comparison_percentage'],
    );
  }
}

class DiscordData {
  final Map<String, dynamic> player;
  final Map<String, dynamic> comparisonPercentage;

  DiscordData({required this.player, required this.comparisonPercentage});

  factory DiscordData.fromJson(Map<String, dynamic> json) {
    return DiscordData(
      player: json['player'],
      comparisonPercentage: json['comparison_percentage'],
    );
  }
}

class CurrentClanComparison {
  final Map<String, dynamic> player;
  final Map<String, dynamic> comparisonPercentage;

  CurrentClanComparison(
      {required this.player, required this.comparisonPercentage});

  factory CurrentClanComparison.fromJson(Map<String, dynamic> json) {
    return CurrentClanComparison(
      player: json['player'],
      comparisonPercentage: json['comparison_percentage'],
    );
  }
}

Future<ClashWrappedData> fetchWrappedData() async {
  /*apiUrl = 'https://api.clashking.xyz/v1/wrapped';
  final response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    return ClashWrappedData.fromJson(jsonData);
  } else {
    throw Exception('Failed to load wrapped data');
  }*/
  final jsonString = await rootBundle.loadString('clash_wrapped_example.json');
  final jsonData = jsonDecode(jsonString);
  return ClashWrappedData.fromJson(jsonData);
}
