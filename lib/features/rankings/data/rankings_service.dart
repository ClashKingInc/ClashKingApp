import 'dart:convert';

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/rankings/models/ranking_models.dart';
import 'package:intl/intl.dart';

class RankingsService {
  RankingsService({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

  final ApiService _apiService;

  Future<List<RankingLocation>> fetchLocations() async {
    final response = await _apiService.proxyGet('/locations');
    final decoded = _decodeSuccessful(response.statusCode, response);
    final rawItems = decoded is Map ? decoded['items'] : null;
    if (rawItems is! List) {
      throw const FormatException('Locations response does not contain items.');
    }

    final locations =
        rawItems
            .whereType<Map>()
            .map(
              (item) =>
                  RankingLocation.fromJson(Map<String, dynamic>.from(item)),
            )
            .where(
              (location) => location.id != null && location.name.isNotEmpty,
            )
            .toList(growable: false)
          ..sort((a, b) {
            if (a.isCountry != b.isCountry) return a.isCountry ? 1 : -1;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    return [const RankingLocation.worldwide(), ...locations];
  }

  Future<RankingResult> fetchRankings(RankingQuery query) async {
    final route = _routeFor(query);
    final response = route.official
        ? await _apiService.proxyGet(route.path)
        : await _apiService.getResponse(route.path);
    final decoded = _decodeSuccessful(response.statusCode, response);
    final rawItems = decoded is Map ? decoded['items'] : null;
    if (decoded == null || rawItems == null) {
      return RankingResult(
        entries: const [],
        source: query.board.source,
        limit: route.limit,
      );
    }
    if (rawItems is! List) {
      throw const FormatException('Ranking response does not contain items.');
    }

    final entries = rawItems
        .whereType<Map>()
        .map(
          (item) => RankingEntry.fromJson(
            Map<String, dynamic>.from(item),
            query.board,
          ),
        )
        .where((entry) => entry.tag.isNotEmpty)
        .toList(growable: false);
    return RankingResult(
      entries: entries,
      source: query.board.source,
      limit: route.limit,
    );
  }

  _RankingRoute _routeFor(RankingQuery query) {
    final board = query.board;
    if (query.period == RankingPeriod.history) {
      final date = DateFormat('yyyy-MM-dd').format(query.historyDate);
      final path = switch (board) {
        RankingBoard.playerHome =>
          '/ranking/player-trophies/${query.location.apiPath}/$date',
        RankingBoard.playerBuilder =>
          '/ranking/player-builder/${query.location.apiPath}/$date',
        RankingBoard.playerTownHall =>
          '/leaderboard/townhalls/${query.townHallLevel}/history/$date?limit=200',
        RankingBoard.playerRanked =>
          '/leaderboard/league/${query.leagueTier.id}/history/$date?limit=200',
        RankingBoard.clanHome =>
          '/ranking/clan-trophies/${query.location.apiPath}/$date',
        RankingBoard.clanBuilder =>
          '/ranking/clan-builder/${query.location.apiPath}/$date',
        RankingBoard.clanCapital =>
          '/ranking/clan-capital/${query.location.apiPath}/$date',
        RankingBoard.clanDonations ||
        RankingBoard.clanWarWins ||
        RankingBoard.clanWinStreak => throw UnsupportedError(
          'History is not available for ${board.name}.',
        ),
      };
      return _RankingRoute(path, limit: 200);
    }

    return switch (board) {
      RankingBoard.playerHome => _RankingRoute(
        '/locations/${query.location.apiPath}/rankings/players?limit=200',
        official: true,
        limit: 200,
      ),
      RankingBoard.playerBuilder => _RankingRoute(
        '/locations/${query.location.apiPath}/rankings/players-builder-base?limit=200',
        official: true,
        limit: 200,
      ),
      RankingBoard.playerTownHall => _RankingRoute(
        '/leaderboard/townhalls/${query.townHallLevel}?limit=500',
        limit: 500,
      ),
      RankingBoard.playerRanked => _RankingRoute(
        '/leaderboard/league/${query.leagueTier.id}?limit=500',
        limit: 500,
      ),
      RankingBoard.clanHome => _RankingRoute(
        '/locations/${query.location.apiPath}/rankings/clans?limit=200',
        official: true,
        limit: 200,
      ),
      RankingBoard.clanBuilder => _RankingRoute(
        '/locations/${query.location.apiPath}/rankings/clans-builder-base?limit=200',
        official: true,
        limit: 200,
      ),
      RankingBoard.clanCapital => _RankingRoute(
        '/locations/${query.location.apiPath}/rankings/capitals?limit=200',
        official: true,
        limit: 200,
      ),
      RankingBoard.clanDonations => _RankingRoute(
        '/leaderboard/${query.location.id}/clan/donations?limit=500',
        limit: 500,
      ),
      RankingBoard.clanWarWins => _RankingRoute(
        '/leaderboard/${query.location.id}/clan/war-wins?limit=500',
        limit: 500,
      ),
      RankingBoard.clanWinStreak => const _RankingRoute(
        '/leaderboard/clan/win-streak?limit=500',
        limit: 500,
      ),
    };
  }

  Object? _decodeSuccessful(int statusCode, dynamic response) {
    if (statusCode != 200) {
      throw RankingsRequestException(statusCode);
    }
    final body = ApiService.decodeResponseBody(response);
    if (body.trim().isEmpty) return null;
    return jsonDecode(body);
  }
}

class RankingsRequestException implements Exception {
  const RankingsRequestException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Rankings request failed ($statusCode).';
}

class _RankingRoute {
  const _RankingRoute(this.path, {this.official = false, required this.limit});

  final String path;
  final bool official;
  final int limit;
}
