import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/achievements/data/achievements_repository.dart';
import 'package:clashkingapp/features/achievements/models/achievement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}

class _FakeApiService extends ApiService {
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
    return response;
  }
}
