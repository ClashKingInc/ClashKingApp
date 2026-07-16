import 'dart:convert';

import 'package:clashkingapp/features/auth/data/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../../../helpers/fake_services.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  // ---------------------------------------------------------------------------
  // Helper factories
  // ---------------------------------------------------------------------------

  Map<String, dynamic> userJson({String id = 'u1', String name = 'TestUser'}) =>
      <String, dynamic>{
        'user_id': id,
        'discord_username': name,
        'avatar_url': '',
        'auth_methods': <String>['discord'],
      };

  // ---------------------------------------------------------------------------
  // initial state
  // ---------------------------------------------------------------------------

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
  });

  // ---------------------------------------------------------------------------
  // initializeAuth
  // ---------------------------------------------------------------------------

  group('AuthService — initializeAuth (no token)', () {
    test('stays not authenticated when no token stored', () async {
      final service = AuthService(
        tokenService: FakeTokenService(fakeToken: null),
      );
      await service.initializeAuth();
      expect(service.isAuthenticated, isFalse);
    });

    test('accessToken remains null when no token stored', () async {
      final service = AuthService(
        tokenService: FakeTokenService(fakeToken: null),
      );
      await service.initializeAuth();
      expect(service.accessToken, isNull);
    });

    test('notifies listeners even when no token stored', () async {
      final service = AuthService(
        tokenService: FakeTokenService(fakeToken: null),
      );
      var notified = false;
      service.addListener(() => notified = true);
      await service.initializeAuth();
      expect(notified, isTrue);
    });
  });

  group('AuthService — initializeAuth (valid token, API success)', () {
    late FakeApiService fakeApi;
    late FakeTokenService fakeToken;

    setUp(() {
      fakeApi = FakeApiService();
      fakeApi.getStubs['/auth/me'] = http.Response(jsonEncode(userJson()), 200);
      fakeToken = FakeTokenService(fakeToken: 'header.payload.sig');
    });

    test('sets isAuthenticated = true', () async {
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await service.initializeAuth();
      expect(service.isAuthenticated, isTrue);
    });

    test('populates currentUser.username', () async {
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await service.initializeAuth();
      expect(service.currentUser?.username, 'TestUser');
    });

    test('populates accessToken', () async {
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await service.initializeAuth();
      expect(service.accessToken, isNotNull);
    });

    test('notifies listeners', () async {
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      var notified = false;
      service.addListener(() => notified = true);
      await service.initializeAuth();
      expect(notified, isTrue);
    });
  });

  group('AuthService — initializeAuth (valid token, auth error)', () {
    test('sets isAuthenticated = false on 401', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/auth/me'] = http.Response('Unauthorized', 401);
      final fakeToken = FakeTokenService(fakeToken: 'header.payload.sig');
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await expectLater(() => service.initializeAuth(), throwsA(anything));
      expect(service.isAuthenticated, isFalse);
    });

    test('calls clearTokens on auth error', () async {
      final fakeApi = FakeApiService();
      fakeApi.getStubs['/auth/me'] = http.Response('Unauthorized', 401);
      final fakeToken = FakeTokenService(fakeToken: 'header.payload.sig');
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await expectLater(() => service.initializeAuth(), throwsA(anything));
      expect(fakeToken.clearCalled, isTrue);
    });
  });

  group('AuthService — initializeAuth (network error)', () {
    test('keeps isAuthenticated = true on SocketException', () async {
      final fakeApi = NetworkErrorApiService();
      final fakeToken = FakeTokenService(fakeToken: 'header.payload.sig');
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await expectLater(() => service.initializeAuth(), throwsA(anything));
      expect(service.isAuthenticated, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // signInWithEmail
  // ---------------------------------------------------------------------------

  group('AuthService — signInWithEmail (success)', () {
    late FakeApiService fakeApi;
    late FakeTokenService fakeToken;

    setUp(() {
      fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/email'] = http.Response(
        jsonEncode({
          'access_token': 'acc123',
          'refresh_token': 'ref123',
          'user': userJson(),
        }),
        200,
      );
      fakeToken = FakeTokenService(fakeToken: null);
    });

    test('sets isAuthenticated = true', () async {
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await service.signInWithEmail('a@b.com', 'pass');
      expect(service.isAuthenticated, isTrue);
    });

    test('sets accessToken', () async {
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await service.signInWithEmail('a@b.com', 'pass');
      expect(service.accessToken, 'acc123');
    });

    test('populates currentUser', () async {
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await service.signInWithEmail('a@b.com', 'pass');
      expect(service.currentUser?.username, 'TestUser');
    });

    test('calls saveTokens', () async {
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await service.signInWithEmail('a@b.com', 'pass');
      expect(fakeToken.saveTokensCalled, isTrue);
    });

    test('notifies listeners', () async {
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      var notified = false;
      service.addListener(() => notified = true);
      await service.signInWithEmail('a@b.com', 'pass');
      expect(notified, isTrue);
    });
  });

  group('AuthService — signInWithEmail (failure)', () {
    test('throws Exception on API error', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/email'] = http.Response('Unauthorized', 401);
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      await expectLater(
        () => service.signInWithEmail('a@b.com', 'wrong'),
        throwsA(isA<Exception>()),
      );
    });

    test('isAuthenticated stays false on failure', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/email'] = http.Response('Unauthorized', 401);
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      try {
        await service.signInWithEmail('a@b.com', 'wrong');
      } catch (_) {}
      expect(service.isAuthenticated, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // registerWithEmail
  // ---------------------------------------------------------------------------

  group('AuthService — registerWithEmail', () {
    test('does not set isAuthenticated', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/register'] = http.Response(
        jsonEncode({'verification_sent': true}),
        200,
      );
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      await service.registerWithEmail('a@b.com', 'pass', 'user');
      expect(service.isAuthenticated, isFalse);
    });

    test('returns response map', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/register'] = http.Response(
        jsonEncode({'verification_sent': true}),
        200,
      );
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      final result = await service.registerWithEmail('a@b.com', 'pass', 'u');
      expect(result['verification_sent'], isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // signOut
  // ---------------------------------------------------------------------------

  group('AuthService — signOut', () {
    test('isAuthenticated is false after signOut', () async {
      final service = AuthService(tokenService: FakeTokenService());
      await service.signOut();
      expect(service.isAuthenticated, isFalse);
    });

    test('accessToken is null after signOut', () async {
      final service = AuthService(tokenService: FakeTokenService());
      await service.signOut();
      expect(service.accessToken, isNull);
    });

    test('currentUser is null after signOut', () async {
      final service = AuthService(tokenService: FakeTokenService());
      await service.signOut();
      expect(service.currentUser, isNull);
    });

    test('notifies listeners on signOut', () async {
      final service = AuthService(tokenService: FakeTokenService());
      var notified = false;
      service.addListener(() => notified = true);
      await service.signOut();
      expect(notified, isTrue);
    });

    test('calls clearTokens on signOut', () async {
      final fakeToken = FakeTokenService();
      final service = AuthService(tokenService: fakeToken);
      await service.signOut();
      expect(fakeToken.clearCalled, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // logoutAndClearAllData
  // ---------------------------------------------------------------------------

  group('AuthService — logoutAndClearAllData', () {
    test('resets isAuthenticated', () async {
      final service = AuthService(tokenService: FakeTokenService());
      await service.logoutAndClearAllData();
      expect(service.isAuthenticated, isFalse);
    });

    test('resets accessToken', () async {
      final service = AuthService(tokenService: FakeTokenService());
      await service.logoutAndClearAllData();
      expect(service.accessToken, isNull);
    });

    test('resets currentUser', () async {
      final service = AuthService(tokenService: FakeTokenService());
      await service.logoutAndClearAllData();
      expect(service.currentUser, isNull);
    });

    test('notifies listeners', () async {
      final service = AuthService(tokenService: FakeTokenService());
      var notified = false;
      service.addListener(() => notified = true);
      await service.logoutAndClearAllData();
      expect(notified, isTrue);
    });

    test('calls clearTokens', () async {
      final fakeToken = FakeTokenService();
      final service = AuthService(tokenService: fakeToken);
      await service.logoutAndClearAllData();
      expect(fakeToken.clearCalled, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // verifyEmailWithCode
  // ---------------------------------------------------------------------------

  group('AuthService — verifyEmailWithCode (success)', () {
    test('sets isAuthenticated = true', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/verify-email-code'] = http.Response(
        jsonEncode({
          'access_token': 'acc',
          'refresh_token': 'ref',
          'user': userJson(),
        }),
        200,
      );
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      await service.verifyEmailWithCode('a@b.com', '123456');
      expect(service.isAuthenticated, isTrue);
    });

    test('sets accessToken', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/verify-email-code'] = http.Response(
        jsonEncode({
          'access_token': 'acc99',
          'refresh_token': 'ref99',
          'user': userJson(),
        }),
        200,
      );
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      await service.verifyEmailWithCode('a@b.com', '123456');
      expect(service.accessToken, 'acc99');
    });

    test('rethrows on API error', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/verify-email-code'] = http.Response(
        'invalid code',
        400,
      );
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      await expectLater(
        () => service.verifyEmailWithCode('a@b.com', 'bad'),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // resendVerificationEmail
  // ---------------------------------------------------------------------------

  group('AuthService — resendVerificationEmail', () {
    test('returns response on success', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/resend-verification'] = http.Response(
        jsonEncode({'sent': true}),
        200,
      );
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      final result = await service.resendVerificationEmail('a@b.com');
      expect(result['sent'], isTrue);
    });

    test('rethrows on API error', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/resend-verification'] = http.Response(
        'error',
        429,
      );
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      await expectLater(
        () => service.resendVerificationEmail('a@b.com'),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // forgotPassword
  // ---------------------------------------------------------------------------

  group('AuthService — forgotPassword', () {
    test('returns response on success', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/forgot-password'] = http.Response(
        jsonEncode({'reset_sent': true}),
        200,
      );
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      final result = await service.forgotPassword('a@b.com');
      expect(result['reset_sent'], isTrue);
    });

    test('rethrows on API error', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/forgot-password'] = http.Response(
        'not found',
        404,
      );
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      await expectLater(
        () => service.forgotPassword('nobody@b.com'),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // resetPassword
  // ---------------------------------------------------------------------------

  group('AuthService — resetPassword (success)', () {
    test('sets isAuthenticated = true', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/reset-password'] = http.Response(
        jsonEncode({
          'access_token': 'acc_reset',
          'refresh_token': 'ref_reset',
          'user': userJson(),
        }),
        200,
      );
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      await service.resetPassword('a@b.com', 'CODE123', 'newpass');
      expect(service.isAuthenticated, isTrue);
    });

    test('sets accessToken', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/reset-password'] = http.Response(
        jsonEncode({
          'access_token': 'acc_reset',
          'refresh_token': 'ref_reset',
          'user': userJson(),
        }),
        200,
      );
      final fakeToken = FakeTokenService(fakeToken: null);
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await service.resetPassword('a@b.com', 'CODE123', 'newpass');
      expect(service.accessToken, 'acc_reset');
      expect(fakeToken.saveTokensCalled, isTrue);
    });

    test('rethrows on error', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/reset-password'] = http.Response(
        'bad code',
        400,
      );
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      await expectLater(
        () => service.resetPassword('a@b.com', 'BADCODE', 'newpass'),
        throwsA(anything),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // linkEmailAccount
  // ---------------------------------------------------------------------------

  group('AuthService — linkEmailAccount', () {
    test('calls initializeAuth after linking — sets isAuthenticated', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/link-email'] = http.Response('{}', 200);
      fakeApi.getStubs['/auth/me'] = http.Response(jsonEncode(userJson()), 200);
      final fakeToken = FakeTokenService(fakeToken: 'token123');
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await service.linkEmailAccount('a@b.com', 'pass', 'user');
      expect(service.isAuthenticated, isTrue);
    });

    test('throws localized Exception on API error', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/link-email'] = http.Response('conflict', 409);
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      await expectLater(
        () => service.linkEmailAccount('a@b.com', 'pass', 'user'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // linkDiscordAccount
  // ---------------------------------------------------------------------------

  group('AuthService — linkDiscordAccount', () {
    test('calls initializeAuth after linking — sets isAuthenticated', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/link-discord'] = http.Response('{}', 200);
      fakeApi.getStubs['/auth/me'] = http.Response(jsonEncode(userJson()), 200);
      final fakeToken = FakeTokenService(fakeToken: 'token123');
      final service = AuthService(apiService: fakeApi, tokenService: fakeToken);
      await service.linkDiscordAccount('discord_token', 'refresh', 3600);
      expect(service.isAuthenticated, isTrue);
    });

    test('throws localized Exception on API error', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/link-discord'] = http.Response('forbidden', 403);
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
      );
      await expectLater(
        () => service.linkDiscordAccount('bad_token', null, null),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // linkDiscordWithCode (OAuth-code flow)
  // ---------------------------------------------------------------------------

  group('AuthService — linkDiscordWithCode', () {
    test('links and re-authenticates on success', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/link-discord-code'] = http.Response('{}', 200);
      // linkDiscordWithCode calls initializeAuth(), which fetches /auth/me.
      fakeApi.getStubs['/auth/me'] = http.Response(
        jsonEncode(userJson()),
        200,
      );
      final fakeToken = FakeTokenService(fakeToken: 'header.payload.sig');
      final service = AuthService(
        apiService: fakeApi,
        tokenService: fakeToken,
        discordAuthCodeProvider: () async =>
            {'code': 'auth_code', 'code_verifier': 'verifier'},
      );

      await service.linkDiscordWithCode();
      expect(service.isAuthenticated, isTrue);
    });

    test('throws when the OAuth flow is cancelled (null code)', () async {
      final service = AuthService(
        apiService: FakeApiService(),
        tokenService: FakeTokenService(fakeToken: null),
        discordAuthCodeProvider: () async => null,
      );

      await expectLater(
        () => service.linkDiscordWithCode(),
        throwsA(isA<Exception>()),
      );
    });

    test('throws localized Exception on API error', () async {
      final fakeApi = FakeApiService();
      fakeApi.postStubs['/auth/link-discord-code'] =
          http.Response('forbidden', 403);
      final service = AuthService(
        apiService: fakeApi,
        tokenService: FakeTokenService(fakeToken: null),
        discordAuthCodeProvider: () async =>
            {'code': 'auth_code', 'code_verifier': 'verifier'},
      );

      await expectLater(
        () => service.linkDiscordWithCode(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
