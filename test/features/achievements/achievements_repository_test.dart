import 'dart:async';
import 'dart:collection';

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/config/api_config.dart';
import 'package:clashkingapp/features/achievements/data/achievements_repository.dart';
import 'package:clashkingapp/features/achievements/models/achievement.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('does not expose catalog entries before an authenticated response', () {
    final repository = AchievementsRepository(apiService: _FakeApiService());

    expect(repository.achievements, isEmpty);
  });

  test(
    'check uses the authenticated endpoint and maps all achievement states',
    () async {
      final api = _FakeApiService();
      final repository = AchievementsRepository(apiService: api);

      await repository.check();

      expect(api.lastEndpoint, '/achievements/check');
      expect(api.lastRequiresAuth, isTrue);
      expect(repository.achievements, hasLength(4));
      expect(
        repository.achievements
            .firstWhere((item) => item.id == AchievementId.townhall18)
            .earnedCount,
        3,
      );
      expect(
        repository.achievements
            .firstWhere((item) => item.id == AchievementId.warWarrior)
            .isUnlocked,
        isTrue,
      );
      expect(
        repository.achievements
            .firstWhere((item) => item.id == AchievementId.mrLegend)
            .isUnlocked,
        isFalse,
      );
      expect(
        repository.achievements
            .firstWhere((item) => item.id == AchievementId.defenseDoesntMatter)
            .modelUrl,
        endsWith('bad-legends-achievement-badge.glb'),
      );
    },
  );

  test(
    'load uses the catalog endpoint without running an award check',
    () async {
      final api = _FakeApiService();
      final repository = AchievementsRepository(apiService: api);

      await repository.load();

      expect(api.lastEndpoint, '/achievements');
      expect(api.lastRequiresAuth, isTrue);
    },
  );

  test('clear removes account-scoped state and notifies listeners', () async {
    final repository = AchievementsRepository(apiService: _FakeApiService());
    await repository.check();
    var notifications = 0;
    repository.addListener(() => notifications++);

    repository.clear();

    expect(repository.achievements, isEmpty);
    expect(repository.isRefreshing, isFalse);
    expect(notifications, 1);
  });

  test('binding auth clears achievements when the session changes', () async {
    final api = _FakeApiService();
    final repository = AchievementsRepository(apiService: api);
    await repository.check();
    final auth = AuthService(
      apiService: api,
      environment: ApiEnvironment.local,
    );
    repository.bindAuth(auth);
    repository.bindAuth(auth);

    await auth.initializeAuth();

    expect(repository.achievements, isEmpty);
    repository.dispose();
    auth.dispose();
  });

  test('a stale request cannot clear a newer refresh state', () async {
    final api = _FakeApiService();
    final first = Completer<Map<String, dynamic>>();
    final second = Completer<Map<String, dynamic>>();
    api.postResponses.addAll([first, second]);
    final repository = AchievementsRepository(apiService: api);

    final firstCheck = repository.check();
    repository.clear();
    final secondCheck = repository.check();
    first.complete(_FakeApiService.response);
    await firstCheck;

    expect(repository.isRefreshing, isTrue);
    second.complete(_FakeApiService.response);
    await secondCheck;
    expect(repository.isRefreshing, isFalse);
  });
}

class _FakeApiService extends ApiService {
  final Queue<Completer<Map<String, dynamic>>> postResponses = Queue();
  String? lastEndpoint;
  bool? lastRequiresAuth;

  static const response = <String, dynamic>{
    'items': <Map<String, dynamic>>[
      {
        'id': 'townhall_18',
        'asset_url':
            'https://assets.clashk.ing/achievements/town-hall-18-achievement-badge.glb',
        'repeatable': true,
        'earned_count': 3,
      },
      {
        'id': 'war_warrior',
        'asset_url':
            'https://assets.clashk.ing/achievements/war-champion-achievement-badge.glb',
        'repeatable': true,
        'earned_count': 1,
      },
      {
        'id': 'mr_legend',
        'asset_url':
            'https://assets.clashk.ing/achievements/perfect-legends-day-achievement-badge.glb',
        'repeatable': true,
        'earned_count': 0,
      },
      {
        'id': 'defense_doesnt_matter',
        'asset_url':
            'https://assets.clashk.ing/achievements/bad-legends-achievement-badge.glb',
        'repeatable': true,
        'earned_count': 0,
      },
    ],
  };

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    lastEndpoint = endpoint;
    lastRequiresAuth = requiresAuth;
    if (endpoint == '/auth/me') {
      return const {
        'user_id': 'achievement-test-user',
        'discord_username': 'Achievement Tester',
        'avatar_url': '',
        'auth_methods': <String>['discord'],
      };
    }
    return response;
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, String> body, {
    bool requiresAuth = false,
  }) async {
    lastEndpoint = endpoint;
    lastRequiresAuth = requiresAuth;
    if (postResponses.isNotEmpty) return postResponses.removeFirst().future;
    return response;
  }
}
