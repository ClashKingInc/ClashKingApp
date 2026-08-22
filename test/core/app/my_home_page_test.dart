import 'package:clashkingapp/core/app/my_home_page.dart';
import 'package:clashkingapp/core/app/my_app_state.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/coc_accounts/presentation/coc_account_management_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('signed-out home does not redirect to Clash account onboarding', (
    tester,
  ) async {
    final authService = AuthService();
    final cocAccountService = CocAccountService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MyAppState>(create: (_) => MyAppState()),
          ChangeNotifierProvider<AuthService>.value(value: authService),
          ChangeNotifierProvider<CocAccountService>.value(
            value: cocAccountService,
          ),
        ],
        child: const MaterialApp(home: MyHomePage()),
      ),
    );
    await tester.pump();

    expect(authService.canUseApp, isFalse);
    expect(cocAccountService.hasVerifiedAccounts, isFalse);
    expect(find.byType(AddCocAccountPage), findsNothing);
    expect(find.byType(MyHomePage), findsOneWidget);
  });
}
