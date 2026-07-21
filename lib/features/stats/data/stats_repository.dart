import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/stats/models/stats_models.dart';

class StatsRepository {
  StatsRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

  final ApiService _apiService;

  Future<StatsOverviewResponse> loadOverview(StatsDateFilter dates) async {
    final query = Uri(
      queryParameters: {
        'start_date': StatsDateFilter.formatDate(dates.start),
        'end_date': StatsDateFilter.formatDate(dates.end),
      },
    ).query;
    final json = await _apiService.get(
      '/stats/overview?$query',
      requiresAuth: false,
    );
    return StatsOverviewResponse.fromJson(json);
  }

  Future<StatsPlayerCountsResponse> loadPlayerCounts() async {
    final responses = await Future.wait([
      _apiService.get('/counts/players/town-halls', requiresAuth: false),
      _apiService.get('/counts/players/builder-halls', requiresAuth: false),
      _apiService.get('/counts/players/league-tiers', requiresAuth: false),
    ]);
    return StatsPlayerCountsResponse(
      townHalls: decodeStatsGroupedCounts(responses[0], 'townhall_level'),
      builderHalls: decodeStatsGroupedCounts(responses[1], 'builderhall_level'),
      leagueTiers: decodeStatsGroupedCounts(responses[2], 'league_tier_id'),
    );
  }

  Future<StatsClanCountsResponse> loadClanCounts() async {
    final responses = await Future.wait([
      _apiService.get('/counts/clans/locations', requiresAuth: false),
      _apiService.get('/counts/clans/cwl-leagues', requiresAuth: false),
      _apiService.get('/counts/clans/capital-leagues', requiresAuth: false),
    ]);
    return StatsClanCountsResponse(
      locations: decodeStatsGroupedCounts(responses[0], 'location_id'),
      cwlLeagues: decodeStatsGroupedCounts(responses[1], 'cwl_league_id'),
      capitalLeagues: decodeStatsGroupedCounts(
        responses[2],
        'capital_league_id',
      ),
    );
  }

  Future<StatsArmiesResponse> loadArmies(StatsArmiesQuery request) async {
    final json = await _apiService.query(
      '/stats/armies',
      request.toJson(),
      requiresAuth: false,
    );
    return StatsArmiesResponse.fromJson(json);
  }

  Future<StatsItemsResponse> loadItems(StatsItemsQuery request) async {
    final json = await _apiService.query(
      '/stats/items',
      request.toJson(),
      requiresAuth: false,
    );
    return StatsItemsResponse.fromJson(json);
  }

  Future<StatsPerformanceResponse> loadRanked(StatsRankedQuery request) async {
    final json = await _apiService.query(
      '/stats/ranked',
      request.toJson(),
      requiresAuth: false,
    );
    return StatsPerformanceResponse.fromJson(json);
  }

  Future<StatsPerformanceResponse> loadWar(StatsWarQuery request) async {
    final json = await _apiService.query(
      '/stats/war',
      request.toJson(),
      requiresAuth: false,
    );
    return StatsPerformanceResponse.fromJson(json);
  }

  Future<StatsPerformanceResponse> loadCwl(StatsCwlQuery request) async {
    final json = await _apiService.query(
      '/stats/cwl',
      request.toJson(),
      requiresAuth: false,
    );
    return StatsPerformanceResponse.fromJson(json);
  }
}
