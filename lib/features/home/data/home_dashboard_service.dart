import 'dart:convert';
import 'dart:io';

import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/home/models/home_dashboard_models.dart';

class HomeDashboardService {
  HomeDashboardService({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

  final ApiService _apiService;

  Future<HomeActivityResponse> getActivity({
    required String accountId,
    required List<Map<String, Object?>> mappings,
  }) async {
    final response = await _apiService.queryResponse(
      '/home/activity',
      body: {'account_id': accountId, 'mappings': mappings, 'limit': 25},
      requiresAuth: true,
    );
    return HomeActivityResponse.fromJson(
      _decodeMap(response.statusCode, ApiService.decodeResponseBody(response)),
    );
  }

  Future<HomeUpgradeRecord> getUpgrades({
    required String accountId,
    required String playerTag,
  }) async {
    final response = await _apiService.getResponse(
      _playerEndpoint(accountId, playerTag, 'upgrades'),
      requiresAuth: true,
    );
    return HomeUpgradeRecord.fromJson(
      _decodeMap(response.statusCode, ApiService.decodeResponseBody(response)),
    );
  }

  Future<HomeUpgradePreferences> getUpgradePreferences({
    required String accountId,
    required String playerTag,
  }) async {
    final response = await _apiService.getResponse(
      _playerEndpoint(accountId, playerTag, 'upgrade-preferences'),
      requiresAuth: true,
    );
    return HomeUpgradePreferences.fromJson(
      _decodeMap(response.statusCode, ApiService.decodeResponseBody(response)),
    );
  }

  Future<DateTime> updateLastLogin(String accountId) async {
    final endpoint = '/links/${Uri.encodeComponent(accountId)}/last-login';
    final response = await _apiService.patchResponse(
      endpoint,
      requiresAuth: true,
    );
    final decoded = _decodeMap(
      response.statusCode,
      ApiService.decodeResponseBody(response),
    );
    final timestamp = DateTime.tryParse(decoded['timestamp']?.toString() ?? '');
    if (timestamp == null) {
      throw const FormatException('last-login timestamp is invalid');
    }
    return timestamp.toUtc();
  }

  static String _playerEndpoint(
    String accountId,
    String playerTag,
    String resource,
  ) =>
      '/links/${Uri.encodeComponent(accountId)}/${Uri.encodeComponent(playerTag)}/$resource';

  static Map<String, dynamic> _decodeMap(int statusCode, String body) {
    if (statusCode < 200 || statusCode >= 300) {
      throw HttpException('Home API request failed ($statusCode)');
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Home API response must be an object');
    }
    return Map<String, dynamic>.from(decoded);
  }
}
