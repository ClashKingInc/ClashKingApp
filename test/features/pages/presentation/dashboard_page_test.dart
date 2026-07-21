import 'dart:convert';

import 'package:clashkingapp/core/models/user.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/home/data/home_dashboard_controller.dart';
import 'package:clashkingapp/features/home/data/home_dashboard_service.dart';
import 'package:clashkingapp/features/pages/presentation/dashboard_page.dart';
import 'package:clashkingapp/features/player/data/player_service.dart';
import 'package:clashkingapp/features/war_cwl/data/war_cwl_service.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../helpers/fake_services.dart';

void main() {
  testWidgets('renders fixed-order Home attention sections', (tester) async {
    final api = FakeApiService();
    api.getStubs['/links/user-1'] = http.Response(
      jsonEncode({
        'items': [
          {
            'player_tag': '#ABC',
            'is_verified': true,
            'hidden': false,
            'last_login': '2026-07-20T12:00:00Z',
          },
        ],
      }),
      200,
    );
    api.queryStubs['/home/activity'] = http.Response('{"items":[]}', 200);
    api.getStubs['/links/user-1/%23ABC/upgrades'] = http.Response(
      '{"player_tag":"#ABC","data":{},"updated_at":null}',
      200,
    );
    api.patchStubs['/links/user-1/last-login'] = http.Response(
      '{"timestamp":"2026-07-20T13:00:00Z","updated_count":1}',
      200,
    );
    final accounts = CocAccountService(
      apiService: api,
      currentUserId: 'user-1',
    );
    await accounts.fetchCocAccounts();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>(
            create: (_) => _FakeAuthService(),
          ),
          ChangeNotifierProvider.value(value: accounts),
          ChangeNotifierProvider(create: (_) => PlayerService(apiService: api)),
          ChangeNotifierProvider(create: (_) => WarCwlService(apiService: api)),
          ChangeNotifierProvider(
            create: (_) => HomeDashboardController(
              service: HomeDashboardService(apiService: api),
            ),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: DashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('To do'), findsOneWidget);
    expect(find.text('Since away'), findsOneWidget);
    expect(find.text('Your pulse'), findsOneWidget);
    expect(find.byType(PageView), findsNothing);
  });
}

class _FakeAuthService extends AuthService {
  @override
  User? get currentUser =>
      User(userId: 'user-1', username: 'Tester', avatarUrl: '');
}
