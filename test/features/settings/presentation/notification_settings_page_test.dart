import 'package:clashkingapp/core/models/notification_preferences.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/bookmark_service.dart';
import 'package:clashkingapp/core/services/notification_preferences_service.dart';
import 'package:clashkingapp/features/coc_accounts/data/coc_account_service.dart';
import 'package:clashkingapp/features/settings/presentation/notification_settings_page.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'shows current notification categories without legacy selectors',
    (tester) async {
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => CocAccountService(apiService: ApiService.shared),
            ),
            ChangeNotifierProvider(
              create: (_) => BookmarkService(apiService: ApiService.shared),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: NotificationSettingsPage(
              preferencesService: _FakeNotificationPreferencesService(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      for (final category in NotificationCategory.values) {
        final key = category == NotificationCategory.warReminders
            ? 'notification-warReminders'
            : 'notification-${category.name}';
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      expect(find.text('Defenses against your base'), findsNothing);
      expect(find.text('All attacks'), findsNothing);
      expect(find.text('Clan Games'), findsNothing);
      expect(find.text('War starts'), findsNothing);
      expect(find.text('War ends'), findsNothing);
      expect(find.text('Town Hall'), findsNothing);
      expect(find.text('Clan'), findsNothing);
      expect(find.text('All accounts'), findsNothing);
    },
  );
}

class _FakeNotificationPreferencesService
    extends NotificationPreferencesService {
  _FakeNotificationPreferencesService()
    : super(
        apiService: ApiService.shared,
        deviceIdProvider: () async => 'device-1',
        environmentProvider: () => 'sandbox',
      );

  final settings = const NotificationPreferences(
    deviceId: 'device-1',
    environment: 'sandbox',
  );

  @override
  Future<NotificationPreferences> load() async => settings;

  @override
  Future<NotificationPreferences> loadLocal() async => settings;

  @override
  Future<NotificationPreferences> save(
    NotificationPreferences settings,
  ) async => settings;
}
