import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/clan/models/clan.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BookmarkService extends ChangeNotifier {
  BookmarkService({ApiService? apiService})
    : _apiService = apiService ?? ApiService() {
    unawaited(load());
  }

  final ApiService _apiService;
  bool _loaded = false;
  int _loadGeneration = 0;
  String? _currentUserId;
  List<BookmarkedPlayer> _players = [];
  List<BookmarkedClan> _clans = [];

  bool get loaded => _loaded;
  List<BookmarkedPlayer> get players => List.unmodifiable(_players);
  List<BookmarkedClan> get clans => List.unmodifiable(_clans);

  void setCurrentUserId(String? userId) {
    final normalizedUserId = userId?.trim();
    final nextUserId = normalizedUserId == null || normalizedUserId.isEmpty
        ? null
        : normalizedUserId;
    if (_currentUserId == nextUserId) return;
    _currentUserId = nextUserId;
    _invalidateLoadedState();
  }

  void _invalidateLoadedState() {
    _loadGeneration++;
    _loaded = false;
  }

  Future<void> load() async {
    final loadGeneration = ++_loadGeneration;
    if (!_hasCurrentUser) {
      if (loadGeneration != _loadGeneration) return;
      _players = [];
      _clans = [];
      _loaded = false;
      return;
    }

    final userId = Uri.encodeComponent(_currentUserId!);
    final responses = await Future.wait([
      _apiService.getResponse(
        '/links/$userId/bookmarks?type=player',
        requiresAuth: true,
      ),
      _apiService.getResponse(
        '/links/$userId/bookmarks?type=clan',
        requiresAuth: true,
      ),
    ]);

    final players = _decodeBookmarkItems(
      responses[0],
    ).map(BookmarkedPlayer.fromApiJson).toList();
    final clans = _decodeBookmarkItems(
      responses[1],
    ).map(BookmarkedClan.fromApiJson).toList();
    if (loadGeneration != _loadGeneration) return;
    _players = players;
    _clans = clans;
    _loaded = true;
    notifyListeners();
  }

  bool get _hasCurrentUser {
    final userId = _currentUserId;
    return userId != null && userId.isNotEmpty;
  }

  List<Map<String, dynamic>> _decodeBookmarkItems(http.Response response) {
    // The remote bookmarks endpoint is optional/newer API surface. A 404 means
    // the user has no server-side bookmark resource yet, or the deployed API
    // does not expose this typed route. Bookmarks should not block app startup.
    if (response.statusCode == 404) {
      return const [];
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to load bookmarks (${response.statusCode})',
        uri: response.request?.url,
      );
    }

    final data = jsonDecode(ApiService.decodeResponseBody(response));
    if (data is! Map<String, dynamic> || data['items'] is! List) {
      throw const FormatException('Invalid bookmarks payload');
    }

    return (data['items'] as List).whereType<Map<String, dynamic>>().toList();
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
    final previous = List<BookmarkedPlayer>.from(_players);
    _players.removeWhere((existing) => existing.tag == player.tag);
    _players.insert(0, player);
    notifyListeners();

    try {
      if (_hasCurrentUser) {
        await _createBookmark('player', player.tag);
      } else {
        throw UnauthorizedException('User not authenticated');
      }
    } catch (_) {
      _players = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removePlayer(String tag) async {
    final previous = List<BookmarkedPlayer>.from(_players);
    _players.removeWhere((player) => player.tag == tag);
    notifyListeners();

    try {
      if (_hasCurrentUser) {
        await _deleteBookmark('player', tag);
      } else {
        throw UnauthorizedException('User not authenticated');
      }
    } catch (_) {
      _players = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reorderPlayer(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _players.length) return;
    if (newIndex < 0 || newIndex > _players.length) return;
    final previous = List<BookmarkedPlayer>.from(_players);
    final player = _players.removeAt(oldIndex);
    _players.insert(newIndex, player);
    notifyListeners();

    try {
      if (_hasCurrentUser) {
        await _saveBookmarkOrder(
          'player',
          _players.map((player) => player.tag).toList(growable: false),
        );
      } else {
        throw UnauthorizedException('User not authenticated');
      }
    } catch (_) {
      _players = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleClan(Clan clan) async {
    if (isClanBookmarked(clan.tag)) {
      await removeClan(clan.tag);
    } else {
      await addClan(BookmarkedClan.fromClan(clan));
    }
  }

  Future<void> addClan(BookmarkedClan clan) async {
    final previous = List<BookmarkedClan>.from(_clans);
    _clans.removeWhere((existing) => existing.tag == clan.tag);
    _clans.insert(0, clan);
    notifyListeners();

    try {
      if (_hasCurrentUser) {
        await _createBookmark('clan', clan.tag);
      } else {
        throw UnauthorizedException('User not authenticated');
      }
    } catch (_) {
      _clans = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> removeClan(String tag) async {
    final previous = List<BookmarkedClan>.from(_clans);
    _clans.removeWhere((clan) => clan.tag == tag);
    notifyListeners();

    try {
      if (_hasCurrentUser) {
        await _deleteBookmark('clan', tag);
      } else {
        throw UnauthorizedException('User not authenticated');
      }
    } catch (_) {
      _clans = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reorderClan(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _clans.length) return;
    if (newIndex < 0 || newIndex > _clans.length) return;
    final previous = List<BookmarkedClan>.from(_clans);
    final clan = _clans.removeAt(oldIndex);
    _clans.insert(newIndex, clan);
    notifyListeners();

    try {
      if (_hasCurrentUser) {
        await _saveBookmarkOrder(
          'clan',
          _clans.map((clan) => clan.tag).toList(growable: false),
        );
      } else {
        throw UnauthorizedException('User not authenticated');
      }
    } catch (_) {
      _clans = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _createBookmark(String type, String tag) async {
    final response = await _apiService.postResponse(
      _bookmarksEndpoint(),
      body: {'type': type, 'tag': tag},
      requiresAuth: true,
    );
    _throwOnBookmarkFailure(response, 'create');
  }

  Future<void> _deleteBookmark(String type, String tag) async {
    final response = await _apiService.deleteResponse(
      _bookmarkItemEndpoint(type, tag),
      requiresAuth: true,
    );
    _throwOnBookmarkFailure(response, 'delete');
  }

  Future<void> _saveBookmarkOrder(String type, List<String> tags) async {
    final response = await _apiService.putResponse(
      '${_bookmarksEndpoint()}/order',
      body: {'type': type, 'ordered_tags': tags},
      requiresAuth: true,
    );
    _throwOnBookmarkFailure(response, 'reorder');
  }

  String _bookmarksEndpoint() {
    final userId = Uri.encodeComponent(_currentUserId ?? '');
    return '/links/$userId/bookmarks';
  }

  String _bookmarkItemEndpoint(String type, String tag) {
    return '${_bookmarksEndpoint()}/$type/${Uri.encodeComponent(tag)}';
  }

  void _throwOnBookmarkFailure(http.Response response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    throw HttpException(
      'Failed to $action bookmark (${response.statusCode})',
      uri: response.request?.url,
    );
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

  factory BookmarkedPlayer.fromApiJson(Map<String, dynamic> json) {
    final tag = json['player_tag']?.toString() ?? json['tag']?.toString() ?? '';
    return BookmarkedPlayer(
      tag: tag,
      name: tag.isEmpty ? 'Unknown Player' : tag,
      townHallLevel: 0,
      townHallPic: '',
      clanTag: '',
      clanName: '',
      trophies: 0,
      league: '',
      leagueUrl: '',
    );
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

  factory BookmarkedClan.fromApiJson(Map<String, dynamic> json) {
    final tag = json['clan_tag']?.toString() ?? json['tag']?.toString() ?? '';
    return BookmarkedClan(
      tag: tag,
      name: tag.isEmpty ? 'Unknown Clan' : tag,
      badgeUrl: '',
      clanLevel: 0,
      memberCount: 0,
    );
  }
}
