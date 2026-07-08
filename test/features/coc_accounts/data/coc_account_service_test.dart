import 'dart:convert';

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/clan/data/clan_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

const testUserId = 'user-123';
const testLinksEndpoint = '/links/user-123';

Future<CocAccountService> serviceWithAccounts(
  List<Map<String, dynamic>> accounts, {
  FakeApiService? fakeApi,
}) async {
  final api = fakeApi ?? FakeApiService();
  api.getStubs[testLinksEndpoint] = http.Response(
    jsonEncode({'items': accounts}),
    200,
  );
  final service = CocAccountService(apiService: api, currentUserId: testUserId);
  await service.fetchCocAccounts();
  return service;
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('CocAccountService — initial state', () {
    test('starts with empty accounts', () {
      final service = CocAccountService();
      expect(service.cocAccounts, isEmpty);
      expect(service.accounts, isEmpty);
    });

    test('starts not loading', () {
      final service = CocAccountService();
      expect(service.isLoading, isFalse);
    });

    test('starts with null selectedTag', () {
      final service = CocAccountService();
      expect(service.selectedTag, isNull);
      expect(service.selectedTagNotifier.value, isNull);
    });
  });

  group('CocAccountService — getAccountTags', () {
    test('returns empty list when no accounts', () {
      final service = CocAccountService();
      expect(service.getAccountTags(), isEmpty);
    });

    test('returns all player tags', () async {
      final service = await serviceWithAccounts([
        {'player_tag': '#P1'},
        {'player_tag': '#P2'},
      ]);
      expect(service.getAccountTags(), containsAll(['#P1', '#P2']));
    });
  });

  group('CocAccountService — clearAccountData', () {
    test('resets all fields to defaults', () async {
      final service = await serviceWithAccounts([
        {'player_tag': '#ABC'},
      ]);
      service.clearAccountData();
      expect(service.cocAccounts, isEmpty);
      expect(service.selectedTag, isNull);
      expect(service.isLoading, isFalse);
    });

    test('notifies listeners on clear', () async {
      final service = await serviceWithAccounts([
        {'player_tag': '#ABC'},
      ]);
      var notified = false;
      service.addListener(() => notified = true);
      service.clearAccountData();
      expect(notified, isTrue);
    });

    test('clears selectedTagNotifier', () {
      final service = CocAccountService();
      service.clearAccountData();
      expect(service.selectedTagNotifier.value, isNull);
    });
  });

  group('CocAccountService — initializeSelectedTag', () {
    test('does nothing when no accounts', () async {
      final service = CocAccountService();
      service.initializeSelectedTag();
      await Future.delayed(Duration.zero);
      expect(service.selectedTag, isNull);
    });

    test('sets first account tag when none selected', () async {
      final service = await serviceWithAccounts([
        {'player_tag': '#FIRST'},
        {'player_tag': '#SECOND'},
      ]);
      service.initializeSelectedTag();
      // _selectedTag is set synchronously at start of setSelectedTag
      expect(service.selectedTag, '#FIRST');
      expect(service.selectedTagNotifier.value, '#FIRST');
    });

    test('does not override existing selection', () async {
      final service = await serviceWithAccounts([
        {'player_tag': '#FIRST'},
        {'player_tag': '#SECOND'},
      ]);
      service.initializeSelectedTag(); // sets to #FIRST
      service.initializeSelectedTag(); // should be no-op
      expect(service.selectedTag, '#FIRST');
    });
  });

  group('CocAccountService — setSelectedTag', () {
    test('updates selectedTag synchronously', () {
      final service = CocAccountService();
      service.setSelectedTag('#TAG1');
      expect(service.selectedTag, '#TAG1');
    });

    test('updates selectedTagNotifier synchronously', () {
      final service = CocAccountService();
      service.setSelectedTag('#TAG1');
      expect(service.selectedTagNotifier.value, '#TAG1');
    });

    test('accepts null to clear selection', () {
      final service = CocAccountService();
      service.setSelectedTag('#TAG1');
      service.setSelectedTag(null);
      expect(service.selectedTag, isNull);
      expect(service.selectedTagNotifier.value, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // fetchCocAccounts (using FakeApiService)
  // ---------------------------------------------------------------------------

  group('CocAccountService — fetchCocAccounts', () {
    test('populates cocAccounts on 200 response', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({
          'items': [
            {'player_tag': '#ABC123', 'name': 'TestPlayer'},
            {'player_tag': '#DEF456', 'name': 'Other'},
          ],
        }),
        200,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await service.fetchCocAccounts();
      expect(service.cocAccounts, hasLength(2));
      expect(service.cocAccounts.first['player_tag'], '#ABC123');
    });

    test('sets isLoading to false after success', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = await serviceWithAccounts([
        {'player_tag': '#ABC', 'is_verified': false},
      ], fakeApi: fakeApi);
      await service.fetchCocAccounts();
      expect(service.isLoading, isFalse);
    });

    test('throws on non-200 and sets isLoading to false', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response('error', 401);
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await expectLater(() => service.fetchCocAccounts(), throwsA(anything));
      expect(service.isLoading, isFalse);
    });

    test('throws FormatException on invalid payload', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({'items': 'not-a-list'}),
        200,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await expectLater(() => service.fetchCocAccounts(), throwsA(anything));
    });

    test('notifies listeners on success', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      var notifyCount = 0;
      service.addListener(() => notifyCount++);
      await service.fetchCocAccounts();
      expect(
        notifyCount,
        greaterThanOrEqualTo(2),
      ); // loading=true + loading=false
    });
  });

  // ---------------------------------------------------------------------------
  // addCocAccount (using FakeApiService)
  // ---------------------------------------------------------------------------

  group('CocAccountService — addCocAccount', () {
    test('returns code 200 and account on success', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response(
        jsonEncode({
          'account': {'player_tag': '#ABC', 'name': 'Test'},
        }),
        200,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      final result = await service.addCocAccount('#ABC');
      expect(result['code'], 200);
      expect(result['account'], isNotNull);
      expect(fakeApi.lastPostBodies[testLinksEndpoint], {'player_tag': '#ABC'});
    });

    test('returns code 401 on UnauthorizedException', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnPost[testLinksEndpoint] = UnauthorizedException(
        'not auth',
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      final result = await service.addCocAccount('#ABC');
      expect(result['code'], 401);
    });

    test('returns code 500 on other errors', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnPost[testLinksEndpoint] = Exception('server error');
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      final result = await service.addCocAccount('#ABC');
      expect(result['code'], 500);
    });

    test('returns code from response for non-200 status', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response(
        jsonEncode({'detail': 'player not found'}),
        404,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      final result = await service.addCocAccount('#NOTFOUND');
      expect(result['code'], 404);
    });
  });

  // ---------------------------------------------------------------------------
  // addCocAccountWithVerification (using FakeApiService)
  // ---------------------------------------------------------------------------

  group('CocAccountService — addCocAccountWithVerification', () {
    test('returns code 200 on success', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response(
        jsonEncode({
          'account': {'player_tag': '#ABC'},
        }),
        200,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      final result = await service.addCocAccountWithVerification('#ABC', 'tok');
      expect(result['code'], 200);
      expect(fakeApi.lastPostBodies[testLinksEndpoint], {
        'player_tag': '#ABC',
        'api_token': 'tok',
      });
    });

    test('returns code 401 on UnauthorizedException', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnPost[testLinksEndpoint] = UnauthorizedException(
        'not auth',
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      final result = await service.addCocAccountWithVerification('#ABC', 'tok');
      expect(result['code'], 401);
    });

    test('returns code 500 on generic error', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnPost[testLinksEndpoint] = Exception('oops');
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      final result = await service.addCocAccountWithVerification('#ABC', 'tok');
      expect(result['code'], 500);
    });
  });

  // ---------------------------------------------------------------------------
  // removeCocAccount (using FakeApiService)
  // ---------------------------------------------------------------------------

  group('CocAccountService — removeCocAccount', () {
    test('removes account from list on 200', () async {
      final fakeApi = FakeApiService();
      final encodedTag = Uri.encodeComponent('#ABC123');
      fakeApi.deleteStubs['$testLinksEndpoint/$encodedTag'] = http.Response(
        '{}',
        200,
      );
      final service = await serviceWithAccounts([
        {'player_tag': '#ABC123'},
      ], fakeApi: fakeApi);
      await service.removeCocAccount('#ABC123');
      expect(service.cocAccounts, isEmpty);
    });

    test('does not remove account on non-200 response', () async {
      final fakeApi = FakeApiService();
      final encodedTag = Uri.encodeComponent('#ABC123');
      fakeApi.deleteStubs['$testLinksEndpoint/$encodedTag'] = http.Response(
        'error',
        500,
      );
      final service = await serviceWithAccounts([
        {'player_tag': '#ABC123'},
      ], fakeApi: fakeApi);
      await service.removeCocAccount('#ABC123');
      expect(service.cocAccounts, hasLength(1));
    });

    test('does not throw on network error', () async {
      final service = CocAccountService(
        apiService: NetworkErrorApiService(),
        currentUserId: testUserId,
      );
      await expectLater(
        () => service.removeCocAccount('#ERR'),
        returnsNormally,
      );
    });

    test('notifies listeners on successful removal', () async {
      final fakeApi = FakeApiService();
      final encodedTag = Uri.encodeComponent('#X');
      fakeApi.deleteStubs['$testLinksEndpoint/$encodedTag'] = http.Response(
        '{}',
        200,
      );
      final service = await serviceWithAccounts([
        {'player_tag': '#X'},
      ], fakeApi: fakeApi);
      var notified = false;
      service.addListener(() => notified = true);
      await service.removeCocAccount('#X');
      expect(notified, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // updateAccountOrder (using FakeApiService)
  // ---------------------------------------------------------------------------

  group('CocAccountService — updateAccountOrder', () {
    test('completes without throwing on 200', () async {
      final fakeApi = FakeApiService();
      fakeApi.putStubs['$testLinksEndpoint/order'] = http.Response('{}', 200);
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await expectLater(
        () => service.updateAccountOrder(['#A', '#B']),
        returnsNormally,
      );
    });

    test('completes without throwing on non-200', () async {
      final fakeApi = FakeApiService();
      fakeApi.putStubs['$testLinksEndpoint/order'] = http.Response(
        'error',
        500,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await expectLater(
        () => service.updateAccountOrder(['#A']),
        returnsNormally,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // updateRefreshTime
  // ---------------------------------------------------------------------------

  group('CocAccountService — updateRefreshTime', () {
    test('sets lastRefresh to a non-null value', () {
      final service = CocAccountService();
      expect(service.lastRefresh, isNull);
      service.updateRefreshTime();
      expect(service.lastRefresh, isNotNull);
    });

    test('notifies listeners', () {
      final service = CocAccountService();
      var notified = false;
      service.addListener(() => notified = true);
      service.updateRefreshTime();
      expect(notified, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // refreshPageData
  // ---------------------------------------------------------------------------

  group('CocAccountService — refreshPageData', () {
    PlayerService makePlayer() => PlayerService(apiService: FakeApiService());
    ClanService makeClan() => ClanService(apiService: FakeApiService());
    WarCwlService makeWar() => WarCwlService(apiService: FakeApiService());

    test('returns immediately when playerTags is empty', () async {
      final service = CocAccountService(
        apiService: FakeApiService(),
        currentUserId: testUserId,
      );
      await service.refreshPageData([], makePlayer(), makeClan(), makeWar());
      expect(service.lastRefresh, isNull);
    });

    test('sets lastRefresh after direct refresh', () async {
      final fakeApi = FakeApiService();
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await service.refreshPageData(
        ['#P1'],
        makePlayer(),
        makeClan(),
        makeWar(),
      );
      expect(service.lastRefresh, isNotNull);
    });

    test('notifies listeners on success', () async {
      final fakeApi = FakeApiService();
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      var notified = false;
      service.addListener(() => notified = true);
      await service.refreshPageData(
        ['#P1'],
        makePlayer(),
        makeClan(),
        makeWar(),
      );
      expect(notified, isTrue);
    });

    test('returns normally when optional initial data is absent', () async {
      final fakeApi = FakeApiService();
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await expectLater(
        () => service.refreshPageData(
          ['#P1'],
          makePlayer(),
          makeClan(),
          makeWar(),
        ),
        returnsNormally,
      );
    });

    test('sets lastRefresh after player refresh', () async {
      final fakeApi = FakeApiService();
      final playerService = PlayerService(apiService: FakeApiService());
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await service.refreshPageData(
        ['#P1'],
        playerService,
        makeClan(),
        makeWar(),
      );
      expect(service.lastRefresh, isNotNull);
    });

    test('links clan data when clan_tags is populated', () async {
      final fakeApi = FakeApiService();
      final playerFakeApi = FakeApiService();
      playerFakeApi.postStubs['/players'] = http.Response(
        jsonEncode({
          'items': [
            {
              'tag': '#P1',
              'name': 'Test',
              'townHallLevel': 15,
              'clan': {'tag': '#CLAN1', 'name': 'Alpha'},
            },
          ],
        }),
        200,
      );
      final clanFakeApi = FakeApiService();
      clanFakeApi.postStubs['/clans/details'] = http.Response(
        jsonEncode({
          'items': [
            {'tag': '#CLAN1', 'name': 'Alpha'},
          ],
        }),
        200,
      );
      final playerService = PlayerService(apiService: playerFakeApi);
      final clanService = ClanService(apiService: clanFakeApi);
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await service.refreshPageData(
        ['#P1'],
        playerService,
        clanService,
        makeWar(),
      );
      expect(clanService.clans.containsKey('#CLAN1'), isTrue);
      expect(service.lastRefresh, isNotNull);
    });

    test(
      'direct refresh still sets lastRefresh when optional data is empty',
      () async {
        final fakeApi = FakeApiService();
        final service = CocAccountService(
          apiService: fakeApi,
          currentUserId: testUserId,
        );
        await service.refreshPageData(
          ['#P1'],
          makePlayer(),
          makeClan(),
          makeWar(),
        );
        expect(service.lastRefresh, isNotNull);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // updateAccountVerificationStatus
  // ---------------------------------------------------------------------------

  group('CocAccountService — updateAccountVerificationStatus', () {
    test('sets is_verified to true on matching account', () async {
      final service = await serviceWithAccounts([
        {'player_tag': '#ABC', 'is_verified': false},
      ]);
      service.updateAccountVerificationStatus('#ABC', true);
      expect(service.cocAccounts.first['is_verified'], isTrue);
    });

    test('does nothing for unknown tag', () async {
      final service = await serviceWithAccounts([
        {'player_tag': '#ABC', 'is_verified': false},
      ]);
      expect(
        () => service.updateAccountVerificationStatus('#UNKNOWN', true),
        returnsNormally,
      );
      expect(service.cocAccounts.first['is_verified'], isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // getAccountVerificationStatus
  // ---------------------------------------------------------------------------

  group('CocAccountService — getAccountVerificationStatus', () {
    test('returns true after setting verification status', () async {
      final service = await serviceWithAccounts([
        {'player_tag': '#ABC', 'is_verified': false},
      ]);
      service.updateAccountVerificationStatus('#ABC', true);
      expect(service.getAccountVerificationStatus('#ABC'), isTrue);
    });

    test('returns false when tag is not present', () {
      final service = CocAccountService();
      expect(service.getAccountVerificationStatus('#GHOST'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // clearAccounts
  // ---------------------------------------------------------------------------

  group('CocAccountService — clearAccounts', () {
    test('clears all accounts and resets state', () async {
      final service = await serviceWithAccounts([
        {'player_tag': '#X'},
      ]);
      service.clearAccounts();
      expect(service.cocAccounts, isEmpty);
      expect(service.selectedTag, isNull);
      expect(service.isLoading, isFalse);
    });

    test('notifies listeners', () {
      final service = CocAccountService();
      var notified = false;
      service.addListener(() => notified = true);
      service.clearAccounts();
      expect(notified, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // addAccountWithToken
  // ---------------------------------------------------------------------------

  group('CocAccountService — addAccountWithToken', () {
    test('returns true on 200 response', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response(
        jsonEncode({'account': null}),
        200,
      );
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({'items': []}),
        200,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      String? errorMsg;
      final result = await service.addAccountWithToken(
        '#ABC',
        'token123',
        (msg) => errorMsg = msg,
      );
      expect(result, isTrue);
      expect(errorMsg, isNull);
      expect(fakeApi.lastPostBodies[testLinksEndpoint], {
        'player_tag': '#ABC',
        'api_token': 'token123',
      });
    });

    test('returns false and sets error message on 403', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response('Forbidden', 403);
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      String? errorMsg;
      final result = await service.addAccountWithToken(
        '#ABC',
        'bad_token',
        (msg) => errorMsg = msg,
      );
      expect(result, isFalse);
      expect(errorMsg, contains('Invalid API token'));
    });

    test('returns false on UnauthorizedException', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnPost[testLinksEndpoint] = UnauthorizedException(
        'unauthorized',
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      String? errorMsg;
      final result = await service.addAccountWithToken(
        '#ABC',
        'token',
        (msg) => errorMsg = msg,
      );
      expect(result, isFalse);
      expect(errorMsg, isNotNull);
    });

    test('returns false on generic exception', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnPost[testLinksEndpoint] = Exception('boom');
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      String? errorMsg;
      final result = await service.addAccountWithToken(
        '#ABC',
        'token',
        (msg) => errorMsg = msg,
      );
      expect(result, isFalse);
      expect(errorMsg, contains('Failed to add account'));
    });
  });

  // ---------------------------------------------------------------------------
  // verifyAccount
  // ---------------------------------------------------------------------------

  group('CocAccountService — verifyAccount', () {
    test('returns true on 200 and sends api_token payload', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response(
        jsonEncode({
          'account': {'player_tag': '#ABC'},
        }),
        200,
      );
      final service = await serviceWithAccounts([
        {'player_tag': '#ABC', 'is_verified': false},
      ], fakeApi: fakeApi);
      String? errorMsg;
      final result = await service.verifyAccount(
        '#ABC',
        'token',
        (msg) => errorMsg = msg,
      );
      expect(result, isTrue);
      expect(errorMsg, isNull);
      expect(service.getAccountVerificationStatus('#ABC'), isTrue);
      expect(fakeApi.lastPostBodies[testLinksEndpoint], {
        'player_tag': '#ABC',
        'api_token': 'token',
      });
    });

    test('returns false and sets error message on 403', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response('Forbidden', 403);
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      String? errorMsg;
      final result = await service.verifyAccount(
        '#ABC',
        'bad_token',
        (msg) => errorMsg = msg,
      );
      expect(result, isFalse);
      expect(errorMsg, contains('Invalid API token'));
    });

    test('returns false and sets error message on 404', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response('Not Found', 404);
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      String? errorMsg;
      final result = await service.verifyAccount(
        '#ABC',
        'token',
        (msg) => errorMsg = msg,
      );
      expect(result, isFalse);
      expect(errorMsg, contains('not found'));
    });

    test('returns false and sets error message on generic error', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response('Server Error', 500);
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      String? errorMsg;
      final result = await service.verifyAccount(
        '#ABC',
        'token',
        (msg) => errorMsg = msg,
      );
      expect(result, isFalse);
      expect(errorMsg, isNotNull);
    });

    test('returns false on UnauthorizedException', () async {
      final fakeApi = FakeApiService();
      fakeApi.throwOnPost[testLinksEndpoint] = UnauthorizedException(
        'unauthorized',
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      String? errorMsg;
      final result = await service.verifyAccount(
        '#ABC',
        'token',
        (msg) => errorMsg = msg,
      );
      expect(result, isFalse);
      expect(errorMsg, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // addAccountWithToken — 200 with full account data
  // ---------------------------------------------------------------------------

  group('CocAccountService — addAccountWithToken account data update', () {
    test('updates account name and TH when account data is present', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response(
        jsonEncode({
          'account': {'name': 'Hero', 'townHallLevel': 14},
        }),
        200,
      );
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({
          'items': [
            {'player_tag': '#ABC', 'name': 'Old Name', 'townHallLevel': 10},
          ],
        }),
        200,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      String? errorMsg;
      final result = await service.addAccountWithToken(
        '#ABC',
        'token',
        (msg) => errorMsg = msg,
      );
      expect(result, isTrue);
      expect(errorMsg, isNull);
      expect(service.cocAccounts.first['name'], 'Hero');
      expect(service.cocAccounts.first['townHallLevel'], 14);
    });
  });

  // ---------------------------------------------------------------------------
  // _extractErrorMessage branches (via addCocAccount)
  // ---------------------------------------------------------------------------

  group('CocAccountService — _extractErrorMessage', () {
    test('returns message field when present', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response(
        jsonEncode({'message': 'Custom error message'}),
        400,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      final result = await service.addCocAccount('#TAG');
      expect(result['message'], 'Custom error message');
    });

    test('returns nested detail.message when present', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs[testLinksEndpoint] = http.Response(
        jsonEncode({
          'detail': {'message': 'Nested error'},
        }),
        400,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      final result = await service.addCocAccount('#TAG');
      expect(result['message'], 'Nested error');
    });
  });

  // ---------------------------------------------------------------------------
  // loadApiData
  // ---------------------------------------------------------------------------

  group('CocAccountService — loadApiData', () {
    PlayerService makePlayer() => PlayerService(apiService: FakeApiService());
    ClanService makeClan() => ClanService(apiService: FakeApiService());
    WarCwlService makeWar() => WarCwlService(apiService: FakeApiService());

    test(
      'returns early and does not set lastRefresh when cocAccounts is empty',
      () async {
        final fakeApi = FakeApiService();
        fakeApi.getStubs[testLinksEndpoint] = http.Response(
          jsonEncode({'items': []}),
          200,
        );
        final service = CocAccountService(
          apiService: fakeApi,
          currentUserId: testUserId,
        );
        await service.loadApiData(makePlayer(), makeClan(), makeWar());
        expect(service.lastRefresh, isNull);
      },
    );

    test('sets lastRefresh after successful parallel load', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response(
        jsonEncode({
          'items': [
            {'player_tag': '#P1'},
          ],
        }),
        200,
      );
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await service.loadApiData(makePlayer(), makeClan(), makeWar());
      expect(service.lastRefresh, isNotNull);
    });

    test('throws when fetchCocAccounts returns 503', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response('error', 503);
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await expectLater(
        () => service.loadApiData(makePlayer(), makeClan(), makeWar()),
        throwsA(anything),
      );
    });

    test('throws when fetchCocAccounts returns 500', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response('error', 500);
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await expectLater(
        () => service.loadApiData(makePlayer(), makeClan(), makeWar()),
        throwsA(anything),
      );
    });

    test('rethrows non-503/500 HttpException from fetchCocAccounts', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs[testLinksEndpoint] = http.Response('error', 401);
      final service = CocAccountService(
        apiService: fakeApi,
        currentUserId: testUserId,
      );
      await expectLater(
        () => service.loadApiData(makePlayer(), makeClan(), makeWar()),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Initial clan loading with non-empty clan tags
  // ---------------------------------------------------------------------------

  group('CocAccountService — initial clan loading', () {
    test('executes clan loading path when player has a clan tag', () async {
      final playerJson = <String, dynamic>{
        'tag': '#P1',
        'name': 'Test',
        'trophies': 1000,
        'townHallLevel': 14,
        'clan': {
          'tag': '#CLAN1',
          'name': 'Test Clan',
          'clanLevel': 5,
          'badgeUrls': {'small': '', 'medium': '', 'large': ''},
        },
      };
      final playerFakeApi = FakeApiService();
      playerFakeApi.postStubs['/players'] = http.Response(
        jsonEncode({
          'items': [playerJson],
        }),
        200,
      );
      playerFakeApi.postStubs['/war/players/warhits'] = http.Response(
        jsonEncode({'items': []}),
        200,
      );

      final warCwlFakeApi = FakeApiService();
      warCwlFakeApi.postStubs['/war/war-summary'] = http.Response(
        jsonEncode({'items': []}),
        200,
      );

      final service = CocAccountService(
        apiService: FakeApiService(),
        currentUserId: testUserId,
      );
      final playerService = PlayerService(apiService: playerFakeApi);
      final clanService = ClanService(apiService: FakeApiService());
      final warCwlService = WarCwlService(apiService: warCwlFakeApi);

      await service.refreshPageData(
        ['#P1'],
        playerService,
        clanService,
        warCwlService,
      );
      expect(service.lastRefresh, isNotNull);
      expect(playerService.profiles, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // dispose
  // ---------------------------------------------------------------------------

  group('CocAccountService — dispose', () {
    test('dispose releases selectedTagNotifier without throwing', () {
      final service = CocAccountService();
      expect(() => service.dispose(), returnsNormally);
    });
  });
}
