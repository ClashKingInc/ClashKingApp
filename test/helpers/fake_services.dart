import 'dart:io';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:http/http.dart' as http;

/// A testable [ApiService] that bypasses HTTP and [FlutterSecureStorage]
/// entirely by returning preset [http.Response] objects for each endpoint.
///
/// Only the four low-level `*Response` methods are overridden so that the
/// inherited `get()` / `post()` wrappers still run `_handleResponse`, keeping
/// status-code handling logic under coverage.
class FakeApiService extends ApiService {
  final Map<String, http.Response> getStubs = {};
  final Map<String, http.Response> postStubs = {};
  final Map<String, http.Response> putStubs = {};
  final Map<String, http.Response> deleteStubs = {};

  /// If set, the next call to the corresponding method for [endpoint] will
  /// throw this exception instead of returning a stubbed response.
  final Map<String, Exception> throwOnGet = {};
  final Map<String, Exception> throwOnPost = {};
  final Map<String, Exception> throwOnDelete = {};

  @override
  Future<http.Response> getResponse(
    String endpoint, {
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (throwOnGet.containsKey(endpoint)) throw throwOnGet[endpoint]!;
    return getStubs[endpoint] ?? http.Response('{}', 200);
  }

  @override
  Future<http.Response> postResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (throwOnPost.containsKey(endpoint)) throw throwOnPost[endpoint]!;
    return postStubs[endpoint] ?? http.Response('{}', 200);
  }

  @override
  Future<http.Response> putResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    return putStubs[endpoint] ?? http.Response('{}', 200);
  }

  @override
  Future<http.Response> deleteResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (throwOnDelete.containsKey(endpoint)) throw throwOnDelete[endpoint]!;
    return deleteStubs[endpoint] ?? http.Response('{}', 200);
  }
}

/// A testable [TokenService] that avoids [FlutterSecureStorage] by returning
/// preset values and recording whether [clearTokens]/[saveTokens] were called.
class FakeTokenService extends TokenService {
  final String? fakeToken;
  bool clearCalled = false;
  bool saveTokensCalled = false;

  FakeTokenService({this.fakeToken});

  @override
  Future<String?> getAccessToken() async => fakeToken;

  @override
  Future<void> clearTokens() async {
    clearCalled = true;
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    saveTokensCalled = true;
  }

  @override
  Future<String> getDeviceId() async => 'test-device-id';

  @override
  Future<String> getDeviceName() async => 'test-device';
}

/// Simulates a network failure by throwing [SocketException] for any request.
class NetworkErrorApiService extends FakeApiService {
  @override
  Future<http.Response> getResponse(
    String endpoint, {
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    throw const SocketException('Network unreachable');
  }

  @override
  Future<http.Response> postResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    throw const SocketException('Network unreachable');
  }
}
