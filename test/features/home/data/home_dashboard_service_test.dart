import 'dart:convert';

import 'package:clashkingapp/features/home/data/home_dashboard_controller.dart';
import 'package:clashkingapp/features/home/data/home_dashboard_service.dart';
import 'package:clashkingapp/features/home/models/home_dashboard_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

void main() {
  test('uses the exact QUERY activity contract and limit', () async {
    final api = FakeApiService();
    api.queryStubs['/home/activity'] = http.Response('{"items":[]}', 200);
    final service = HomeDashboardService(apiService: api);

    await service.getActivity(
      accountId: 'user-1',
      mappings: const [
        {'player_tag': '#ABC', 'clan_tag': null},
      ],
    );

    expect(api.lastQueryBodies['/home/activity'], {
      'account_id': 'user-1',
      'mappings': [
        {'player_tag': '#ABC', 'clan_tag': null},
      ],
      'limit': 25,
    });
  });

  test('uses verified player upgrade and last-login paths', () async {
    final api = FakeApiService();
    const upgradeEndpoint = '/links/user-1/%23ABC/upgrades';
    api.getStubs[upgradeEndpoint] = http.Response(
      jsonEncode({
        'player_tag': '#ABC',
        'data': <String, dynamic>{},
        'updated_at': null,
      }),
      200,
    );
    api.patchStubs['/links/user-1/last-login'] = http.Response(
      '{"timestamp":"2026-07-20T13:00:00Z","updated_count":1}',
      200,
    );
    final service = HomeDashboardService(apiService: api);

    final upgrade = await service.getUpgrades(
      accountId: 'user-1',
      playerTag: '#ABC',
    );
    final timestamp = await service.updateLastLogin('user-1');

    expect(upgrade.playerTag, '#ABC');
    expect(timestamp, DateTime.parse('2026-07-20T13:00:00Z'));
    expect(api.lastPatchBodies, contains('/links/user-1/last-login'));
  });

  test(
    'keeps the prior login and patches only once per controller launch',
    () async {
      final service = _StubHomeDashboardService();
      final controller = HomeDashboardController(service: service);
      final accounts = <Map<String, dynamic>>[
        {
          'player_tag': '#ABC',
          'is_verified': true,
          'last_login': '2026-07-20T12:00:00Z',
        },
        {'player_tag': '#UNVERIFIED', 'is_verified': false},
      ];

      await controller.load(
        accountId: 'user-1',
        linkedAccounts: accounts,
        players: const [],
      );
      accounts.first['last_login'] = '2026-07-20T14:00:00Z';
      await controller.load(
        accountId: 'user-1',
        linkedAccounts: accounts,
        players: const [],
      );

      expect(controller.priorLastLogin, DateTime.parse('2026-07-20T12:00:00Z'));
      expect(service.lastLoginCalls, 1);
      expect(service.lastMappings, [
        {'player_tag': '#ABC', 'clan_tag': null},
      ]);
    },
  );
}

class _StubHomeDashboardService extends HomeDashboardService {
  int lastLoginCalls = 0;
  List<Map<String, Object?>> lastMappings = const [];

  @override
  Future<HomeActivityResponse> getActivity({
    required String accountId,
    required List<Map<String, Object?>> mappings,
  }) async {
    lastMappings = mappings;
    return const HomeActivityResponse(items: []);
  }

  @override
  Future<HomeUpgradeRecord> getUpgrades({
    required String accountId,
    required String playerTag,
  }) async =>
      HomeUpgradeRecord(playerTag: playerTag, data: const {}, updatedAt: null);

  @override
  Future<DateTime> updateLastLogin(String accountId) async {
    lastLoginCalls++;
    return DateTime.parse('2026-07-20T13:00:00Z');
  }
}
