import 'dart:async';
import 'dart:convert';

import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkService extends ChangeNotifier {
  static const String _playerBookmarksKey = 'bookmarked_players_v1';
  static const String _clanBookmarksKey = 'bookmarked_clans_v1';

  BookmarkService() {
    unawaited(load());
  }

  bool _loaded = false;
  List<BookmarkedPlayer> _players = [];
  List<BookmarkedClan> _clans = [];

  bool get loaded => _loaded;
  List<BookmarkedPlayer> get players => List.unmodifiable(_players);
  List<BookmarkedClan> get clans => List.unmodifiable(_clans);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _players =
        prefs
            .getStringList(_playerBookmarksKey)
            ?.map((value) => BookmarkedPlayer.tryDecode(value))
            .whereType<BookmarkedPlayer>()
            .toList() ??
        [];
    _clans =
        prefs
            .getStringList(_clanBookmarksKey)
            ?.map((value) => BookmarkedClan.tryDecode(value))
            .whereType<BookmarkedClan>()
            .toList() ??
        [];
    _loaded = true;
    notifyListeners();
  }

  bool isPlayerBookmarked(String tag) {
    return _players.any((player) => player.tag == tag);
  }

  bool isClanBookmarked(String tag) {
    return _clans.any((clan) => clan.tag == tag);
  }

  Future<void> togglePlayer(Player player) async {
    if (isPlayerBookmarked(player.tag)) {
      await removePlayer(player.tag);
    } else {
      await addPlayer(BookmarkedPlayer.fromPlayer(player));
    }
  }

  Future<void> addPlayer(BookmarkedPlayer player) async {
    _players.removeWhere((existing) => existing.tag == player.tag);
    _players.insert(0, player);
    await _savePlayers();
  }

  Future<void> removePlayer(String tag) async {
    _players.removeWhere((player) => player.tag == tag);
    await _savePlayers();
  }

  Future<void> reorderPlayer(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _players.length) return;
    if (newIndex < 0 || newIndex > _players.length) return;
    final player = _players.removeAt(oldIndex);
    _players.insert(newIndex, player);
    await _savePlayers();
  }

  Future<void> toggleClan(Clan clan) async {
    if (isClanBookmarked(clan.tag)) {
      await removeClan(clan.tag);
    } else {
      await addClan(BookmarkedClan.fromClan(clan));
    }
  }

  Future<void> addClan(BookmarkedClan clan) async {
    _clans.removeWhere((existing) => existing.tag == clan.tag);
    _clans.insert(0, clan);
    await _saveClans();
  }

  Future<void> removeClan(String tag) async {
    _clans.removeWhere((clan) => clan.tag == tag);
    await _saveClans();
  }

  Future<void> reorderClan(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _clans.length) return;
    if (newIndex < 0 || newIndex > _clans.length) return;
    final clan = _clans.removeAt(oldIndex);
    _clans.insert(newIndex, clan);
    await _saveClans();
  }

  Future<void> _savePlayers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _playerBookmarksKey,
      _players.map((player) => jsonEncode(player.toJson())).toList(),
    );
    notifyListeners();
  }

  Future<void> _saveClans() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _clanBookmarksKey,
      _clans.map((clan) => jsonEncode(clan.toJson())).toList(),
    );
    notifyListeners();
  }
}

class BookmarkedPlayer {
  const BookmarkedPlayer({
    required this.tag,
    required this.name,
    required this.townHallLevel,
    required this.townHallPic,
    required this.clanTag,
    required this.clanName,
    required this.trophies,
    required this.league,
    required this.leagueUrl,
  });

  final String tag;
  final String name;
  final int townHallLevel;
  final String townHallPic;
  final String clanTag;
  final String clanName;
  final int trophies;
  final String league;
  final String leagueUrl;

  factory BookmarkedPlayer.fromPlayer(Player player) {
    return BookmarkedPlayer(
      tag: player.tag,
      name: player.name,
      townHallLevel: player.townHallLevel,
      townHallPic: player.townHallPic,
      clanTag: player.clanTag,
      clanName: player.clan?.name ?? player.clanOverview.name,
      trophies: player.trophies,
      league: player.league,
      leagueUrl: player.leagueUrl,
    );
  }

  static BookmarkedPlayer? tryDecode(String value) {
    try {
      final data = jsonDecode(value);
      if (data is! Map<String, dynamic>) return null;
      return BookmarkedPlayer.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  factory BookmarkedPlayer.fromJson(Map<String, dynamic> json) {
    return BookmarkedPlayer(
      tag: json['tag']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Player',
      townHallLevel: json['townHallLevel'] is int
          ? json['townHallLevel'] as int
          : int.tryParse(json['townHallLevel']?.toString() ?? '') ?? 0,
      townHallPic: json['townHallPic']?.toString() ?? '',
      clanTag: json['clanTag']?.toString() ?? '',
      clanName: json['clanName']?.toString() ?? '',
      trophies: json['trophies'] is int
          ? json['trophies'] as int
          : int.tryParse(json['trophies']?.toString() ?? '') ?? 0,
      league: json['league']?.toString() ?? '',
      leagueUrl: json['leagueUrl']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'townHallLevel': townHallLevel,
      'townHallPic': townHallPic,
      'clanTag': clanTag,
      'clanName': clanName,
      'trophies': trophies,
      'league': league,
      'leagueUrl': leagueUrl,
    };
  }
}

class BookmarkedClan {
  const BookmarkedClan({
    required this.tag,
    required this.name,
    required this.badgeUrl,
    required this.clanLevel,
    required this.memberCount,
  });

  final String tag;
  final String name;
  final String badgeUrl;
  final int clanLevel;
  final int memberCount;

  factory BookmarkedClan.fromClan(Clan clan) {
    return BookmarkedClan(
      tag: clan.tag,
      name: clan.name,
      badgeUrl: clan.badgeUrls.medium,
      clanLevel: clan.clanLevel,
      memberCount: clan.members,
    );
  }

  static BookmarkedClan? tryDecode(String value) {
    try {
      final data = jsonDecode(value);
      if (data is! Map<String, dynamic>) return null;
      return BookmarkedClan.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  factory BookmarkedClan.fromJson(Map<String, dynamic> json) {
    return BookmarkedClan(
      tag: json['tag']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Clan',
      badgeUrl: json['badgeUrl']?.toString() ?? '',
      clanLevel: json['clanLevel'] is int
          ? json['clanLevel'] as int
          : int.tryParse(json['clanLevel']?.toString() ?? '') ?? 0,
      memberCount: json['memberCount'] is int
          ? json['memberCount'] as int
          : int.tryParse(json['memberCount']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'name': name,
      'badgeUrl': badgeUrl,
      'clanLevel': clanLevel,
      'memberCount': memberCount,
    };
  }
}
