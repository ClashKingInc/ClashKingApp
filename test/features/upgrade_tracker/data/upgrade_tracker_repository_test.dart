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
}
