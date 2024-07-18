import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:clashkingapp/classes/profile/legend/spot_data.dart';

class LegendSeason {
  final String tag;
  final String name;
  final int expLevel;
  final int trophies;
  final int attackWins;
  final int defenseWins;
  final int rank;
  final Clan clan;
  final String season;
  final int? townHallLevel;

  LegendSeason({
    required this.tag,
    required this.name,
    required this.expLevel,
    required this.trophies,
    required this.attackWins,
    required this.defenseWins,
    required this.rank,
    required this.clan,
    required this.season,
    this.townHallLevel,
  });

  factory LegendSeason.fromJson(Map<String, dynamic> json) {
    return LegendSeason(
      tag: json['tag'],
      name: json['name'],
      expLevel: json['expLevel'],
      trophies: json['trophies'],
      attackWins: json['attackWins'],
      defenseWins: json['defenseWins'],
      rank: json['rank'],
      clan: Clan.fromJson(json['clan']),
      season: json['season'],
      townHallLevel: json['townHallLevel'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'expLevel': expLevel,
      'trophies': trophies,
      'attackWins': attackWins,
      'defenseWins': defenseWins,
      'rank': rank,
      'clan': clan.toJson(),
      'season': season,
      'townHallLevel': townHallLevel,
    };
  }

  SpotData toSpotData() {
    double x = DateTime.parse(season + '-01').millisecondsSinceEpoch.toDouble();
    double y = trophies.toDouble();
    return SpotData(x: x, y: y);
  }
}

class Clan {
  final String tag;
  final String name;
  final BadgeUrls badgeUrls;

  Clan({
    required this.tag,
    required this.name,
    required this.badgeUrls,
  });

  factory Clan.fromJson(Map<String, dynamic> json) {
    return Clan(
      tag: json['tag'],
      name: json['name'],
      badgeUrls: BadgeUrls.fromJson(json['badgeUrls']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'badgeUrls': badgeUrls.toJson(),
    };
  }
}

class BadgeUrls {
  final String small;
  final String large;
  final String medium;

  BadgeUrls({
    required this.small,
    required this.large,
    required this.medium,
  });

  factory BadgeUrls.fromJson(Map<String, dynamic> json) {
    return BadgeUrls(
      small: json['small'],
      large: json['large'],
      medium: json['medium'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'small': small,
      'large': large,
      'medium': medium,
    };
  }
}

Future<List<LegendSeason>> fetchSeasonsData(String tag) async {
  final response = await http.get(Uri.parse(
      'https://api.clashking.xyz/player/${tag.substring(1)}/legend_rankings'));

  if (response.statusCode == 200) {
    String body = utf8.decode(response.bodyBytes);
    List<dynamic> jsonData = json.decode(body);
    return jsonData.map((data) => LegendSeason.fromJson(data)).toList();
  } else {
    throw Exception('Failed to load seasons data');
  }
}