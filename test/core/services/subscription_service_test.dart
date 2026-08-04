import 'dart:convert';

import 'package:clashkingapp/core/services/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fake_services.dart';

void main() {
  test('loads the Stripe-backed ClashKing entitlement', () async {
    final api = FakeApiService();
    api.getStubs[SubscriptionService.statusEndpoint] = http.Response(
      jsonEncode({
        'provider': 'stripe',
        'status': 'active',
        'active': true,
        'bookmarkNotificationsLimit': 10,
        'rosterAssistantMonthlyCreditUsd': 5.0,
      }),
      200,
    );

    final status = await SubscriptionService(apiService: api).load();

    expect(status.provider, 'stripe');
    expect(status.active, isTrue);
    expect(status.bookmarkNotificationsLimit, 10);
    expect(status.rosterAssistantMonthlyCreditUsd, 5.0);
  });
}
