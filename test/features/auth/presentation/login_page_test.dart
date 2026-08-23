import 'package:clashkingapp/features/auth/presentation/login_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildLogin({required bool discordSignInEnabled}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LoginPage(discordSignInEnabled: discordSignInEnabled),
    );
  }

  testWidgets('shows Discord and email modes when Discord is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(buildLogin(discordSignInEnabled: true));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('login-auth-mode-selector')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('discord-auth')), findsOneWidget);
    expect(find.byKey(const ValueKey('email-auth')), findsNothing);
  });

  testWidgets('shows only email when Discord is disabled', (tester) async {
    await tester.pumpWidget(buildLogin(discordSignInEnabled: false));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('login-auth-mode-selector')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('discord-auth')), findsNothing);
    expect(find.byKey(const ValueKey('email-auth')), findsOneWidget);
  });

  testWidgets('uses email copy on wide previews when Discord is disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildLogin(discordSignInEnabled: false));
    await tester.pump();

    final context = tester.element(find.byType(LoginPage));
    final l10n = AppLocalizations.of(context)!;
    expect(find.text(l10n.authDiscordSignIn), findsNothing);
    expect(find.text(l10n.authLogin), findsOneWidget);
    expect(find.byKey(const ValueKey('email-auth')), findsOneWidget);
  });
}
