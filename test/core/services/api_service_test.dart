import 'dart:async';
import 'dart:io';

import 'package:clashkingapp/core/config/api_config.dart';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/fake_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService — static helpers', () {
    test('decodeResponseBody allows malformed utf8', () {
      final response = http.Response.bytes([0xC3, 0x28], 200);
      expect(ApiService.decodeResponseBody(response), isNotEmpty);
    });

    test('cocAssetsProxyUrl rewrites clashofclans.com URLs', () {
      const input = 'https://api-assets.clashofclans.com/leagues/256/image.png';
      final result = ApiService.cocAssetsProxyUrl(input);
      expect(result, startsWith('https://assets-proxy.clashk.ing/'));
      expect(result, isNot(contains('clashofclans.com')));
    });

    test('cocAssetsProxyUrl leaves unrelated URLs unchanged', () {
      const input = 'https://example.com/image.png';
      expect(ApiService.cocAssetsProxyUrl(input), input);
    });
  });

  group('ApiService — getErrorMessage', () {
    test('SocketException returns network message', () {
      expect(
        ApiService.getErrorMessage(const SocketException('offline')),
        'Network connection error.',
      );
    });

    test('TimeoutException returns timeout message', () {
      expect(
        ApiService.getErrorMessage(TimeoutException('slow')),
        'Request timeout.',
      );
    });

    test('FormatException returns format message', () {
      expect(
        ApiService.getErrorMessage(FormatException('bad payload')),
        'Invalid response format.',
      );
    });

    test('BadRequestException returns its message', () {
      expect(
        ApiService.getErrorMessage(BadRequestException('bad input')),
        'bad input',
      );
    });

    test('UnauthorizedException returns its message', () {
      expect(
        ApiService.getErrorMessage(UnauthorizedException('no auth')),
        'no auth',
      );
    });

    test('ForbiddenException returns its message', () {
      expect(
        ApiService.getErrorMessage(ForbiddenException('no access')),
        'no access',
      );
    });

    test('NotFoundException returns its message', () {
      expect(
        ApiService.getErrorMessage(NotFoundException('missing')),
        'missing',
      );
    });

    test('RateLimitException returns its message', () {
      expect(
        ApiService.getErrorMessage(RateLimitException('too many')),
        'too many',
      );
    });

    test('ServerException returns its message', () {
      expect(
        ApiService.getErrorMessage(ServerException('server down')),
        'server down',
      );
    });

    test('EmailVerificationRequiredException returns its message', () {
      expect(
        ApiService.getErrorMessage(
          EmailVerificationRequiredException('verify email'),
        ),
        'verify email',
      );
    });

    test('generic ApiException returns its message', () {
      expect(ApiService.getErrorMessage(ApiException('generic')), 'generic');
    });

    test('unknown exception type falls back to toString', () {
      expect(
        ApiService.getErrorMessage(Exception('weird error')),
        contains('weird error'),
      );
    });
  });

  group(
    'ApiService — _handleResponse and _expectMapResponse via FakeApiService',
    () {
      late FakeApiService fakeApi;

      setUp(() => fakeApi = FakeApiService());

      test('200 with valid JSON map returns parsed map', () async {
        fakeApi.getStubs['/test'] = http.Response('{"key":"value"}', 200);
        final result = await fakeApi.get('/test');
        expect(result, {'key': 'value'});
      });

      test('200 with non-map JSON throws FormatException', () async {
        fakeApi.getStubs['/test'] = http.Response('[1,2,3]', 200);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<FormatException>()),
        );
      });

      test('200 with invalid JSON throws FormatException', () async {
        fakeApi.getStubs['/test'] = http.Response('not-json', 200);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<FormatException>()),
        );
      });

      test('201 with valid JSON returns parsed map', () async {
        fakeApi.postStubs['/test'] = http.Response('{"created":true}', 201);
        final result = await fakeApi.post('/test', {});
        expect(result['created'], isTrue);
      });

      test('400 throws BadRequestException', () async {
        fakeApi.getStubs['/test'] = http.Response('error', 400);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<BadRequestException>()),
        );
      });

      test('400 with detail field extracts specific message', () async {
        fakeApi.getStubs['/test'] = http.Response(
          '{"detail":"custom error"}',
          400,
        );
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(
            predicate<BadRequestException>((e) => e.message == 'custom error'),
          ),
        );
      });

      test('401 throws UnauthorizedException', () async {
        fakeApi.getStubs['/test'] = http.Response('unauth', 401);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<UnauthorizedException>()),
        );
      });

      test('403 throws ForbiddenException', () async {
        fakeApi.getStubs['/test'] = http.Response('forbidden', 403);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<ForbiddenException>()),
        );
      });

      test('404 throws NotFoundException', () async {
        fakeApi.getStubs['/test'] = http.Response('not found', 404);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('409 throws EmailVerificationRequiredException', () async {
        fakeApi.getStubs['/test'] = http.Response('conflict', 409);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<EmailVerificationRequiredException>()),
        );
      });

      test('429 throws RateLimitException', () async {
        fakeApi.getStubs['/test'] = http.Response('too many', 429);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<RateLimitException>()),
        );
      });

      test('500 throws ServerException', () async {
        fakeApi.getStubs['/test'] = http.Response('server error', 500);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<ServerException>()),
        );
      });

      test('502 throws ServerException', () async {
        fakeApi.getStubs['/test'] = http.Response('bad gateway', 502);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<ServerException>()),
        );
      });

      test('503 throws ServerException', () async {
        fakeApi.getStubs['/test'] = http.Response('maintenance', 503);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<ServerException>()),
        );
      });

      test('504 throws ServerException', () async {
        fakeApi.getStubs['/test'] = http.Response('gateway timeout', 504);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<ServerException>()),
        );
      });

      test('418 throws generic ApiException for unknown status', () async {
        fakeApi.getStubs['/test'] = http.Response('teapot', 418);
        await expectLater(
          () => fakeApi.get('/test'),
          throwsA(isA<ApiException>()),
        );
      });
    },
  );

  group(
    'ApiService — _requestResponse via MockClient (requiresAuth: false)',
    () {
      test('GET 200 returns response', () async {
        final client = MockClient(
          (_) async => http.Response('{"ok":true}', 200),
        );
        final service = ApiService(client: client);
        final response = await service.getResponse(
          '/test',
          requiresAuth: false,
        );
        expect(response.statusCode, 200);
      });

      test('local authenticated request can omit the access token', () async {
        http.Request? captured;
        final client = MockClient((request) async {
          captured = request;
          return http.Response('{"ok":true}', 200);
        });
        final service = ApiService(
          client: client,
          tokenService: FakeTokenService(fakeToken: null),
          environment: ApiEnvironment.local,
        );

        final response = await service.getResponse('/test', requiresAuth: true);

        expect(response.statusCode, 200);
        expect(captured?.headers.containsKey('Authorization'), isFalse);
      });

      test('POST with Map body encodes JSON', () async {
        http.Request? captured;
        final client = MockClient((req) async {
          captured = req;
          return http.Response('{"ok":true}', 200);
        });
        final service = ApiService(client: client);
        await service.postResponse(
          '/test',
          body: {'key': 'value'},
          requiresAuth: false,
        );
        expect(captured?.body, '{"key":"value"}');
        expect(captured?.headers['Content-Type'], contains('application/json'));
      });

      test('POST with String body sends it as-is', () async {
        http.Request? captured;
        final client = MockClient((req) async {
          captured = req;
          return http.Response('{}', 200);
        });
        final service = ApiService(client: client);
        await service.postResponse('/test', body: 'raw', requiresAuth: false);
        expect(captured?.body, 'raw');
      });

      test('POST with null body returns response', () async {
        final client = MockClient((_) async => http.Response('{}', 200));
        final service = ApiService(client: client);
        final response = await service.postResponse(
          '/test',
          body: null,
          requiresAuth: false,
        );
        expect(response.statusCode, 200);
      });

      test('PUT 200 returns response', () async {
        final client = MockClient((_) async => http.Response('{}', 200));
        final service = ApiService(client: client);
        final response = await service.putResponse(
          '/test',
          body: {'x': 1},
          requiresAuth: false,
        );
        expect(response.statusCode, 200);
      });

      test('PATCH with Map body uses PATCH and encodes JSON', () async {
        http.Request? captured;
        final client = MockClient((request) async {
          captured = request;
          return http.Response('{}', 200);
        });
        final service = ApiService(client: client);

        await service.patchResponse(
          '/test',
          body: {'hidden': true},
          requiresAuth: false,
        );

        expect(captured?.method, 'PATCH');
        expect(captured?.body, '{"hidden":true}');
      });

      test('DELETE 200 returns response', () async {
        final client = MockClient((_) async => http.Response('{}', 200));
        final service = ApiService(client: client);
        final response = await service.deleteResponse(
          '/test',
          requiresAuth: false,
        );
        expect(response.statusCode, 200);
      });

      test('SocketException propagates after _handleError logging', () async {
        final client = MockClient(
          (_) async => throw const SocketException('down'),
        );
        final service = ApiService(client: client);
        await expectLater(
          () => service.getResponse('/test', requiresAuth: false),
          throwsA(isA<SocketException>()),
        );
      });

      test('TimeoutException propagates after _handleError logging', () async {
        final client = MockClient((_) async => throw TimeoutException('slow'));
        final service = ApiService(client: client);
        await expectLater(
          () => service.getResponse('/test', requiresAuth: false),
          throwsA(isA<TimeoutException>()),
        );
      });
    },
  );
}
