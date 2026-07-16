import 'dart:math';

import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class RemoteFeatureFlag {
  const RemoteFeatureFlag({
    required this.key,
    required this.enabled,
    required this.rolloutPercentage,
    required this.platforms,
    this.minAppVersion,
    this.startsAt,
    this.endsAt,
  });

  final String key;
  final bool enabled;
  final int rolloutPercentage;
  final List<String> platforms;
  final String? minAppVersion;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory RemoteFeatureFlag.fromJson(Map<String, dynamic> json) {
    return RemoteFeatureFlag(
      key: json['key'] as String? ?? '',
      enabled: json['enabled'] == true,
      rolloutPercentage: (json['rollout_percentage'] as num?)?.toInt() ?? 0,
      platforms:
          (json['platforms'] as List?)?.whereType<String>().toList() ??
          const [],
      minAppVersion: (json['min_app_version'] as String?)?.trim(),
      startsAt: DateTime.tryParse(json['starts_at'] as String? ?? ''),
      endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
    );
  }
}

class RemoteFeatureFlagService {
  RemoteFeatureFlagService({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

  final ApiService _apiService;
  Map<String, RemoteFeatureFlag> _flags = const {};
  int _installationSeed = 0;
  String _appVersion = '';

  Future<void> refresh() async {
    _installationSeed = await _loadInstallationSeed();
    _appVersion = (await PackageInfo.fromPlatform()).version;
    final response = await _apiService.get('/app/config', requiresAuth: false);
    final rawFlags = response['flags'];
    if (rawFlags is! List) return;
    _flags = {
      for (final json in rawFlags.whereType<Map<String, dynamic>>())
        if ((json['key'] as String? ?? '').isNotEmpty)
          json['key'] as String: RemoteFeatureFlag.fromJson(json),
    };
  }

  bool isEnabled(String key, {bool fallback = true, DateTime? now}) {
    final flag = _flags[key];
    if (flag == null) return fallback;
    final current = now ?? DateTime.now().toUtc();
    if (!flag.enabled) return false;
    if (flag.startsAt != null && flag.startsAt!.isAfter(current)) return false;
    if (flag.endsAt != null && !flag.endsAt!.isAfter(current)) return false;
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'web',
    };
    if (flag.platforms.isNotEmpty && !flag.platforms.contains(platform)) {
      return false;
    }
    final minimumVersion = flag.minAppVersion;
    if (minimumVersion != null &&
        minimumVersion.isNotEmpty &&
        !meetsMinimumVersion(_appVersion, minimumVersion)) {
      return false;
    }
    if (flag.rolloutPercentage >= 100) return true;
    if (flag.rolloutPercentage <= 0) return false;
    return _stableBucket(key) < flag.rolloutPercentage;
  }

  @visibleForTesting
  static bool meetsMinimumVersion(String current, String minimum) {
    final currentParts = _numericVersionParts(current);
    final minimumParts = _numericVersionParts(minimum);
    final length = max(currentParts.length, minimumParts.length);
    for (var index = 0; index < length; index++) {
      final currentPart = index < currentParts.length ? currentParts[index] : 0;
      final minimumPart = index < minimumParts.length ? minimumParts[index] : 0;
      if (currentPart != minimumPart) return currentPart > minimumPart;
    }
    return true;
  }

  static List<int> _numericVersionParts(String value) => value
      .split('+')
      .first
      .split('.')
      .map((part) => int.tryParse(RegExp(r'^\d+').stringMatch(part) ?? '') ?? 0)
      .toList(growable: false);

  int _stableBucket(String key) {
    var hash = 2166136261 ^ _installationSeed;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return hash % 100;
  }

  Future<int> _loadInstallationSeed() async {
    final stored = await getPrefs('remoteFeatureFlagSeed');
    final parsed = int.tryParse(stored ?? '');
    if (parsed != null) return parsed;
    final seed = Random.secure().nextInt(0x7fffffff);
    await storePrefs('remoteFeatureFlagSeed', seed.toString());
    return seed;
  }
}
