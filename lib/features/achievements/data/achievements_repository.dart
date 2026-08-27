import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/achievements/models/achievement.dart';
import 'package:flutter/foundation.dart';

class AchievementsRepository extends ChangeNotifier {
  AchievementsRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

  final ApiService _apiService;
  List<Achievement> _achievements = const [];
  bool _isRefreshing = false;
  int _sessionGeneration = 0;
  String? _sessionUserId;
  AuthService? _authService;

  List<Achievement> get achievements => List.unmodifiable(_achievements);
  bool get isRefreshing => _isRefreshing;

  void bindAuth(AuthService authService) {
    if (identical(_authService, authService)) return;
    _authService?.removeListener(_handleAuthChanged);
    _authService = authService;
    _sessionUserId = _currentSessionUserId;
    authService.addListener(_handleAuthChanged);
  }

  String? get _currentSessionUserId => _authService?.canUseApp == true
      ? _authService?.currentUser?.userId
      : null;

  void _handleAuthChanged() {
    final nextUserId = _currentSessionUserId;
    if (nextUserId == _sessionUserId) return;
    _sessionUserId = nextUserId;
    clear();
  }

  void clear() {
    _sessionGeneration++;
    _achievements = const [];
    _isRefreshing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService?.removeListener(_handleAuthChanged);
    super.dispose();
  }

  Future<void> load() async {
    final generation = _sessionGeneration;
    final response = await _apiService.get('/achievements', requiresAuth: true);
    if (generation != _sessionGeneration) return;
    _replaceFromResponse(response);
  }

  Future<void> check() async {
    if (_isRefreshing) return;
    final generation = _sessionGeneration;
    _isRefreshing = true;
    notifyListeners();
    try {
      final response = await _apiService.post(
        '/achievements/check',
        const {},
        requiresAuth: true,
      );
      if (generation != _sessionGeneration) return;
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
      for (final catalogItem in achievementCatalogFallback)
        ?remoteById[catalogItem.id],
    ];
    notifyListeners();
  }
}
