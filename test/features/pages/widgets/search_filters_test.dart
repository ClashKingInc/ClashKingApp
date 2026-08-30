import 'dart:convert';

import 'package:clashkingapp/features/pages/widgets/clan_search_filters_dialog.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  test('player Town Hall range expands to API levels', () {
    const filters = PlayerSearchFilterValue(
      minTownHallLevel: 12,
      maxTownHallLevel: 15,
    );

    expect(filters.townHallLevels, [12, 13, 14, 15]);
    expect(const PlayerSearchFilterValue().townHallLevels, isEmpty);
  });

  testWidgets('clan member range emits min and max values', (tester) async {
    final api = FakeApiService();
    api.getStubs['/locations'] = http.Response('{"items":[]}', 200);
    var value = const ClanSearchFilterValue();

    await tester.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => ClanSearchFiltersPanel(
            apiService: api,
            value: value,
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      ),
    );

    tester.widget<RangeSlider>(find.byType(RangeSlider).first).onChanged!(
      const RangeValues(12, 40),
    );
    await tester.pump();

    expect(value.minMembers, 12);
    expect(value.maxMembers, 40);
  });

  testWidgets('location filter only includes countries with flags', (
    tester,
  ) async {
    final api = FakeApiService();
    api.getStubs['/locations'] = http.Response(
      jsonEncode({
        'items': [
          {'id': 32000006, 'name': 'International', 'isCountry': false},
          {
            'id': 32000058,
            'name': 'United States',
            'isCountry': true,
            'countryCode': 'US',
          },
        ],
      }),
      200,
    );
    api.getStubs['/leaguetiers'] = http.Response(
      jsonEncode({
        'items': [
          {'id': 29000022, 'name': 'Legend League'},
        ],
      }),
      200,
    );

    await tester.pumpWidget(
      app(
        Column(
          children: [
            ClanSearchFiltersPanel(
              apiService: api,
              value: const ClanSearchFilterValue(locationId: 32000058),
              onChanged: (_) {},
            ),
            PlayerSearchFiltersPanel(
              apiService: api,
              value: const PlayerSearchFilterValue(leagueIds: [29000022]),
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('United States'), findsOneWidget);
    expect(find.text('International'), findsNothing);
    expect(find.text('Legend League'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });
}
