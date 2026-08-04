import 'dart:convert';
import 'dart:io';

import 'package:clashkingapp/core/models/subscription_status.dart';
import 'package:clashkingapp/core/services/api_service.dart';

class SubscriptionService {
  SubscriptionService({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

  static const statusEndpoint = '/billing/subscription';

  final ApiService _apiService;

  Future<SubscriptionStatus> load() async {
    final response = await _apiService.getResponse(
      statusEndpoint,
      requiresAuth: true,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to load subscription (${response.statusCode})',
        uri: response.request?.url,
      );
    }
    final decoded = jsonDecode(ApiService.decodeResponseBody(response));
    if (decoded is! Map) {
      throw const FormatException('Invalid subscription response');
    }
    return SubscriptionStatus.fromJson(Map<String, dynamic>.from(decoded));
  }
}
