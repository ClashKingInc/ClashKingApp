import 'package:clashkingapp/features/rankings/data/rankings_provider.dart';
import 'package:clashkingapp/features/rankings/data/rankings_service.dart';
import 'package:clashkingapp/features/rankings/models/ranking_models.dart';
import 'package:clashkingapp/features/rankings/presentation/rankings_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('location picker is opaque, searchable, and pins Worldwide', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showRankingLocationPicker(
                context,
                locations: const [
                  RankingLocation.worldwide(),
                  RankingLocation(
                    id: 32000000,
                    name: 'Europe',
                    isCountry: false,
                  ),
                  RankingLocation(
                    id: 32000006,
                    name: 'United States',
                    isCountry: true,
                    countryCode: 'US',
                  ),
                ],
                selected: const RankingLocation.worldwide(),
                allowWorldwide: true,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Material),
          )
          .first,
    );
    expect(material.color, isNot(Colors.transparent));
    expect(find.text('Worldwide'), findsOneWidget);
    expect(find.text('Europe'), findsNothing);
    expect(find.text('United States'), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('rankings-location-search')))
          .autofocus,
      isFalse,
    );

    await tester.enterText(
      find.byKey(const Key('rankings-location-search')),
      'united',
    );
    await tester.pump();

    expect(find.text('Worldwide'), findsOneWidget);
    expect(find.text('United States'), findsOneWidget);
    expect(find.text('Europe'), findsNothing);
  });

  testWidgets('switching Player and Clan subpages updates visible results', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final service = _WidgetRankingsService();
    final provider = RankingsProvider(
      service: service,
      leagueOptions: const [
        RankingLeagueOption.legendTwo,
        RankingLeagueOption.legendThree,
      ],
      clock: () => DateTime(2026, 7, 20),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RankingsPage(provider: provider),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rankings of the Top Players & Clans'), findsOneWidget);
    expect(find.text('Player result'), findsOneWidget);
    expect(service.queries.last.board, RankingBoard.playerHome);

    await tester.tap(find.text('Clans'));
    await tester.pumpAndSettle();

    expect(find.text('Clan result'), findsOneWidget);
    expect(find.text('Player result'), findsNothing);
    expect(service.queries.last.board, RankingBoard.clanHome);

    await tester.drag(find.byType(TabBar), const Offset(-520, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Donations'));
    await tester.pumpAndSettle();

    expect(service.queries.last.board, RankingBoard.clanDonations);
    expect(service.queries.last.location.isWorldwide, isFalse);
  });

  testWidgets('does not show source, results, or fake filter chips', (
    tester,
  ) async {
    final provider = RankingsProvider(
      service: _WidgetRankingsService(),
      leagueOptions: const [
        RankingLeagueOption.legendTwo,
        RankingLeagueOption.legendThree,
      ],
      clock: () => DateTime(2026, 7, 20),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RankingsPage(provider: provider),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Source'), findsNothing);
    expect(find.text('Results'), findsNothing);
    expect(find.text('TH18 · Legend I'), findsNothing);

    await provider.selectBoard(RankingBoard.playerTownHall);
    await tester.pumpAndSettle();
    expect(find.text('TH18'), findsOneWidget);

    await provider.selectBoard(RankingBoard.playerRanked);
    await tester.pumpAndSettle();
    expect(find.text('Legend League 2'), findsOneWidget);

    await provider.selectLeague(RankingLeagueOption.legendThree);
    await tester.pumpAndSettle();
    expect(find.text('Legend League 3'), findsOneWidget);

    await provider.selectBoard(RankingBoard.playerTownHall);
    await provider.selectTownHall(17);
    await tester.pumpAndSettle();
    expect(find.text('TH17'), findsOneWidget);
  });
}

class _WidgetRankingsService extends RankingsService {
  final queries = <RankingQuery>[];

  @override
  Future<List<RankingLocation>> fetchLocations() async => const [
    RankingLocation.worldwide(),
    RankingLocation(
      id: 32000007,
      name: 'United States',
      isCountry: true,
      countryCode: 'US',
    ),
  ];

  @override
  Future<RankingResult> fetchRankings(RankingQuery query) async {
    queries.add(query);
    final isClan = query.board.isClan;
    return RankingResult(
      entries: [
        RankingEntry(
          audience: query.board.audience,
          rank: 1,
          previousRank: 1,
          tag: isClan ? '#CLAN' : '#PLAYER',
          name: isClan ? 'Clan result' : 'Player result',
          subtitle: isClan ? '#CLAN' : '',
          score: 6000,
          imageUrl: query.board.iconUrl,
          metricImageUrl: query.board.iconUrl,
          townHallLevel: 18,
        ),
      ],
      source: query.board.source,
      limit: query.board.source == RankingSource.official ? 200 : 500,
    );
  }
}
