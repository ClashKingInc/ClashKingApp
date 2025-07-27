import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as material;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:clashkingapp/l10n/app_localizations.dart';

final storage = FlutterSecureStorage();

Future<void> storePrefs(String name, String token) async {
  try {
    await storage.write(key: name, value: token);
  } catch (exception, stackTrace) {
    final hint = Hint.withMap(
        {'message': 'Error storing prefs', 'name': name, 'token': token});
    Sentry.captureException(exception, stackTrace: stackTrace,
        withScope: (scope) {
      scope.setContexts('Storage Context', hint);
    });
  }
}

Future<String?> getPrefs(String name) async {
  try {
    return await storage.read(key: name);
  } catch (exception, stackTrace) {
    Sentry.captureException(exception, stackTrace: stackTrace);
    Sentry.captureMessage('Error retrieving prefs, name: $name');
    return null;
  }
}

Future<void> deletePrefs(String name) async {
  try {
    await storage.delete(key: name);
  } catch (exception, stackTrace) {
    Sentry.captureException(exception, stackTrace: stackTrace);
    Sentry.captureMessage('Error deleting prefs, name: $name');
  }
}

Future<void> clearPrefs() async {
  await storage.deleteAll();
}

Future<String> getAppAndDeviceInfo() async {
  // Fetch app version and build number
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;

  // Fetch device information
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String deviceData;

  if (!kIsWeb && Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceData =
        'Device: ${androidInfo.model}, OS: Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
  } else if (!kIsWeb && Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceData =
        'Device: ${iosInfo.utsname.machine}, OS: iOS ${iosInfo.systemVersion}';
  } else if (!kIsWeb && Platform.isMacOS) {
    MacOsDeviceInfo macInfo = await deviceInfo.macOsInfo;
    deviceData = 'Device: ${macInfo.model}, OS: macOS ${macInfo.osRelease}';
  } else if (!kIsWeb && Platform.isWindows) {
    WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
    deviceData =
        'Device: ${windowsInfo.computerName}, OS: Windows ${windowsInfo.displayVersion}';
  } else if (!kIsWeb && Platform.isLinux) {
    LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
    deviceData = 'Device: ${linuxInfo.name}, OS: Linux ${linuxInfo.version}';
  } else {
    deviceData = 'Unknown Platform';
  }

  return 'Version: $version (Build $buildNumber)\n$deviceData';
}

String getEndedAgoText(DateTime? endTime, material.BuildContext context) {
  if (endTime == null) return AppLocalizations.of(context)!.generalUnknown;

  final localEndTime = endTime.toLocal();
  final now = DateTime.now();
  final difference = now.difference(localEndTime);

  final l10n = AppLocalizations.of(context)!;

  if (difference.inMinutes < 1) {
    return l10n.timeEndedJustNow; // "Ended just now"
  } else if (difference.inMinutes < 60) {
    return l10n.timeEndedMinutesAgo(difference.inMinutes); // "Ended X minutes ago"
  } else if (difference.inHours < 24) {
    return l10n.timeEndedHoursAgo(difference.inHours); // "Ended X hours ago"
  } else {
    return l10n.timeEndedDaysAgo(difference.inDays); // "Ended X days ago"
  }
}

bool isInTimeFrameForRaid() {
  DateTime nowUtc = DateTime.now().toUtc();
  bool isInTimeFrameForRaid = false;

  if (nowUtc.weekday == DateTime.friday && nowUtc.hour >= 7) {
    isInTimeFrameForRaid = true;
  } else if (nowUtc.weekday == DateTime.saturday ||
      nowUtc.weekday == DateTime.sunday) {
    isInTimeFrameForRaid = true;
  } else if (nowUtc.weekday == DateTime.monday && nowUtc.hour < 7) {
    isInTimeFrameForRaid = true;
  }

  return isInTimeFrameForRaid;
}

bool isInTimeFrameForClanGames() {
  DateTime nowUtc = DateTime.now().toUtc();
  bool isInTimeFrameForClanGames = false;

  if ((nowUtc.day == 22 && nowUtc.hour >= 8) ||
      (nowUtc.day >= 23 && nowUtc.day <= 27) ||
      (nowUtc.day == 28 && nowUtc.hour <= 8)) {
    isInTimeFrameForClanGames = true;
  }

  return isInTimeFrameForClanGames;
}

bool isInTimeFrameForCwl() {
  DateTime nowUtc = DateTime.now().toUtc();
  bool isInTimeFrameForCwl = false;

  if (nowUtc.day >= 1 && nowUtc.day <= 12) {
    isInTimeFrameForCwl = true;
  }

  return isInTimeFrameForCwl;
}

String formatSecondsToHHMM(double seconds) {
  final duration = Duration(seconds: seconds.round());
  final hours = duration.inHours.toString().padLeft(2, '0');
  final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
  return '$hours:$minutes';
}

DateTime findLastMondayOfMonth(int year, int month) {
  DateTime firstDayOfNextMonth = DateTime(year, month + 1, 1);

  DateTime lastDayOfMonth = firstDayOfNextMonth.subtract(Duration(days: 1));

  int weekdayOfLastDay = lastDayOfMonth.weekday;

  int daysToLastMonday = (weekdayOfLastDay - DateTime.monday) % 7;

  DateTime lastMondayOfMonth =
      lastDayOfMonth.subtract(Duration(days: daysToLastMonday));

  return lastMondayOfMonth;
}

int get requiredSeasonPassPoints {
  try {
    final now = DateTime.now();
    int totalDaysInMonth = DateTime(now.year, now.month + 1, 0).day;
    int daysPassed = now.day;
    int requiredPoints = ((daysPassed * 2600) / totalDaysInMonth).toInt();
    return requiredPoints;
  } catch (e) {
    return 0;
  }
}

int get requiredClanGamesPoints {
  try {
    final now = DateTime.now();
    DateTime clanGamesStart = DateTime(now.year, now.month, 22, 8);
    int daysPassed = now.difference(clanGamesStart).inDays;
    int requiredPoints = ((daysPassed * 4000) / 6).toInt();
    return requiredPoints;
  } catch (e) {
    return 0;
  }
}
