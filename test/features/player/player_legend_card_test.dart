import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/pages/widgets/player_legend_card.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/player/models/player.dart';
import 'package:clashkingapp/features/player/models/player_clan.dart';
import 'package:clashkingapp/features/player/models/player_legend_day.dart';
import 'package:clashkingapp/features/player/models/player_legend_season.dart';
import 'package:clashkingapp/features/player/models/player_legend_stats.dart';
import 'package:clashkingapp/features/player/models/player_rankings.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

PlayerLegendSeason _buildSeason(PlayerLegendDay? currentDay) {
  final now = DateTime.now();
  final adjustedNow = now.toUtc().hour < 5
      ? now.toUtc().subtract(const Duration(days: 1))
      : now.toUtc();
  final todayKey = adjustedNow.toIso8601String().split('T').first;

  return PlayerLegendSeason(
    start: now.subtract(const Duration(days: 1)),
    end: now.add(const Duration(days: 30)),
    dayOfSeason: 1,
    duration: 30,
    daysInLegend: currentDay == null ? 0 : 1,
    endTrophies: 5500,
    trophiesGainedTotal: currentDay?.trophiesGainedTotal ?? 0,
    trophiesLostTotal: currentDay?.trophiesLostTotal ?? 0,
    trophiesNet: currentDay?.trophiesTotal ?? 0,
    trophiesNetRevised: currentDay?.trophiesTotal ?? 0,
    totalAttacks: currentDay?.totalAttacks ?? 0,
    totalDefenses: currentDay?.totalDefenses ?? 0,
    avgGainedPerAttack: 0,
    avgLostPerDefense: 0,
    totalPossible: 0,
    gainedLostPossible: 0,
    gainedRatio: 0,
    lostRatio: 0,
    attackRatio: 0,
    defenseRatio: 0,
    days: currentDay == null ? {} : {todayKey: currentDay},
    attackStarsDistribution: const {},
    defenseStarsDistribution: const {},
    attackStarsDistributionPercentages: const {},
    defenseStarsDistributionPercentages: const {},
  );
}

Player _buildPlayer({required String league, PlayerLegendDay? currentDay}) {
  return Player(
    name: 'Player',
    tag: '#PLAYER',
    townHallLevel: 16,
    townHallWeaponLevel: 0,
    expLevel: 200,
    trophies: 5500,
    bestTrophies: 5500,
    warStars: 0,
    attackWins: 0,
    defenseWins: 0,
    builderHallLevel: 0,
    builderBaseTrophies: 0,
    bestBuilderBaseTrophies: 0,
    achievements: const [],
    clanTag: '',
    clanOverview: PlayerClanOverview.empty(),
    role: '',
    warPreference: '',
    donations: 0,
    donationsReceived: 0,
    clanCapitalContributions: 0,
    league: league,
    townHallPic: ImageAssets.townHall(16),
    builderHallPic: ImageAssets.builderHall(1),
    leagueUrl: '',
    clanGamesPoint: const [],
    seasonPass: const [],
    lastOnline: DateTime.now(),
    heroes: const [],
    bbHeroes: const [],
    troops: const [],
    superTroops: const [],
    bbTroops: const [],
    spells: const [],
    equipments: const [],
    siegeMachines: const [],
    pets: const [],
    legendsBySeason: PlayerLegendStats(
      seasons: {'current': _buildSeason(currentDay)},
    ),
    rankings: PlayerRankings(
      tag: '#PLAYER',
      countryCode: 'us',
      countryName: 'United States',
      localRank: 123,
      globalRank: 456,
    ),
    legendRanking: const [],
  );
}

Future<Widget> _buildTestApp(Player player) async {
  FlutterSecureStorage.setMockInitialValues({});
  final playerService = PlayerService();
  playerService.profiles.add(player);

  final cocAccountService = CocAccountService();
  cocAccountService.addLocalAccount({'player_tag': player.tag});
  await cocAccountService.setSelectedTag(player.tag);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<PlayerService>.value(value: playerService),
      ChangeNotifierProvider<CocAccountService>.value(value: cocAccountService),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: PlayerLegendCard()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerLegendCard', () {
    testWidgets('renders ranking and trophies chips for current day data', (
      tester,
    ) async {
      final currentDay = PlayerLegendDay.fromJson({
        'trophies_gained_total': 120,
        'trophies_lost_total': 80,
        'trophies_total': 40,
        'num_attacks': 4,
        'num_defenses': 3,
        'start_trophies': 5500,
      });

      await tester.pumpWidget(
        await _buildTestApp(
          _buildPlayer(league: 'Legend League', currentDay: currentDay),
        ),
      );
      await tester.pump();

      expect(find.text('123'), findsOneWidget);
      expect(find.text('456'), findsOneWidget);
      expect(find.text('+40'), findsOneWidget);
    });

    testWidgets(
      'renders zero-state legend chips when current day data is missing',
      (tester) async {
        await tester.pumpWidget(
          await _buildTestApp(
            _buildPlayer(league: 'Legend League', currentDay: null),
          ),
        );
        await tester.pump();

        expect(find.text('123'), findsOneWidget);
        expect(find.text('456'), findsOneWidget);
        expect(find.text('0'), findsWidgets);
      },
    );

    testWidgets('renders no-data text for non-legend players', (tester) async {
      await tester.pumpWidget(
        await _buildTestApp(
          _buildPlayer(league: 'Titan League I', currentDay: null),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byType(PlayerLegendCard));
      expect(
        find.text(AppLocalizations.of(context)!.legendsNoDataToday),
        findsOneWidget,
      );
    });
  });
}
