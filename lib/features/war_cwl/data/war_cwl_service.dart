import 'dart:convert';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:clashkingapp/core/utils/debug_utils.dart';

class WarCwlService extends ChangeNotifier {
  WarCwlService({ApiService? apiService})
    : _apiService = apiService ?? ApiService.shared;

  final ApiService _apiService;
  final Map<String, WarCwl> summaries = {};
  final Map<String, _InFlightWarLoad> _inFlightLoads = {};
  final Map<String, int> _latestRequestByTag = {};
  int _requestSequence = 0;

  static const int _maxBatchSize = 100;

  Future<void> loadAllWarData(
    List<String> clanTags, {
    bool notify = true,
    bool throwOnError = false,
  }) {
    final normalizedTags = _normalizeTags(clanTags);
    if (normalizedTags.isEmpty) return Future.value();

    final loadKey = (List<String>.from(normalizedTags)..sort()).join(',');
    final existing = _inFlightLoads[loadKey];
    if (existing != null) {
      existing.shouldNotify = existing.shouldNotify || notify;
      return _applyErrorPolicy(existing.future, throwOnError: throwOnError);
    }

    final requestId = ++_requestSequence;
    for (final tag in normalizedTags) {
      _latestRequestByTag[tag] = requestId;
    }

    late final _InFlightWarLoad load;
    final future = _loadWarData(normalizedTags, requestId: requestId)
        .then((outcome) {
          if (outcome.changed && load.shouldNotify) notifyListeners();
          return outcome;
        })
        .whenComplete(() {
          if (identical(_inFlightLoads[loadKey], load)) {
            _inFlightLoads.remove(loadKey);
          }
        });
    load = _InFlightWarLoad(future: future, shouldNotify: notify);
    _inFlightLoads[loadKey] = load;
    return _applyErrorPolicy(future, throwOnError: throwOnError);
  }

  Future<_WarLoadOutcome> _loadWarData(
    List<String> clanTags, {
    required int requestId,
  }) async {
    var changed = false;
    final errors = <Object>[];
    DebugUtils.debugInfo("🏰 Loading war data for tags: $clanTags");

    for (var start = 0; start < clanTags.length; start += _maxBatchSize) {
      final proposedEnd = start + _maxBatchSize;
      final end = proposedEnd < clanTags.length ? proposedEnd : clanTags.length;
      final batch = clanTags.sublist(start, end);
      try {
        final parsedSummaries = await _loadWarBatch(batch);
        changed =
            _applyWarBatch(parsedSummaries, requestId: requestId) || changed;
      } catch (error) {
        errors.add(error);
        Sentry.captureException(error);
        DebugUtils.debugError("Error loading war data batch: $error");
      }
    }

    return _WarLoadOutcome(changed: changed, errors: errors);
  }

  Future<List<WarCwl>> _loadWarBatch(List<String> batch) async {
    final response = await _apiService.postResponse(
      '/war/war-summary',
      body: {"clan_tags": batch},
      requiresAuth: true,
    );
    if (response.statusCode != 200) {
      throw Exception("Failed to load war data (${response.statusCode})");
    }

    final decoded = jsonDecode(ApiService.decodeResponseBody(response));
    final items = decoded is Map ? decoded['items'] : null;
    if (items is! List) {
      throw const FormatException('War summary response has no items');
    }

    final requestedTags = batch.toSet();
    final parsedSummaries = <WarCwl>[];
    for (final item in items) {
      final parsed = _parseWarSummary(item, requestedTags);
      if (parsed != null) parsedSummaries.add(parsed);
    }
    return parsedSummaries;
  }

  bool _applyWarBatch(List<WarCwl> parsedSummaries, {required int requestId}) {
    var changed = false;
    for (final parsed in parsedSummaries) {
      if (_latestRequestByTag[parsed.tag] != requestId) continue;
      summaries[parsed.tag] = parsed;
      changed = true;
      DebugUtils.debugSuccess("Loaded war data for clan: ${parsed.tag}");
    }
    return changed;
  }

  Future<void> _applyErrorPolicy(
    Future<_WarLoadOutcome> future, {
    required bool throwOnError,
  }) async {
    final outcome = await future;
    if (outcome.errors.isNotEmpty && throwOnError) throw outcome.errors.first;
  }

  WarCwl? getWarCwlByTag(String tag) {
    final normalizedTag = _normalizeTag(tag);
    if (normalizedTag == null) return null;
    return summaries[normalizedTag];
  }

  /// Process bulk war data from the optimized API endpoint
  void processBulkWarData(List<dynamic> warData, {bool notify = true}) {
    DebugUtils.debugInfo("🔄 Processing ${warData.length} bulk war data items");

    var changed = false;
    for (final warItem in warData) {
      final warSummary = _parseWarSummary(warItem);
      if (warSummary == null) continue;
      summaries[warSummary.tag] = warSummary;
      changed = true;
      DebugUtils.debugSuccess(
        "Processed bulk war data for clan: ${warSummary.tag}",
      );
    }

    DebugUtils.debugSuccess(
      "Processed all bulk war data, total summaries: ${summaries.length}",
    );
    if (changed && notify) notifyListeners();
  }

  void notifyDataChanged() {
    notifyListeners();
  }

  static Future<WarInfo?> fetchWarDataFromTime(
    String tag,
    DateTime end, {
    ApiService? apiService,
  }) async {
    final client = apiService ?? ApiService.shared;
    final encodedTag = Uri.encodeComponent(tag);
    final endTime = end.millisecondsSinceEpoch ~/ 1000;

    final response = await client.getResponse(
      '/war/$encodedTag/previous?timestamp_end=$endTime&include_cwl=true&limit=1',
      requiresAuth: true,
    );
    if (response.statusCode == 200) {
      String body = ApiService.decodeResponseBody(response);
      Map<String, dynamic> jsonBody = json.decode(body);
      final items = jsonBody['items'];
      if (items is List && items.isNotEmpty && items.first is Map) {
        return WarInfo.fromJson(Map<String, dynamic>.from(items.first as Map));
      }
    } else {
      return null;
    }
    return null;
  }
}

class _InFlightWarLoad {
  _InFlightWarLoad({required this.future, required this.shouldNotify});

  final Future<_WarLoadOutcome> future;
  bool shouldNotify;
}

class _WarLoadOutcome {
  const _WarLoadOutcome({required this.changed, required this.errors});

  final bool changed;
  final List<Object> errors;
}

List<String> _normalizeTags(List<String> tags) {
  final normalized = <String>[];
  final seen = <String>{};
  for (final tag in tags) {
    final value = _normalizeTag(tag);
    if (value != null && seen.add(value)) normalized.add(value);
  }
  return normalized;
}

String? _normalizeTag(String? tag) {
  final value = tag?.trim().toUpperCase() ?? '';
  if (value.isEmpty) return null;
  return value.startsWith('#') ? value : '#$value';
}

WarCwl? _parseWarSummary(dynamic item, [Set<String>? requestedTags]) {
  if (item is! Map) return null;
  try {
    final json = Map<String, dynamic>.from(item);
    final tag = _normalizeTag(json['clan_tag']?.toString());
    if (tag == null ||
        (requestedTags != null && !requestedTags.contains(tag))) {
      return null;
    }
    if (json['war_league_infos'] != null && json['war_league_infos'] is! List) {
      return null;
    }
    json['clan_tag'] = tag;
    return WarCwl.fromJson(json, tag);
  } catch (error) {
    DebugUtils.debugError("Error parsing war summary item: $error");
    return null;
  }
}
