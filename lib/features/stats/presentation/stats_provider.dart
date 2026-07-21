import 'package:clashkingapp/features/stats/data/stats_repository.dart';
import 'package:clashkingapp/features/stats/models/stats_models.dart';
import 'package:flutter/foundation.dart';

enum StatsLoadStatus { idle, loading, data, empty, error }

class StatsLoadState {
  const StatsLoadState({
    this.status = StatsLoadStatus.idle,
    this.data,
    this.error,
    this.updatedAt,
    this.isRefreshing = false,
  });

  final StatsLoadStatus status;
  final Object? data;
  final Object? error;
  final DateTime? updatedAt;
  final bool isRefreshing;
}

class StatsProvider extends ChangeNotifier {
  StatsProvider({StatsRepository? repository, DateTime Function()? now})
    : _repository = repository ?? StatsRepository(),
      _now = now ?? DateTime.now {
    final today = _day(_now());
    _dates = StatsDateFilter(
      start: today.subtract(const Duration(days: 29)),
      end: today,
    );
  }

  final StatsRepository _repository;
  final DateTime Function() _now;
  final Map<StatsSection, StatsLoadState> _states = {};
  final Map<StatsSection, int> _requestVersions = {};

  StatsAudience _audience = StatsAudience.battle;
  StatsSection _section = StatsSection.ranked;
  late StatsDateFilter _dates;

  int? armiesTownHall;
  int? armiesLeagueTier;
  int armiesMinimumSample = 100;
  int armiesLimit = 25;
  String armiesSortBy = 'usage_rate';
  List<StatsItemQuantityFilter> armiesInclude = const [];
  List<String> armiesExclude = const [];

  int? itemsTownHall;
  int? itemsLeagueTier;
  List<StatsItemSelector> itemSelectors = const [];

  int? warTownHall;
  int? warOpponentTownHall;
  bool warEqualTownHalls = true;

  int? cwlTownHall;
  int? cwlOpponentTownHall;
  bool cwlEqualTownHalls = true;
  int? cwlLeagueId;
  List<String> cwlSeasons = const [];

  int rankedTownHall = 18;
  int rankedLeagueTier = 1;

  StatsAudience get audience => _audience;
  StatsSection get section => _section;
  StatsDateFilter get dates => _dates;
  StatsLoadState stateFor(StatsSection value) =>
      _states[value] ?? const StatsLoadState();
  StatsLoadState get currentState => stateFor(_section);

  void ensureLoaded() {
    if (currentState.status == StatsLoadStatus.idle) {
      load(_section);
    }
  }

  void selectSection(StatsSection value) {
    if (_section == value) return;
    _section = value;
    notifyListeners();
    if (stateFor(value).status == StatsLoadStatus.idle) load(value);
  }

  void selectAudience(StatsAudience value) {
    if (_audience == value) return;
    _audience = value;
    _section = value == StatsAudience.battle
        ? StatsSection.ranked
        : StatsSection.overview;
    notifyListeners();
    if (stateFor(_section).status == StatsLoadStatus.idle) load(_section);
  }

  Future<void> setDates(DateTime start, DateTime end) async {
    final normalizedStart = _day(start);
    final normalizedEnd = _day(end);
    final next = StatsDateFilter(start: normalizedStart, end: normalizedEnd);
    if (normalizedEnd.isBefore(normalizedStart) || next.inclusiveDays > 90) {
      throw ArgumentError('Stats date ranges must contain 1 to 90 days.');
    }
    _dates = next;
    for (final section in StatsSection.values) {
      _requestVersions[section] = (_requestVersions[section] ?? 0) + 1;
    }
    _states.clear();
    notifyListeners();
    await load(_section);
  }

  void updateArmiesFilters({
    int? townHall,
    int? leagueTier,
    int? minimumSample,
    int? limit,
    String? sortBy,
    List<StatsItemQuantityFilter>? include,
    List<String>? exclude,
    bool clearTownHall = false,
    bool clearLeagueTier = false,
  }) {
    armiesTownHall = clearTownHall ? null : townHall ?? armiesTownHall;
    armiesLeagueTier = clearLeagueTier ? null : leagueTier ?? armiesLeagueTier;
    armiesMinimumSample = minimumSample ?? armiesMinimumSample;
    armiesLimit = limit ?? armiesLimit;
    armiesSortBy = sortBy ?? armiesSortBy;
    armiesInclude = include ?? armiesInclude;
    armiesExclude = exclude ?? armiesExclude;
    _invalidate(StatsSection.armies);
    notifyListeners();
  }

  void updateItemFilters({
    int? townHall,
    int? leagueTier,
    bool clearTownHall = false,
    bool clearLeagueTier = false,
  }) {
    itemsTownHall = clearTownHall ? null : townHall ?? itemsTownHall;
    itemsLeagueTier = clearLeagueTier ? null : leagueTier ?? itemsLeagueTier;
    _invalidate(StatsSection.items);
    notifyListeners();
  }

  void setItemSelectors(List<StatsItemSelector> value) {
    itemSelectors = List.unmodifiable(value.where((item) => item.isValid));
    _invalidate(StatsSection.items);
    notifyListeners();
  }

  void updateWarFilters({
    int? townHall,
    int? opponentTownHall,
    bool? equalTownHalls,
    bool clearTownHall = false,
    bool clearOpponentTownHall = false,
  }) {
    warTownHall = clearTownHall ? null : townHall ?? warTownHall;
    warOpponentTownHall = clearOpponentTownHall
        ? null
        : opponentTownHall ?? warOpponentTownHall;
    warEqualTownHalls = equalTownHalls ?? warEqualTownHalls;
    _invalidate(StatsSection.war);
    notifyListeners();
  }

  void updateCwlFilters({
    int? townHall,
    int? opponentTownHall,
    bool? equalTownHalls,
    int? leagueId,
    List<String>? seasons,
    bool clearTownHall = false,
    bool clearOpponentTownHall = false,
    bool clearLeague = false,
  }) {
    cwlTownHall = clearTownHall ? null : townHall ?? cwlTownHall;
    cwlOpponentTownHall = clearOpponentTownHall
        ? null
        : opponentTownHall ?? cwlOpponentTownHall;
    cwlEqualTownHalls = equalTownHalls ?? cwlEqualTownHalls;
    cwlLeagueId = clearLeague ? null : leagueId ?? cwlLeagueId;
    cwlSeasons = seasons ?? cwlSeasons;
    _invalidate(StatsSection.cwl);
    notifyListeners();
  }

  void updateRankedFilters({required int townHall, required int leagueTier}) {
    rankedTownHall = townHall;
    rankedLeagueTier = leagueTier;
    _invalidate(StatsSection.ranked);
    notifyListeners();
  }

  Future<void> refresh() => load(_section, force: true);

  Future<void> load(StatsSection target, {bool force = false}) async {
    final old = stateFor(target);
    if (!force &&
        (old.status == StatsLoadStatus.loading ||
            old.status == StatsLoadStatus.data ||
            old.status == StatsLoadStatus.empty)) {
      return;
    }
    if (target == StatsSection.items && itemSelectors.isEmpty) {
      _states[target] = const StatsLoadState(status: StatsLoadStatus.empty);
      notifyListeners();
      return;
    }

    final requestVersion = (_requestVersions[target] ?? 0) + 1;
    _requestVersions[target] = requestVersion;
    _states[target] = StatsLoadState(
      status: old.data == null ? StatsLoadStatus.loading : old.status,
      data: old.data,
      updatedAt: old.updatedAt,
      isRefreshing: old.data != null,
    );
    notifyListeners();

    try {
      final result = await _load(target);
      if (_requestVersions[target] != requestVersion) return;
      _states[target] = StatsLoadState(
        status: _isEmpty(result) ? StatsLoadStatus.empty : StatsLoadStatus.data,
        data: result,
        updatedAt: _now(),
      );
    } catch (error) {
      if (_requestVersions[target] != requestVersion) return;
      _states[target] = StatsLoadState(
        status: old.data == null ? StatsLoadStatus.error : old.status,
        data: old.data,
        error: error,
        updatedAt: old.updatedAt,
      );
    }
    notifyListeners();
  }

  Future<Object> _load(StatsSection target) => switch (target) {
    StatsSection.overview => _repository.loadOverview(_dates),
    StatsSection.players => _repository.loadPlayerCounts(),
    StatsSection.clans => _repository.loadClanCounts(),
    StatsSection.armies => _repository.loadArmies(
      StatsArmiesQuery(
        filters: StatsBattleFilters(
          dates: _dates,
          townHallLevel: armiesTownHall,
          rankedLeagueTierId: armiesLeagueTier,
          includeItems: armiesInclude,
          excludeItems: armiesExclude,
          minimumSampleSize: armiesMinimumSample,
        ),
        limit: armiesLimit,
        sortBy: armiesSortBy,
      ),
    ),
    StatsSection.items => _repository.loadItems(
      StatsItemsQuery(
        filters: StatsBattleFilters(
          dates: _dates,
          townHallLevel: itemsTownHall,
          rankedLeagueTierId: itemsLeagueTier,
        ),
        items: itemSelectors,
      ),
    ),
    StatsSection.war => _repository.loadWar(
      StatsWarQuery(
        dates: _dates,
        townHallLevel: warTownHall,
        opponentTownHallLevel: warOpponentTownHall,
        equalTownHalls: warEqualTownHalls,
      ),
    ),
    StatsSection.cwl => _repository.loadCwl(
      StatsCwlQuery(
        dates: _dates,
        townHallLevel: cwlTownHall,
        opponentTownHallLevel: cwlOpponentTownHall,
        equalTownHalls: cwlEqualTownHalls,
        cwlLeagueId: cwlLeagueId,
        seasons: cwlSeasons,
      ),
    ),
    StatsSection.ranked => _repository.loadRanked(
      StatsRankedQuery(
        dates: _dates,
        townHallLevel: rankedTownHall,
        rankedLeagueTierId: rankedLeagueTier,
      ),
    ),
  };

  bool _isEmpty(Object result) => switch (result) {
    StatsArmiesResponse value => value.items.isEmpty,
    StatsItemsResponse value => value.items.isEmpty,
    StatsPerformanceResponse value => !value.metrics.available,
    StatsPlayerCountsResponse value =>
      value.townHalls.isEmpty &&
          value.builderHalls.isEmpty &&
          value.leagueTiers.isEmpty,
    StatsClanCountsResponse value =>
      value.locations.isEmpty &&
          value.cwlLeagues.isEmpty &&
          value.capitalLeagues.isEmpty,
    _ => false,
  };

  void _invalidate(StatsSection target) {
    _requestVersions[target] = (_requestVersions[target] ?? 0) + 1;
    _states[target] = const StatsLoadState();
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
