import 'package:clashkingapp/common/widgets/app_bar/app_bar.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('profile and search keep 16 pixels of horizontal padding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>(
        create: (_) => AuthService(),
        child: const MaterialApp(
          home: Scaffold(
            appBar: MainPageHeader(
              title: 'ClashKing',
              searchHint: 'Search players or clans',
            ),
          ),
        ),
      ),
    );

    final profile = tester.getRect(
      find.byKey(const ValueKey('main-page-header-profile')),
    );
    final search = tester.getRect(
      find.byKey(const ValueKey('main-page-header-search')),
    );

    expect(profile.left, 16);
    expect(search.right, 374);
  });
}
