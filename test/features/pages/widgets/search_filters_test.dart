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
    home: Scaffold(body: child),
  );

  testWidgets('numeric clan filters keep focus across value updates', (
    tester,
  ) async {
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
    await tester.pump();

    final field = find.byType(TextFormField).first;
    await tester.tap(field);
    await tester.enterText(field, '1');
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    await tester.enterText(field, '12');
    await tester.pump();
    expect(tester.widget<TextFormField>(field).controller?.text, '12');
    expect(value.minMembers, 12);
  });

  testWidgets('retained dropdown selections wait for loaded options', (
    tester,
  ) async {
    final api = FakeApiService();
    api.getStubs['/locations'] = http.Response(
      jsonEncode({
        'items': [
          {'id': 32000006, 'name': 'International'},
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
        ListView(
          children: [
            ClanSearchFiltersPanel(
              apiService: api,
              value: const ClanSearchFilterValue(locationId: 32000006),
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
    expect(tester.takeException(), isNull);

    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('International'), findsOneWidget);
    expect(find.text('Legend League'), findsOneWidget);
  });
}
