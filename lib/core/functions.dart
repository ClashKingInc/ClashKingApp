import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as material;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io' show Platform;
import 'package:clashkingapp/l10n/app_localizations.dart';

final String clientId = dotenv.env['DISCORD_CLIENT_ID']!;
final String redirectUri = dotenv.env['DISCORD_REDIRECT_URI']!;
final String clientSecret = dotenv.env['DISCORD_CLIENT_SECRET']!;
final String callbackUrlScheme = dotenv.env['DISCORD_CALLBACK_URL_SCHEME']!;
final storage = FlutterSecureStorage();

Future<bool> isTokenValid() async {
  String? expirationDateString = await getPrefs('expiration_date');
  if (expirationDateString != null) {
    DateTime expirationDate = DateTime.parse(expirationDateString);
    return DateTime.now().isBefore(expirationDate);
  }

  return false;
}

Future<bool> refreshToken() async {
  final refreshToken = await getPrefs("refresh_token");
  if (refreshToken == null) return false;

  final tokenUrl = Uri.https('discord.com', '/api/oauth2/token');
  final response = await http.post(tokenUrl, body: {
    'client_id': clientId,
    'client_secret': clientSecret,
    'grant_type': 'refresh_token',
    'refresh_token': refreshToken,
    'redirect_uri': redirectUri,
  });

  if (response.statusCode == 200) {
    final accessToken = jsonDecode(response.body)['access_token'] as String;
    final newRefreshToken =
        jsonDecode(response.body)['refresh_token'] as String;
    int expiresIn = jsonDecode(response.body)['expires_in'];

    DateTime expirationDate = DateTime.now().add(Duration(seconds: expiresIn));
    await storePrefs('access_token', accessToken);
    await storePrefs(
        'refresh_token', newRefreshToken); // Stocker le nouveau refreshToken
    await storePrefs('expiration_date', expirationDate.toIso8601String());

    return true;
  }

  return false;
}

Future<void> storePrefs(String name, String token) async {
  try {
    // Load the keys from the .env file
    await dotenv.load(fileName: ".env");
    final encryptionKey = Key.fromBase64(
        dotenv.env['ENCRYPTION_KEY']!); // 32 bytes key for AES-256
    final hmacKey = base64.decode(dotenv.env['HMAC_KEY']!); // Key for HMAC

    if (encryptionKey.bytes.length != 32) {
      throw Exception(
          'Invalid encryption key length: ${encryptionKey.bytes.length}');
    }

    if (hmacKey.length != 32) {
      throw Exception('Invalid HMAC key length: ${hmacKey.length}');
    }

    // Encrypt the token
    final iv = IV.fromLength(16); // Initialization vector
    final encrypter = Encrypter(AES(encryptionKey, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(token, iv: iv);

    // Combine IV and encrypted data for HMAC
    final combinedData = iv.bytes + encrypted.bytes;

    // Compute HMAC for integrity
    final hmac = Hmac(sha256, hmacKey);
    final hmacDigest = hmac.convert(combinedData).bytes;

    // Combine IV, encrypted data, and HMAC for storage
    final combined = base64.encode(combinedData + hmacDigest);

    // Store the combined data
    await storage.write(key: name, value: combined);
  } catch (exception, stackTrace) {
    final hint = Hint.withMap(
        {'message': 'Error storing prefs', 'name': name, 'token': token});
    Sentry.captureException(exception, stackTrace: stackTrace,
        withScope: (scope) {
      scope.setContexts('Encryption Context', hint);
    });
  }
}

Future<String?> getPrefs(String name) async {
  try {
    // Retrieve the combined data
    final combined = await storage.read(key: name);
    if (combined == null) {
      return null;
    }

    final data = base64.decode(combined);

    // Extract IV, encrypted data, and HMAC
    final iv = IV(data.sublist(0, 16));
    final encryptedData = data.sublist(16, data.length - 32);
    final hmacDigest = data.sublist(data.length - 32);
    // Combine IV and encrypted data for HMAC
    final combinedData = iv.bytes + encryptedData;

    // Verify HMAC
    final hmacKey = base64.decode(dotenv.env['HMAC_KEY']!); // Key for HMAC
    final hmac = Hmac(sha256, hmacKey);
    final newHmacDigest =
        hmac.convert(combinedData).bytes; // Use IV + encryptedData

    if (!ListEquality().equals(hmacDigest, newHmacDigest)) {
      throw Exception('HMAC verification failed');
    }

    // Decrypt the access token
    final encryptionKey = Key.fromBase64(
        dotenv.env['ENCRYPTION_KEY']!); // 32 bytes key for AES-256
    final encrypter = Encrypter(AES(encryptionKey, mode: AESMode.cbc));
    final encrypted = Encrypted(encryptedData);

    final decrypted = encrypter.decrypt(encrypted, iv: iv);

    return decrypted;
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
  if (endTime == null) return AppLocalizations.of(context)!.unknown;

  final localEndTime = endTime.toLocal();
  final now = DateTime.now();
  final difference = now.difference(localEndTime);

  final l10n = AppLocalizations.of(context)!;

  if (difference.inMinutes < 1) {
    return l10n.endedJustNow; // "Ended just now"
  } else if (difference.inMinutes < 60) {
    return l10n.endedMinutesAgo(difference.inMinutes); // "Ended X minutes ago"
  } else if (difference.inHours < 24) {
    return l10n.endedHoursAgo(difference.inHours); // "Ended X hours ago"
  } else {
    return l10n.endedDaysAgo(difference.inDays); // "Ended X days ago"
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

  if ((nowUtc.day >= 22 && nowUtc.hour >= 8) &&
      (nowUtc.day <= 28 && nowUtc.hour <= 8)) {
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
