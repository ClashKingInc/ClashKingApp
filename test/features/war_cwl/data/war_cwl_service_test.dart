import 'dart:convert';

import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

Map<String, dynamic> _minimalWarCwl(String tag) => {
  'clan_tag': tag,
  'isInWar': false,
  'isInCwl': false,
  'war_info': {'state': 'notInWar', 'currentWarInfo': null},
  'league_info': null,
  'war_league_infos': [],
};

Map<String, dynamic> _war(String left, String right, {String? warTag}) => {
  'war_tag': ?warTag,
  'state': 'inWar',
  'teamSize': 1,
  'attacksPerMember': 2,
  'startTime': '20260829T000000.000Z',
  'endTime': '20260830T000000.000Z',
  'clan': {'tag': left, 'name': left, 'members': <Object>[]},
  'opponent': {'tag': right, 'name': right, 'members': <Object>[]},
};

class _RecordingApiService extends FakeApiService {
  bool? lastGetRequiresAuth;

  @override
  Future<http.Response> getResponse(
    String endpoint, {
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? extraHeaders,
  }) {
    lastGetRequiresAuth = requiresAuth;
    return super.getResponse(
      endpoint,
      requiresAuth: requiresAuth,
      url: url,
      timeout: timeout,
      extraHeaders: extraHeaders,
    );
  }
}

void main() {
  setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

  group('WarCwlService local state', () {
    test('starts empty and normalizes lookups', () {
      final service = WarCwlService();
      expect(service.summaries, isEmpty);
      service.processBulkWarData([_minimalWarCwl('#CLAN')], notify: false);
      expect(service.getWarCwlByTag('clan')?.tag, '#CLAN');
    });

    test('skips malformed bulk entries', () {
      final service = WarCwlService();
      service.processBulkWarData(['bad', null, 42], notify: false);
      expect(service.summaries, isEmpty);
    });
  });

  group('WarCwlService current-war resolver', () {
    test(
      'falls back to the public current-war endpoint when basic is null',
      () async {
        final api = FakeApiService();
        api.getStubs['/war/%23CLAN/basic'] = http.Response('null', 200);
        api.getStubs['/clans/%23CLAN/currentwar'] = http.Response(
          jsonEncode(_war('#CLAN', '#OTHER')),
          200,
        );

        final service = WarCwlService(apiService: api);
        await service.loadAllWarData(['#CLAN'], notify: false);

        final result = service.getWarCwlByTag('#CLAN')!;
        expect(result.isInWar, isTrue);
        expect(result.warInfo.clan?.tag, '#CLAN');
      },
    );

    test('uses a public opponent and reorients the requested clan', () async {
      final api = FakeApiService();
      api.getStubs['/war/%23CLAN/basic'] = http.Response(
        jsonEncode({
          'type': 'regular',
          'clan': {'tag': '#CLAN', 'publicWarLog': false},
          'opponent': {'tag': '#OTHER', 'publicWarLog': true},
        }),
        200,
      );
      api.getStubs['/clans/%23OTHER/currentwar'] = http.Response(
        jsonEncode(_war('#OTHER', '#CLAN')),
        200,
      );

      final service = WarCwlService(apiService: api);
      await service.loadAllWarData(['#CLAN'], notify: false);

      final result = service.getWarCwlByTag('#CLAN')!;
      expect(result.isInWar, isTrue);
      expect(result.warInfo.clan?.tag, '#CLAN');
      expect(result.warInfo.opponent?.tag, '#OTHER');
      expect(api.getCallCounts['/clans/%23CLAN/currentwar'], isNull);
    });

    test(
      'marks a scheduled war private when neither side exposes it',
      () async {
        final api = FakeApiService();
        api.getStubs['/war/%23CLAN/basic'] = http.Response(
          jsonEncode({
            'type': 'regular',
            'clan': {'tag': '#CLAN', 'publicWarLog': false},
            'opponent': {'tag': '#OTHER', 'publicWarLog': false},
          }),
          200,
        );

        final service = WarCwlService(apiService: api);
        await service.loadAllWarData(['#CLAN'], notify: false);

        expect(service.getWarCwlByTag('#CLAN')?.warInfo.state, 'accessDenied');
      },
    );

    test(
      'marks a clan not in war when manual war and CWL probes are empty',
      () async {
        final api = FakeApiService();
        api.getStubs['/war/%23CLAN/basic'] = http.Response('null', 200);
        api.getStubs['/clans/%23CLAN/currentwar'] = http.Response(
          '{"state":"notInWar"}',
          200,
        );
        api.getStubs['/clans/%23CLAN/currentwar/leaguegroup'] = http.Response(
          '{}',
          404,
        );

        final service = WarCwlService(apiService: api);
        await service.loadAllWarData(['#CLAN'], notify: false);

        expect(service.getWarCwlByTag('#CLAN')?.warInfo.state, 'notInWar');
      },
    );

    test('loads the scheduled CWL war directly from its war tag', () async {
      final api = FakeApiService();
      api.getStubs['/war/%23CLAN/basic'] = http.Response(
        jsonEncode({
          'type': 'cwl',
          'warTag': '#WAR',
          'clan': {'tag': '#CLAN', 'publicWarLog': false},
          'opponent': {'tag': '#OTHER', 'publicWarLog': false},
        }),
        200,
      );
      api.getStubs['/clans/%23CLAN/currentwar/leaguegroup'] = http.Response(
        '{}',
        404,
      );
      api.getStubs['/clanwarleagues/wars/%23WAR'] = http.Response(
        jsonEncode(_war('#OTHER', '#CLAN', warTag: '#WAR')),
        200,
      );

      final service = WarCwlService(apiService: api);
      await service.loadAllWarData(['#CLAN'], notify: false);

      final result = service.getWarCwlByTag('#CLAN')!;
      expect(result.isInCwl, isTrue);
      expect(result.getActiveWarByTag('#CLAN')?.clan?.tag, '#CLAN');
    });

    test('honors strict error handling', () async {
      final api = FakeApiService();
      api.throwOnGet['/war/%23CLAN/basic'] = Exception('network');
      final service = WarCwlService(apiService: api);

      await expectLater(
        service.loadAllWarData(['#CLAN'], notify: false, throwOnError: true),
        throwsException,
      );
    });
  });

  group('WarCwlService previous war', () {
    test('uses the v2 endpoint and parses the first item', () async {
      final api = _RecordingApiService();
      final end = DateTime.utc(2026, 8, 9, 12, 34, 56);
      final timestamp = end.millisecondsSinceEpoch ~/ 1000;
      final endpoint =
          '/war/%23ABC123/previous?timestamp_end=$timestamp&include_cwl=true&limit=1';
      api.getStubs[endpoint] = http.Response(
        '{"items":[{"war_tag":"#WAR1","state":"warEnded"}]}',
        200,
      );

      final result = await WarCwlService.fetchWarDataFromTime(
        '#ABC123',
        end,
        apiService: api,
      );

      expect(result?.tag, '#WAR1');
      expect(api.lastGetRequiresAuth, isTrue);
    });
  });
}
