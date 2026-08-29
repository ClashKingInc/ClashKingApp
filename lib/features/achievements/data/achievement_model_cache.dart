import 'dart:convert';

import 'package:http/http.dart' as http;

class AchievementModelCache {
  AchievementModelCache({
    http.Client? client,
    this.timeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client();

  static final AchievementModelCache shared = AchievementModelCache();

  final http.Client _client;
  final Duration timeout;
  final Map<String, String> _resolvedSources = {};
  final Map<String, Future<String>> _pendingSources = {};

  String? peek(String url) => _resolvedSources[url];

  Future<String> resolve(String url) {
    final resolved = _resolvedSources[url];
    if (resolved != null) return Future.value(resolved);
    return _pendingSources.putIfAbsent(url, () => _download(url));
  }

  Future<String> _download(String url) async {
    try {
      final response = await _client.get(Uri.parse(url)).timeout(timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        _resolvedSources[url] = url;
        return url;
      }
      final source =
          'data:model/gltf-binary;base64,${base64Encode(response.bodyBytes)}';
      _resolvedSources[url] = source;
      return source;
    } catch (_) {
      _resolvedSources[url] = url;
      return url;
    } finally {
      _pendingSources.remove(url);
    }
  }
}
