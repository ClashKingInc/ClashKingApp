import 'dart:async';

import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/rankings/data/rankings_service.dart';
import 'package:clashkingapp/features/rankings/models/ranking_models.dart';
import 'package:flutter/foundation.dart';

class RankingsProvider extends ChangeNotifier {
  RankingsProvider({
    RankingsService? service,
    List<RankingLeagueOption>? leagueOptions,
    DateTime Function()? clock,
  }) : _service = service ?? RankingsService(),
       leagueOptions = leagueOptions ?? rankingLeagueOptionsFromGameData(),
       _clock = clock ?? DateTime.now {
    selectedLeague = this.leagueOptions.first;
    final now = _clock();
    historyDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 1));
  }

  final RankingsService _service;
  final DateTime Function() _clock;
  final List<RankingLeagueOption> leagueOptions;

  RankingAudience audience = RankingAudience.players;
  RankingBoard playerBoard = RankingBoard.playerHome;
  RankingBoard clanBoard = RankingBoard.clanHome;
  RankingPeriod period = RankingPeriod.current;
  RankingLocation location = const RankingLocation.worldwide();
  List<RankingLocation> locations = const [RankingLocation.worldwide()];
  late RankingLeagueOption selectedLeague;
  late DateTime historyDate;
  int townHallLevel = 18;
  RankingResult? result;
  Object? error;
  Object? locationError;
  bool isLoading = false;
  bool isLoadingLocations = false;
  int _requestGeneration = 0;

  RankingBoard get board =>
      audience == RankingAudience.players ? playerBoard : clanBoard;

  List<RankingBoard> get boards => RankingBoard.values
      .where((value) => value.audience == audience)
      .toList(growable: false);

  Future<void> initialize() async {
    isLoadingLocations = true;
    locationError = null;
    notifyListeners();
    try {
      final fetchedLocations = await _service.fetchLocations();
      locations = fetchedLocations
          .where((item) => item.isWorldwide || item.hasValidCountryCode)
          .toList(growable: false);
      if (locations.isEmpty) {
        locations = const [RankingLocation.worldwide()];
      }
      location = locations.firstWhere(
        (item) => item.isWorldwide,
        orElse: () => locations.first,
      );
    } catch (exception) {
      locationError = exception;
    } finally {
      isLoadingLocations = false;
      notifyListeners();
    }
    await reload();
  }

  Future<void> reload() async {
    final selectedBoard = board;
    if (selectedBoard.supportsLocation &&
        !selectedBoard.supportsWorldwide &&
        location.isWorldwide) {
      final replacement = locations
          .where((item) => !item.isWorldwide)
          .firstOrNull;
      if (replacement == null) {
        result = null;
        error =
            locationError ?? const FormatException('No locations available.');
        notifyListeners();
        return;
      }
      location = replacement;
    }

    final generation = ++_requestGeneration;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final next = await _service.fetchRankings(
        RankingQuery(
          board: selectedBoard,
          location: location,
          period: period,
          historyDate: historyDate,
          townHallLevel: townHallLevel,
          leagueTier: selectedLeague,
        ),
      );
      if (generation != _requestGeneration) return;
      result = next;
    } catch (exception) {
      if (generation != _requestGeneration) return;
      result = null;
      error = exception;
    } finally {
      if (generation == _requestGeneration) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> selectAudience(RankingAudience value) async {
    if (audience == value) return;
    audience = value;
    period = RankingPeriod.current;
    notifyListeners();
    await reload();
  }

  Future<void> selectBoard(RankingBoard value) async {
    if (value.audience != audience || board == value) return;
    if (audience == RankingAudience.players) {
      playerBoard = value;
    } else {
      clanBoard = value;
    }
    if (!value.supportsHistory) period = RankingPeriod.current;
    notifyListeners();
    await reload();
  }

  Future<void> selectLocation(RankingLocation value) async {
    if (location == value || (value.isWorldwide && !board.supportsWorldwide)) {
      return;
    }
    location = value;
    notifyListeners();
    await reload();
  }

  Future<void> selectPeriod(RankingPeriod value) async {
    if (period == value ||
        (value == RankingPeriod.history && !board.supportsHistory)) {
      return;
    }
    period = value;
    notifyListeners();
    await reload();
  }

  Future<void> selectHistoryDate(DateTime value) async {
    final normalized = DateTime(value.year, value.month, value.day);
    if (historyDate == normalized) return;
    historyDate = normalized;
    notifyListeners();
    await reload();
  }

  Future<void> selectTownHall(int value) async {
    if (townHallLevel == value) return;
    townHallLevel = value;
    notifyListeners();
    await reload();
  }

  Future<void> selectLeague(RankingLeagueOption value) async {
    if (selectedLeague.id == value.id) return;
    selectedLeague = value;
    notifyListeners();
    await reload();
  }
}

List<RankingLeagueOption> rankingLeagueOptionsFromGameData() {
  final rawLeagues = GameDataService.playerLeagueData['leagues'];
  if (rawLeagues is! Map) {
    return const [
      RankingLeagueOption.legendTwo,
      RankingLeagueOption.legendThree,
    ];
  }

  final optionsByID = <int, RankingLeagueOption>{};
  for (final entry in rawLeagues.entries) {
    final raw = entry.value;
    if (raw is! Map) continue;
    final id = _intValue(raw['_id'] ?? raw['id']);
    if (id == null ||
        id < 105000000 ||
        id == RankingLeagueOption.legendOne.id) {
      continue;
    }
    final rawName = raw['name']?.toString().trim() ?? entry.key.toString();
    final name = switch (id) {
      105000035 => 'Legend League 2',
      105000034 => 'Legend League 3',
      _ => rawName,
    };
    if (name.isEmpty) continue;
    optionsByID[id] = RankingLeagueOption(
      id: id,
      name: name,
      iconUrl: ImageAssets.getLeagueImage(name),
    );
  }

  final options = optionsByID.values.toList(growable: false)
    ..sort((a, b) => b.id.compareTo(a.id));
  if (options.isEmpty) {
    return const [
      RankingLeagueOption.legendTwo,
      RankingLeagueOption.legendThree,
    ];
  }
  return options;
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
