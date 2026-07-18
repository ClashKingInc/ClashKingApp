import 'dart:convert';

import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/settings/presentation/privacy_controls_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../helpers/fake_services.dart';

void main() {
  testWidgets('prepares an export before enabling the save action', (
    tester,
  ) async {
    final fakeApi = FakeApiService();
    fakeApi.getStubs['/auth/export'] = http.Response(
      jsonEncode({
        'account': {'user_id': 'user-1'},
        'player_links': [
          {'player_tag': '#ABC123'},
        ],
      }),
      200,
    );
    final savedExports = <Map<String, String>>[];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthService>(
            create: (_) => AuthService(
              apiService: fakeApi,
              tokenService: FakeTokenService(fakeToken: 'header.payload.sig'),
            ),
          ),
          ChangeNotifierProvider<CocAccountService>(
            create: (_) =>
                CocAccountService(apiService: fakeApi, currentUserId: 'user-1'),
          ),
        ],
        child: MaterialApp(
          home: PrivacyControlsPage(
            saveExport: ({required fileName, required data}) async {
              savedExports.add({'fileName': fileName, 'data': data});
            },
          ),
        ),
      ),
    );

    expect(find.text('Prepare export'), findsOneWidget);
    expect(find.text('Save export'), findsNothing);

    await tester.tap(find.text('Prepare export'));
    await tester.pumpAndSettle();

    expect(fakeApi.getCallCounts['/auth/export'], 1);
    expect(find.text('Refresh export'), findsOneWidget);
    expect(find.text('Save export'), findsOneWidget);
    expect(find.text('Your data export is ready to save.'), findsOneWidget);

    await tester.tap(find.text('Save export'));
    await tester.pumpAndSettle();

    expect(savedExports, hasLength(1));
    expect(savedExports.single['fileName'], startsWith('clashking-data-'));
    expect(savedExports.single['fileName'], endsWith('.json'));
    expect(
      jsonDecode(savedExports.single['data']!)['account']['user_id'],
      'user-1',
    );
  });
}
