import 'dart:convert';
import 'dart:io';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/core/services/token_service.dart';
import 'package:http/http.dart' as http;

/// A testable [ApiService] that bypasses HTTP and [FlutterSecureStorage]
/// entirely by returning preset [http.Response] objects for each endpoint.
///
/// Only the low-level `*Response` methods are overridden so that the
/// inherited `get()` / `post()` wrappers still run `_handleResponse`, keeping
/// status-code handling logic under coverage.
class FakeApiService extends ApiService {
  final Map<String, http.Response> getStubs = {};
  final Map<String, http.Response> postStubs = {};
  final Map<String, http.Response> queryStubs = {};
  final Map<String, http.Response> putStubs = {};
  final Map<String, http.Response> patchStubs = {};
  final Map<String, http.Response> deleteStubs = {};
  final Map<String, Object?> lastPostBodies = {};
  final Map<String, Object?> lastQueryBodies = {};
  final Map<String, Object?> lastPutBodies = {};
  final Map<String, Object?> lastPatchBodies = {};
  final Map<String, Object?> lastDeleteBodies = {};
  final Map<String, Map<String, String>?> lastGetHeaders = {};
  final Map<String, int> getCallCounts = {};

  /// If set, the next call to the corresponding method for [endpoint] will
  /// throw this exception instead of returning a stubbed response.
  final Map<String, Exception> throwOnGet = {};
  final Map<String, Exception> throwOnPost = {};
  final Map<String, Exception> throwOnQuery = {};
  final Map<String, Exception> throwOnPatch = {};
  final Map<String, Exception> throwOnDelete = {};

  @override
  Future<http.Response> getResponse(
    String endpoint, {
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? extraHeaders,
  }) async {
    lastGetHeaders[endpoint] = extraHeaders;
    getCallCounts.update(endpoint, (count) => count + 1, ifAbsent: () => 1);
    if (throwOnGet.containsKey(endpoint)) throw throwOnGet[endpoint]!;
    if (getStubs.containsKey(endpoint)) return getStubs[endpoint]!;
    return _derivedProxyGet(endpoint) ??
        getStubs[''] ??
        http.Response('{}', 200);
  }

  @override
  Future<http.Response> postResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? extraHeaders,
  }) async {
    lastPostBodies[endpoint] = body;
    if (throwOnPost.containsKey(endpoint)) throw throwOnPost[endpoint]!;
    return postStubs[endpoint] ?? http.Response('{}', 200);
  }

  @override
  Future<http.Response> queryResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? extraHeaders,
  }) async {
    lastQueryBodies[endpoint] = body;
    if (throwOnQuery.containsKey(endpoint)) throw throwOnQuery[endpoint]!;
    return queryStubs[endpoint] ?? http.Response('{"items":[]}', 200);
  }

  @override
  Future<http.Response> putResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? extraHeaders,
  }) async {
    lastPutBodies[endpoint] = body;
    return putStubs[endpoint] ?? http.Response('{}', 200);
  }

  @override
  Future<http.Response> patchResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? extraHeaders,
  }) async {
    lastPatchBodies[endpoint] = body;
    if (throwOnPatch.containsKey(endpoint)) throw throwOnPatch[endpoint]!;
    return patchStubs[endpoint] ?? http.Response('{}', 200);
  }

  @override
  Future<http.Response> deleteResponse(
    String endpoint, {
    Object? body,
    bool requiresAuth = false,
    String? url,
    Duration timeout = const Duration(seconds: 15),
    Map<String, String>? extraHeaders,
  }) async {
    lastDeleteBodies[endpoint] = body;
    if (throwOnDelete.containsKey(endpoint)) throw throwOnDelete[endpoint]!;
    return deleteStubs[endpoint] ?? http.Response('{}', 200);
  }

  http.Response? _derivedProxyGet(String endpoint) {
    if (endpoint.startsWith('/players/')) {
      return _itemFromBatchStub(
        endpoint,
        batchEndpoint: '/players',
        collectionKey: 'items',
      );
    }

    if (endpoint.startsWith('/clans/')) {
      if (endpoint.contains('/capitalraidseasons') ||
          endpoint.contains('/warlog')) {
        return null;
      }

      final oldDetailsStub =
          getStubs['/clan/${_encodedTagFromProxyEndpoint(endpoint)}/details'];
      if (oldDetailsStub != null) {
        return oldDetailsStub;
      }

      return _itemFromBatchStub(
        endpoint,
        batchEndpoint: '/clans/details',
        collectionKey: 'items',
      );
    }

    return null;
  }

  http.Response? _itemFromBatchStub(
    String endpoint, {
    required String batchEndpoint,
    required String collectionKey,
  }) {
    final batchResponse = postStubs[batchEndpoint];
    if (batchResponse == null) return null;
    if (batchResponse.statusCode != 200) {
      return http.Response(batchResponse.body, batchResponse.statusCode);
    }

    final tag = _tagFromProxyEndpoint(endpoint);
    final decoded = jsonDecode(batchResponse.body);
    if (decoded is! Map<String, dynamic>) return http.Response('{}', 200);
    final items = decoded[collectionKey];
    if (items is! List) return http.Response('{}', 200);
    final item = items.whereType<Map<String, dynamic>>().firstWhere(
      (item) => item['tag'] == tag,
      orElse: () => <String, dynamic>{},
    );
    return http.Response(jsonEncode(item), 200);
  }

  String _tagFromProxyEndpoint(String endpoint) {
    final parts = endpoint.split('/');
    if (parts.length < 3) return '';
    return Uri.decodeComponent(parts[2]);
  }

  String _encodedTagFromProxyEndpoint(String endpoint) {
    final parts = endpoint.split('/');
    if (parts.length < 3) return '';
    return parts[2];
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
    Map<String, String>? extraHeaders,
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
    Map<String, String>? extraHeaders,
  }) async {
    throw const SocketException('Network unreachable');
  }
}
