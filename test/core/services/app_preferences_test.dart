import 'package:clashkingapp/core/services/app_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
  });

  test('migrates non-secret values without moving tokens', () async {
    FlutterSecureStorage.setMockInitialValues({
      'selectedTag': '#PLAYER',
      'player_#PLAYER_clan_tag': '#CLAN',
      'access_token': 'secret-token',
    });
    final preferences = AppPreferences();

    expect(await preferences.getString('selectedTag'), '#PLAYER');
    expect(await preferences.getString('player_#PLAYER_clan_tag'), '#CLAN');

    const secureStorage = FlutterSecureStorage();
    expect(await secureStorage.read(key: 'selectedTag'), isNull);
    expect(await secureStorage.read(key: 'access_token'), 'secret-token');
  });

  test('keeps an existing SharedPreferences value during migration', () async {
    FlutterSecureStorage.setMockInitialValues({'themeMode': 'dark'});
    SharedPreferences.setMockInitialValues({'themeMode': 'light'});
    final preferences = AppPreferences();

    expect(await preferences.getString('themeMode'), 'light');
    expect(await const FlutterSecureStorage().read(key: 'themeMode'), isNull);
  });

  test('clear preserves secure device identity and tokens', () async {
    FlutterSecureStorage.setMockInitialValues({
      'selectedTag': '#PLAYER',
      'access_token': 'secret-token',
      'device_id_fallback': 'stable-device',
    });
    final preferences = AppPreferences();
    await preferences.getString('selectedTag');

    await preferences.clear();

    const secureStorage = FlutterSecureStorage();
    expect(await secureStorage.read(key: 'access_token'), 'secret-token');
    expect(
      await secureStorage.read(key: 'device_id_fallback'),
      'stable-device',
    );
  });
}
