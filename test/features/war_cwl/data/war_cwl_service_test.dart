import 'dart:async';
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

class _BatchingApiService extends FakeApiService {
  final List<List<String>> batches = [];

  @override
  Future<http.Response> postResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? extraHeaders,
  }) async {
    final tags = List<String>.from((body! as Map)['clan_tags'] as List);
    batches.add(tags);
    return http.Response(
      jsonEncode({'items': tags.map(_minimalWarCwl).toList()}),
      200,
    );
  }
}

class _QueuedApiService extends FakeApiService {
  final List<Completer<http.Response>> responses = [];
  int postCalls = 0;

  @override
  Future<http.Response> postResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? extraHeaders,
  }) {
    postCalls++;
    final response = Completer<http.Response>();
    responses.add(response);
    return response.future;
  }
}

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
      service.processBulkWarData([
        _minimalWarCwl('#CLAN1'),
        _minimalWarCwl('#CLAN2'),
      ], notify: false);
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

    test('keeps clan summaries when war_info is null or missing', () {
      final service = WarCwlService();
      final missingWarInfo = _minimalWarCwl('#MISSING')..remove('war_info');

      service.processBulkWarData([
        {..._minimalWarCwl('#NULL'), 'war_info': null},
        missingWarInfo,
      ], notify: false);

      expect(service.summaries, hasLength(2));
      expect(service.summaries['#NULL']?.warInfo.state, 'notInWar');
      expect(service.summaries['#MISSING']?.warInfo.state, 'notInWar');
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
        jsonEncode({
          'items': [_minimalWarCwl('#CLAN1')],
        }),
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
        jsonEncode({
          'items': [_minimalWarCwl('#C1'), _minimalWarCwl('#C2')],
        }),
        200,
      );
      final service = WarCwlService(apiService: fakeApi);
      await service.loadAllWarData(['#C1', '#C2'], notify: false);
      expect(service.summaries, hasLength(2));
    });

    test('normalizes, deduplicates, and batches at 100 tags', () async {
      final fakeApi = _BatchingApiService();
      final service = WarCwlService(apiService: fakeApi);
      final tags = [
        for (var index = 0; index < 205; index++) ' clan$index ',
        'CLAN0',
      ];

      await service.loadAllWarData(tags, notify: false);

      expect(fakeApi.batches.map((batch) => batch.length), [100, 100, 5]);
      expect(service.summaries, hasLength(205));
      expect(service.getWarCwlByTag('clan0')?.tag, '#CLAN0');
    });

    test('coalesces identical in-flight loads', () async {
      final fakeApi = _QueuedApiService();
      final service = WarCwlService(apiService: fakeApi);

      final first = service.loadAllWarData(['#CLAN'], notify: false);
      final second = service.loadAllWarData(['clan'], notify: false);
      expect(fakeApi.postCalls, 1);

      fakeApi.responses.single.complete(
        http.Response(
          jsonEncode({
            'items': [_minimalWarCwl('#CLAN')],
          }),
          200,
        ),
      );
      await Future.wait([first, second]);
      expect(service.summaries, hasLength(1));
    });

    test('honors notify when a later coalesced caller requests it', () async {
      final fakeApi = _QueuedApiService();
      final service = WarCwlService(apiService: fakeApi);
      var notifications = 0;
      service.addListener(() => notifications++);

      final quiet = service.loadAllWarData(['#CLAN'], notify: false);
      final notifying = service.loadAllWarData(['#CLAN'], notify: true);
      expect(fakeApi.postCalls, 1);

      fakeApi.responses.single.complete(
        http.Response(
          jsonEncode({
            'items': [_minimalWarCwl('#CLAN')],
          }),
          200,
        ),
      );
      await Future.wait([quiet, notifying]);

      expect(notifications, 1);
    });

    test('applies error policy per coalesced caller', () async {
      final fakeApi = _QueuedApiService();
      final service = WarCwlService(apiService: fakeApi);

      final bestEffort = service.loadAllWarData(['#CLAN'], notify: false);
      final strict = service.loadAllWarData(
        ['#CLAN'],
        notify: false,
        throwOnError: true,
      );
      expect(fakeApi.postCalls, 1);

      final strictExpectation = expectLater(strict, throwsA(isA<Exception>()));
      fakeApi.responses.single.complete(http.Response('error', 503));

      await expectLater(bestEffort, completes);
      await strictExpectation;
    });

    test(
      'prevents an older overlapping response replacing newer data',
      () async {
        final fakeApi = _QueuedApiService();
        final service = WarCwlService(apiService: fakeApi);

        final older = service.loadAllWarData(['#CLAN'], notify: false);
        final newer = service.loadAllWarData([
          '#CLAN',
          '#OTHER',
        ], notify: false);
        expect(fakeApi.postCalls, 2);

        fakeApi.responses[1].complete(
          http.Response(
            jsonEncode({
              'items': [
                {..._minimalWarCwl('#CLAN'), 'isInWar': true},
                _minimalWarCwl('#OTHER'),
              ],
            }),
            200,
          ),
        );
        await newer;
        fakeApi.responses[0].complete(
          http.Response(
            jsonEncode({
              'items': [_minimalWarCwl('#CLAN')],
            }),
            200,
          ),
        );
        await older;

        expect(service.summaries['#CLAN']?.isInWar, isTrue);
        expect(service.summaries['#OTHER'], isNotNull);
      },
    );

    test(
      'keeps good state while accepting valid items from a partial response',
      () async {
        final fakeApi = FakeApiService();
        final service = WarCwlService(apiService: fakeApi);
        service.processBulkWarData([_minimalWarCwl('#OLD')], notify: false);
        final previous = service.summaries['#OLD'];
        var notifications = 0;
        service.addListener(() => notifications++);
        fakeApi.postStubs['/war/war-summary'] = http.Response(
          jsonEncode({
            'items': [
              _minimalWarCwl('#NEW'),
              {'clan_tag': '#OLD', 'war_info': 'invalid'},
              'invalid',
            ],
          }),
          200,
        );

        await service.loadAllWarData(['#OLD', '#NEW']);

        expect(service.summaries['#OLD'], same(previous));
        expect(service.summaries['#NEW'], isNotNull);
        expect(notifications, 1);
      },
    );

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
        () => service.loadAllWarData(
          ['#CLAN1'],
          notify: false,
          throwOnError: true,
        ),
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
        () => service.loadAllWarData(
          ['#CLAN1'],
          notify: false,
          throwOnError: true,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('WarCwlService — fetchWarDataFromTime', () {
    test('uses the v2 previous-war endpoint and parses its first item', () async {
      final fakeApi = _RecordingApiService();
      final end = DateTime.utc(2026, 8, 9, 12, 34, 56);
      final timestamp = end.millisecondsSinceEpoch ~/ 1000;
      final endpoint =
          '/war/%23ABC123/previous?timestamp_end=$timestamp&include_cwl=true&limit=1';
      fakeApi.getStubs[endpoint] = http.Response(
        jsonEncode({
          'items': [
            {'war_tag': '#WAR1', 'state': 'warEnded', 'type': 'regular'},
          ],
        }),
        200,
      );

      final result = await WarCwlService.fetchWarDataFromTime(
        '#ABC123',
        end,
        apiService: fakeApi,
      );

      expect(fakeApi.getCallCounts[endpoint], 1);
      expect(fakeApi.lastGetRequiresAuth, isTrue);
      expect(result?.tag, '#WAR1');
      expect(result?.state, 'warEnded');
    });

    test('returns null when the v2 response has no historical wars', () async {
      final fakeApi = FakeApiService();
      final end = DateTime.utc(2026, 8, 9);
      final timestamp = end.millisecondsSinceEpoch ~/ 1000;
      final endpoint =
          '/war/%23EMPTY/previous?timestamp_end=$timestamp&include_cwl=true&limit=1';
      fakeApi.getStubs[endpoint] = http.Response('{"items":[]}', 200);

      final result = await WarCwlService.fetchWarDataFromTime(
        '#EMPTY',
        end,
        apiService: fakeApi,
      );

      expect(result, isNull);
    });
  });
}
