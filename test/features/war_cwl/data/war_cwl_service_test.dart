import 'dart:convert';

import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

Map<String, dynamic> _minimalWarCwl(String tag) => {
      'clan_tag': tag,
      'isInWar': false,
      'isInCwl': false,
      'war_info': {
        'state': 'notInWar',
        'currentWarInfo': null,
      },
      'league_info': null,
      'war_league_infos': [],
    };

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('WarCwlService — initial state', () {
    test('summaries map starts empty', () {
      final service = WarCwlService();
      expect(service.summaries, isEmpty);
    });

    test('getWarCwlByTag returns null for empty tag', () {
      final service = WarCwlService();
      expect(service.getWarCwlByTag(''), isNull);
    });

    test('getWarCwlByTag returns null when no data loaded', () {
      final service = WarCwlService();
      expect(service.getWarCwlByTag('#UNKNOWN'), isNull);
    });
  });

  group('WarCwlService — processBulkWarData', () {
    test('adds entries to summaries map', () {
      final service = WarCwlService();
      service.processBulkWarData(
        [_minimalWarCwl('#CLAN1'), _minimalWarCwl('#CLAN2')],
        notify: false,
      );
      expect(service.summaries, hasLength(2));
      expect(service.summaries['#CLAN1'], isNotNull);
      expect(service.summaries['#CLAN2'], isNotNull);
    });

    test('does nothing for empty list', () {
      final service = WarCwlService();
      service.processBulkWarData([], notify: false);
      expect(service.summaries, isEmpty);
    });

    test('skips non-map entries gracefully', () {
      final service = WarCwlService();
      service.processBulkWarData(['not a map', 42, null], notify: false);
      expect(service.summaries, isEmpty);
    });

    test('overwrites existing entry for same tag', () {
      final service = WarCwlService();
      service.processBulkWarData([_minimalWarCwl('#CLAN1')], notify: false);
      service.processBulkWarData([_minimalWarCwl('#CLAN1')], notify: false);
      expect(service.summaries, hasLength(1));
    });
  });

  group('WarCwlService — getWarCwlByTag', () {
    test('returns entry after processBulkWarData', () {
      final service = WarCwlService();
      service.processBulkWarData([_minimalWarCwl('#CLAN1')], notify: false);
      final result = service.getWarCwlByTag('#CLAN1');
      expect(result, isNotNull);
      expect(result!.tag, '#CLAN1');
    });

    test('returns null for unknown tag after data loaded', () {
      final service = WarCwlService();
      service.processBulkWarData([_minimalWarCwl('#CLAN1')], notify: false);
      expect(service.getWarCwlByTag('#OTHER'), isNull);
    });
  });

  group('WarCwlService — loadAllWarData', () {
    test('does nothing for empty tag list', () async {
      final service = WarCwlService();
      await service.loadAllWarData([], notify: false);
      expect(service.summaries, isEmpty);
    });

    test('populates summaries on 200 response', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/war-summary'] = http.Response(
        jsonEncode({'items': [_minimalWarCwl('#CLAN1')]}),
        200,
      );
      final service = WarCwlService(apiService: fakeApi);
      await service.loadAllWarData(['#CLAN1'], notify: false);
      expect(service.summaries['#CLAN1'], isNotNull);
      expect(service.summaries['#CLAN1']!.tag, '#CLAN1');
    });

    test('populates multiple clans on 200 response', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/war-summary'] = http.Response(
        jsonEncode({'items': [_minimalWarCwl('#C1'), _minimalWarCwl('#C2')]}),
        200,
      );
      final service = WarCwlService(apiService: fakeApi);
      await service.loadAllWarData(['#C1', '#C2'], notify: false);
      expect(service.summaries, hasLength(2));
    });

    test('does not throw on server error by default', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/war-summary'] = http.Response('error', 500);
      final service = WarCwlService(apiService: fakeApi);
      await expectLater(
        service.loadAllWarData(['#CLAN1'], notify: false),
        completes,
      );
    });

    test('throws when throwOnError is true on server error', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/war/war-summary'] = http.Response('error', 503);
      final service = WarCwlService(apiService: fakeApi);
      await expectLater(
        () => service.loadAllWarData(['#CLAN1'],
            notify: false, throwOnError: true),
        throwsA(isA<Exception>()),
      );
    });

    test('does not throw on network exception by default', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnPost['/war/war-summary'] = Exception('no network');
      final service = WarCwlService(apiService: fakeApi);
      await expectLater(
        service.loadAllWarData(['#CLAN1'], notify: false),
        completes,
      );
    });

    test('throws on network exception when throwOnError is true', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnPost['/war/war-summary'] = Exception('no network');
      final service = WarCwlService(apiService: fakeApi);
      await expectLater(
        () => service.loadAllWarData(['#CLAN1'],
            notify: false, throwOnError: true),
        throwsA(isA<Exception>()),
      );
    });
  });
}
