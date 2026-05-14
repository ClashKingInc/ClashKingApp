import 'package:clashkingapp/core/services/token_service.dart';
import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

// Fake that overrides every platform-channel method so tests run without
// FlutterSecureStorage / SharedPreferences being available.
class _FakeTokenService extends TokenService {
  final String? fakeToken;
  _FakeTokenService({this.fakeToken});

  @override
  Future<String?> getAccessToken() async => fakeToken;

  @override
  Future<void> clearTokens() async {}

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {}

  @override
  Future<String> getDeviceId() async => 'test-device-id';

  @override
  Future<String> getDeviceName() async => 'test-device';
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AuthService — initial state', () {
    test('starts not authenticated', () {
      final service = AuthService();
      expect(service.isAuthenticated, isFalse);
    });

    test('starts with null accessToken', () {
      final service = AuthService();
      expect(service.accessToken, isNull);
    });

    test('starts with null currentUser', () {
      final service = AuthService();
      expect(service.currentUser, isNull);
    });

    test('starts with null cocAccounts', () {
      final service = AuthService();
      expect(service.cocAccounts, isNull);
    });
  });

  group('AuthService — initializeAuth', () {
    test('stays not authenticated when no token stored', () async {
      final service =
          AuthService(tokenService: _FakeTokenService(fakeToken: null));
      await service.initializeAuth();
      expect(service.isAuthenticated, isFalse);
    });

    test('accessToken remains null when no token stored', () async {
      final service =
          AuthService(tokenService: _FakeTokenService(fakeToken: null));
      await service.initializeAuth();
      expect(service.accessToken, isNull);
    });

    test('notifies listeners even when no token stored', () async {
      final service =
          AuthService(tokenService: _FakeTokenService(fakeToken: null));
      var notified = false;
      service.addListener(() => notified = true);
      await service.initializeAuth();
      expect(notified, isTrue);
    });
  });

  group('AuthService — signOut', () {
    test('isAuthenticated is false after signOut', () async {
      final service = AuthService(tokenService: _FakeTokenService());
      await service.signOut();
      expect(service.isAuthenticated, isFalse);
    });

    test('accessToken is null after signOut', () async {
      final service = AuthService(tokenService: _FakeTokenService());
      await service.signOut();
      expect(service.accessToken, isNull);
    });

    test('currentUser is null after signOut', () async {
      final service = AuthService(tokenService: _FakeTokenService());
      await service.signOut();
      expect(service.currentUser, isNull);
    });

    test('cocAccounts is null after signOut', () async {
      final service = AuthService(tokenService: _FakeTokenService());
      await service.signOut();
      expect(service.cocAccounts, isNull);
    });

    test('notifies listeners on signOut', () async {
      final service = AuthService(tokenService: _FakeTokenService());
      var notified = false;
      service.addListener(() => notified = true);
      await service.signOut();
      expect(notified, isTrue);
    });
  });

  group('AuthService — logoutAndClearAllData', () {
    test('resets isAuthenticated', () async {
      final service = AuthService(tokenService: _FakeTokenService());
      await service.logoutAndClearAllData();
      expect(service.isAuthenticated, isFalse);
    });

    test('resets accessToken', () async {
      final service = AuthService(tokenService: _FakeTokenService());
      await service.logoutAndClearAllData();
      expect(service.accessToken, isNull);
    });

    test('resets currentUser', () async {
      final service = AuthService(tokenService: _FakeTokenService());
      await service.logoutAndClearAllData();
      expect(service.currentUser, isNull);
    });

    test('resets cocAccounts', () async {
      final service = AuthService(tokenService: _FakeTokenService());
      await service.logoutAndClearAllData();
      expect(service.cocAccounts, isNull);
    });

    test('notifies listeners', () async {
      final service = AuthService(tokenService: _FakeTokenService());
      var notified = false;
      service.addListener(() => notified = true);
      await service.logoutAndClearAllData();
      expect(notified, isTrue);
    });
  });
}
