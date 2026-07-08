import 'dart:convert';

import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fake_services.dart';

const testUserId = 'user-123';
const testBookmarksEndpoint = '/links/user-123/bookmarks';
const testPlayerBookmarksEndpoint = '/links/user-123/bookmarks?type=player';
const testClanBookmarksEndpoint = '/links/user-123/bookmarks?type=clan';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  BookmarkService serviceWith(FakeApiService fakeApi) {
    final service = BookmarkService(apiService: fakeApi);
    service.setCurrentUserId(testUserId);
    return service;
  }

  void stubBookmarkLoad(
    FakeApiService fakeApi, {
    List<Map<String, dynamic>> players = const [],
    List<Map<String, dynamic>> clans = const [],
  }) {
    fakeApi.getStubs[testPlayerBookmarksEndpoint] = http.Response(
      jsonEncode({'items': players}),
      200,
    );
    fakeApi.getStubs[testClanBookmarksEndpoint] = http.Response(
      jsonEncode({'items': clans}),
      200,
    );
  }

  test('loads API bookmarks into tag-only snapshots', () async {
    final fakeApi = FakeApiService();
    stubBookmarkLoad(
      fakeApi,
      players: [
        {'type': 'player', 'tag': '#P1', 'player_tag': '#P1'},
      ],
      clans: [
        {'type': 'clan', 'tag': '#C1', 'clan_tag': '#C1'},
      ],
    );
    final service = serviceWith(fakeApi);

    await service.load();

    expect(service.players.map((player) => player.tag), ['#P1']);
    expect(service.clans.map((clan) => clan.tag), ['#C1']);
  });

  test('reloads from API after auth user is set post-construction', () async {
    final fakeApi = FakeApiService();
    stubBookmarkLoad(
      fakeApi,
      players: [
        {'tag': '#API', 'player_tag': '#API'},
      ],
    );
    final service = BookmarkService(apiService: fakeApi);

    await service.load();
    expect(service.loaded, isFalse);
    expect(service.players, isEmpty);

    service.setCurrentUserId(testUserId);
    expect(service.loaded, isFalse);

    await service.load();
    expect(service.players.map((player) => player.tag), ['#API']);
  });

  test('adds player bookmark through links bookmarks endpoint', () async {
    final fakeApi = FakeApiService();
    stubBookmarkLoad(fakeApi);
    final service = serviceWith(fakeApi);
    await service.load();

    await service.addPlayer(_bookmarkPlayer('#P1'));

    expect(fakeApi.lastPostBodies[testBookmarksEndpoint], {
      'type': 'player',
      'tag': '#P1',
    });
    expect(service.isPlayerBookmarked('#P1'), isTrue);
  });

  test('removes clan bookmark through typed bookmark endpoint', () async {
    final fakeApi = FakeApiService();
    stubBookmarkLoad(fakeApi);
    final service = serviceWith(fakeApi);
    await service.load();
    await service.addClan(_bookmarkClan('#C1'));

    await service.removeClan('#C1');

    expect(
      fakeApi.lastDeleteBodies,
      containsPair('/links/user-123/bookmarks/clan/%23C1', isNull),
    );
    expect(service.isClanBookmarked('#C1'), isFalse);
  });

  test(
    'sends typed ordered tags when player bookmarks are reordered',
    () async {
      final fakeApi = FakeApiService();
      stubBookmarkLoad(fakeApi);
      final service = serviceWith(fakeApi);
      await service.load();
      await service.addPlayer(_bookmarkPlayer('#P1'));
      await service.addPlayer(_bookmarkPlayer('#P2'));

      await service.reorderPlayer(1, 0);

      expect(fakeApi.lastPutBodies['/links/user-123/bookmarks/order'], {
        'type': 'player',
        'ordered_tags': ['#P1', '#P2'],
      });
    },
  );
}

BookmarkedPlayer _bookmarkPlayer(String tag) {
  return BookmarkedPlayer(
    tag: tag,
    name: tag,
    townHallLevel: 0,
    townHallPic: '',
    clanTag: '',
    clanName: '',
    trophies: 0,
    league: '',
    leagueUrl: '',
  );
}

BookmarkedClan _bookmarkClan(String tag) {
  return BookmarkedClan(
    tag: tag,
    name: tag,
    badgeUrl: '',
    clanLevel: 0,
    memberCount: 0,
  );
}
