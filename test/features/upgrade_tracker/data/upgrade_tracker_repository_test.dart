import 'dart:convert';

import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/upgrade_tracker/data/upgrade_tracker_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GameDataService.loadFromBundleForTesting({
      'buildings': [
        {
          '_id': 1,
          'name': 'Town Hall',
          'village': 'home',
          'type': 'Town Hall',
          'upgrade_resource': 'Gold',
          'levels': [
            {
              'level': 18,
              'build_cost': 1,
              'build_time': 1,
              'required_townhall': 18,
            },
          ],
        },
      ],
    });
  });

  test('imports, indexes, and reloads a raw account snapshot', () async {
    final repository = UpgradeTrackerRepository(
      checkStaticDataFreshness: false,
    );
    final raw = {
      'tag': '2j8v28gv0',
      'name': 'Imported Player',
      'buildings': [
        {'data': 1, 'lvl': 18},
      ],
    };

    final imported = await repository.importSnapshotBytes(
      utf8.encode(jsonEncode({'player': raw})),
      allowedTags: const {'#2J8V28GV0'},
      linkedNamesByTag: const {'#2J8V28GV0': 'Magic Jr.'},
    );

    expect(imported.tag, '#2J8V28GV0');
    expect(imported.name, 'Magic Jr.');
    expect(imported.townHallLevel, 18);
    expect(await repository.load('#2J8V28GV0'), isNotNull);
    expect(
      await repository.savedSnapshotAccounts(),
      contains(
        allOf(
          containsPair('tag', '#2J8V28GV0'),
          containsPair('name', 'Magic Jr.'),
          containsPair('townHallLevel', '18'),
          containsPair('builderHallLevel', '0'),
          containsPair('capturedAt', isNotEmpty),
        ),
      ),
    );
  });

  test('rejects JSON without a player tag', () async {
    final repository = UpgradeTrackerRepository(
      checkStaticDataFreshness: false,
    );

    expect(
      () => repository.importSnapshotBytes(
        utf8.encode(jsonEncode({'buildings': []})),
      ),
      throwsFormatException,
    );
  });

  test('persists plan preferences by account', () async {
    final repository = UpgradeTrackerRepository(
      checkStaticDataFreshness: false,
    );
    await repository.savePlanPreferences(
      '#TEST',
      goldPassPercent: 20,
      strategy: 'shortest',
    );

    final draft = await repository.loadPlanPreferences('test');
    expect(draft?['gold_pass_percent'], 20);
    expect(draft?['strategy'], 'shortest');
  });

  test('replaces whole upgrade JSON for verified remote accounts', () async {
    final api = FakeApiService();
    const endpoint = '/links/user-1/%23TEST/upgrades';
    api.putStubs[endpoint] = http.Response(
      '{"player_tag":"#TEST","data":{},"updated_at":null}',
      200,
    );
    final repository = UpgradeTrackerRepository(apiService: api);
    repository.configureRemote(
      accountId: 'user-1',
      verifiedPlayerTags: const {'#TEST'},
    );
    final snapshot = {
      'tag': '#TEST',
      'buildings': [
        {'data': 1, 'lvl': 18},
      ],
    };

    await repository.saveRawSnapshot('#TEST', snapshot);

    expect(api.lastPutBodies[endpoint], {'data': snapshot});
  });

  test(
    'patches whole preference object for verified remote accounts',
    () async {
      final api = FakeApiService();
      const endpoint = '/links/user-1/%23TEST/upgrade-preferences';
      api.patchStubs[endpoint] = http.Response(
        '{"player_tag":"#TEST","preferences":{},"updated_at":null}',
        200,
      );
      final repository = UpgradeTrackerRepository(apiService: api);
      repository.configureRemote(
        accountId: 'user-1',
        verifiedPlayerTags: const {'#TEST'},
      );

      await repository.savePlanPreferences(
        '#TEST',
        goldPassPercent: 20,
        strategy: 'balanced',
      );

      expect(
        api.lastPatchBodies[endpoint],
        containsPair('preferences', containsPair('gold_pass_percent', 20)),
      );
    },
  );

  test('rejects remote upgrade writes for unverified accounts', () async {
    final repository = UpgradeTrackerRepository(apiService: FakeApiService());
    repository.configureRemote(
      accountId: 'user-1',
      verifiedPlayerTags: const {'#OTHER'},
    );

    await expectLater(
      () => repository.saveRawSnapshot('#TEST', {
        'tag': '#TEST',
        'buildings': <Object>[],
      }),
      throwsStateError,
    );
  });

  test(
    'clearCache resets remote config so a later load skips the remote endpoint',
    () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/links/user1/%232J8V28GV0/upgrades'] = http.Response(
        jsonEncode({
          'data': {
            'player': {'tag': '2j8v28gv0', 'name': 'Remote', 'buildings': []},
          },
        }),
        200,
      );
      final repository = UpgradeTrackerRepository(
        apiService: fakeApi,
        checkStaticDataFreshness: false,
      );
      repository.configureRemote(
        accountId: 'user1',
        verifiedPlayerTags: const ['#2J8V28GV0'],
      );

      await repository.load('#2J8V28GV0');
      expect(fakeApi.getCallCounts['/links/user1/%232J8V28GV0/upgrades'], 1);

      repository.clearCache();

      // Remote config was reset — a shared device's next account never
      // reuses the previous account's remote link or in-memory snapshot.
      await repository.load('#2J8V28GV0');
      expect(fakeApi.getCallCounts['/links/user1/%232J8V28GV0/upgrades'], 1);
    },
  );

  test('load uses warmed cache unless forceRefresh is requested', () async {
    final fakeApi = FakeApiService();
    const endpoint = '/links/user1/%232J8V28GV0/upgrades';
    fakeApi.getStubs[endpoint] = http.Response(
      jsonEncode({
        'data': {
          'tag': '#2J8V28GV0',
          'name': 'Remote',
          'buildings': <Object>[],
        },
      }),
      200,
    );
    final repository = UpgradeTrackerRepository(
      apiService: fakeApi,
      checkStaticDataFreshness: false,
    );
    await repository.importSnapshotBytes(
      utf8.encode(
        jsonEncode({
          'tag': '#2J8V28GV0',
          'name': 'Local',
          'buildings': [
            {'data': 1, 'lvl': 18},
          ],
        }),
      ),
      allowedTags: const {'#2J8V28GV0'},
    );
    repository.configureRemote(
      accountId: 'user1',
      verifiedPlayerTags: const ['#2J8V28GV0'],
    );

    final cached = await repository.load('#2J8V28GV0');
    final fresh = await repository.load('#2J8V28GV0', forceRefresh: true);

    expect(cached?.name, 'Local');
    expect(fresh?.name, 'Remote');
    expect(fakeApi.getCallCounts[endpoint], 1);
  });

  test('shared is a single reusable instance', () {
    expect(
      UpgradeTrackerRepository.shared,
      same(UpgradeTrackerRepository.shared),
    );
    expect(() => UpgradeTrackerRepository.shared.clearCache(), returnsNormally);
  });
}
