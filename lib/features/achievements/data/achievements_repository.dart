import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/achievements/models/achievement.dart';
import 'package:flutter/foundation.dart';

class AchievementsRepository extends ChangeNotifier {
  AchievementsRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

  final ApiService _apiService;
  List<Achievement> _achievements = achievementCatalogFallback;
  bool _isRefreshing = false;

  List<Achievement> get achievements => List.unmodifiable(_achievements);
  bool get isRefreshing => _isRefreshing;

  Future<void> load() async {
    final response = await _apiService.get('/achievements', requiresAuth: true);
    _replaceFromResponse(response);
  }

  Future<void> check() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '/achievements/check',
        const {},
        requiresAuth: true,
      );
      _replaceFromResponse(response);
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  void _replaceFromResponse(Map<String, dynamic> response) {
    final rawItems = response['items'];
    if (rawItems is! List) {
      throw const FormatException('Achievement response is missing items.');
    }

    final remoteById = <AchievementId, Achievement>{};
    for (final rawItem in rawItems) {
      if (rawItem is! Map) continue;
      final item = Map<String, dynamic>.from(rawItem);
      final id = AchievementIdApi.tryParse(item['id'] as String? ?? '');
      final modelUrl = item['asset_url'];
      final earnedCount = item['earned_count'];
      final repeatable = item['repeatable'];
      if (id == null ||
          modelUrl is! String ||
          modelUrl.isEmpty ||
          earnedCount is! num ||
          repeatable is! bool) {
        continue;
      }
      remoteById[id] = Achievement(
        id: id,
        modelUrl: modelUrl,
        earnedCount: earnedCount.toInt().clamp(0, 1 << 31),
        isRepeatable: repeatable,
      );
    }

    _achievements = [
      for (final fallback in achievementCatalogFallback)
        remoteById[fallback.id] ?? fallback,
    ];
    notifyListeners();
  }
}
