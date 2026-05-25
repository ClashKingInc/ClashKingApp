import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:clashkingapp/core/functions/functions.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeDeviceInfoPlatform extends DeviceInfoPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<BaseDeviceInfo> deviceInfo() async {
    if (Platform.isWindows) {
      return WindowsDeviceInfo(
        computerName: 'TestPC',
        numberOfCores: 8,
        systemMemoryInMegabytes: 16384,
        userName: 'tester',
        majorVersion: 10,
        minorVersion: 0,
        buildNumber: 22631,
        platformId: 2,
        csdVersion: '',
        servicePackMajor: 0,
        servicePackMinor: 0,
        suitMask: 0,
        productType: 1,
        reserved: 0,
        buildLab: 'test',
        buildLabEx: 'test',
        digitalProductId: Uint8List(0),
        displayVersion: '11',
        editionId: 'Pro',
        installDate: DateTime(2024, 1, 1),
        productId: 'test-product',
        productName: 'Windows Test',
        registeredOwner: 'Tester',
        releaseId: '23H2',
        deviceId: 'device-id',
      );
    }

    if (Platform.isLinux) {
      return LinuxDeviceInfo(
        name: 'Test Linux',
        version: '1.0',
        id: 'test-linux',
        prettyName: 'Test Linux',
        machineId: 'machine-id',
      );
    }

    if (Platform.isMacOS) {
      return MacOsDeviceInfo.setMockInitialValues(
        computerName: 'Test Mac',
        hostName: 'test-mac.local',
        arch: 'arm64',
        model: 'Mac14,7',
        modelName: 'MacBook Pro',
        kernelVersion: '23.5.0',
        osRelease: '14.5',
        majorVersion: 14,
        minorVersion: 5,
        patchVersion: 0,
        activeCPUs: 8,
        memorySize: 16384,
        cpuFrequency: 3200,
        systemGUID: 'guid',
      );
    }

    throw UnsupportedError(
      'Unsupported test platform: ${Platform.operatingSystem}',
    );
  }
}

Future<BuildContext> _pumpLocalizedApp(WidgetTester tester) async {
  late BuildContext context;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (buildContext) {
          context = buildContext;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return context;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'ClashKing',
      packageName: 'com.clashking.app',
      version: '1.2.3',
      buildNumber: '42',
      buildSignature: 'signature',
    );
  });

  group('functions.dart additional coverage', () {
    group('storage helpers', () {
      test('stores and retrieves preferences', () async {
        await storePrefs('selectedTag', '#PLAYER');

        expect(await getPrefs('selectedTag'), '#PLAYER');
      });

      test('deletes a stored preference', () async {
        await storePrefs('selectedTag', '#PLAYER');
        await deletePrefs('selectedTag');

        expect(await getPrefs('selectedTag'), isNull);
      });

      test('clears all stored preferences', () async {
        await storePrefs('selectedTag', '#PLAYER');
        await storePrefs('player_#PLAYER_clan_tag', '#CLAN');
        await clearPrefs();

        expect(await getPrefs('selectedTag'), isNull);
        expect(await getPrefs('player_#PLAYER_clan_tag'), isNull);
      });
    });

    testWidgets('getEndedAgoText returns localized text for each branch', (
      tester,
    ) async {
      final context = await _pumpLocalizedApp(tester);
      final localizations = AppLocalizations.of(context)!;

      expect(getEndedAgoText(null, context), localizations.generalUnknown);
      expect(
        getEndedAgoText(
          DateTime.now().subtract(const Duration(seconds: 30)),
          context,
        ),
        localizations.timeEndedJustNow,
      );
      expect(
        getEndedAgoText(
          DateTime.now().subtract(const Duration(minutes: 5)),
          context,
        ),
        localizations.timeEndedMinutesAgo(5),
      );
      expect(
        getEndedAgoText(
          DateTime.now().subtract(const Duration(hours: 3)),
          context,
        ),
        localizations.timeEndedHoursAgo(3),
      );
      expect(
        getEndedAgoText(
          DateTime.now().subtract(const Duration(days: 2)),
          context,
        ),
        localizations.timeEndedDaysAgo(2),
      );
    });

    test('getAppAndDeviceInfo returns version and platform details', () async {
      final previousPlatform = DeviceInfoPlatform.instance;
      DeviceInfoPlatform.instance = _FakeDeviceInfoPlatform();
      addTearDown(() => DeviceInfoPlatform.instance = previousPlatform);

      final info = await getAppAndDeviceInfo();

      expect(info, contains('Version: 1.2.3 (Build 42)'));
      if (Platform.isWindows) {
        expect(info, contains('Device: TestPC, OS: Windows 11'));
      } else if (Platform.isLinux) {
        expect(info, contains('Device: Test Linux, OS: Linux 1.0'));
      } else if (Platform.isMacOS) {
        expect(info, contains('Device: Mac14,7, OS: macOS 14.5'));
      }
    });
  });
}
