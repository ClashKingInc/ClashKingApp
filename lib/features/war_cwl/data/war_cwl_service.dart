import 'dart:convert';
import 'package:clashkingapp/core/services/api_service.dart';
import 'package:clashkingapp/features/war_cwl/models/war_cwl.dart';
import 'package:clashkingapp/features/war_cwl/models/war_info.dart';
import 'package:clashkingapp/features/war_cwl/models/cwl_league.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
    return Future.wait(batch.map(_resolveCurrentWar));
  }

  Future<WarCwl> _resolveCurrentWar(String clanTag) async {
    final encodedTag = Uri.encodeComponent(clanTag);
    final basicResponse = await _apiService.getResponse(
      '/war/$encodedTag/basic',
    );
    final basic = basicResponse.statusCode == 200
        ? _decodeNullableMap(basicResponse)
        : null;

    if (basic != null && basic.isNotEmpty) {
      final type = basic['type']?.toString().toLowerCase() ?? '';
      final warTag = basic['warTag']?.toString();
      if (type.contains('cwl') || type.contains('league')) {
        final cwl = await _loadCwl(clanTag, preferredWarTag: warTag);
        if (cwl != null) return cwl;
      } else {
        return _loadScheduledRegularWar(clanTag, basic);
      }
    }

    return _loadManualCurrentWar(clanTag);
  }

  Future<WarCwl> _loadScheduledRegularWar(
    String clanTag,
    Map<String, dynamic> basic,
  ) async {
    final left = _map(basic['clan']);
    final right = _map(basic['opponent']);
    final leftTag = _normalizeTag(left['tag']?.toString());
    final rightTag = _normalizeTag(right['tag']?.toString());
    final requestedIsRight = rightTag == clanTag;
    final requested = requestedIsRight ? right : left;
    final opponent = requestedIsRight ? left : right;
    final requestedPublic = requested['publicWarLog'] as bool?;
    final opponentPublic = opponent['publicWarLog'] as bool?;
    final opponentTag = requestedIsRight ? leftTag : rightTag;

    final candidates = <String>[
      if (requestedPublic != false) clanTag,
      if (opponentTag != null && opponentPublic != false) opponentTag,
    ];
    for (final candidate in candidates) {
      final war = await _fetchRegularWar(candidate);
      if (war != null && _isFullWar(war)) {
        return _regularResult(clanTag, war.reorderForClan(clanTag));
      }
    }
    return _privateResult(clanTag);
  }

  Future<WarCwl> _loadManualCurrentWar(String clanTag) async {
    final regular = await _fetchRegularWar(clanTag);
    if (regular != null && _isFullWar(regular)) {
      return _regularResult(clanTag, regular.reorderForClan(clanTag));
    }

    final cwl = await _loadCwl(clanTag);
    if (cwl != null) return cwl;

    if (regular?.state == 'accessDenied') return _privateResult(clanTag);
    return _notInWarResult(clanTag);
  }

  Future<WarInfo?> _fetchRegularWar(String clanTag) async {
    final encodedTag = Uri.encodeComponent(clanTag);
    final response = await _apiService.proxyGet(
      '/clans/$encodedTag/currentwar',
    );
    if (response.statusCode == 403) return WarInfo(state: 'accessDenied');
    if (response.statusCode != 200) return null;
    final data = _decodeNullableMap(response);
    if (data == null) return null;
    if (data['reason'] == 'accessDenied') {
      return WarInfo(state: 'accessDenied');
    }
    return WarInfo.fromJson(data);
  }

  Future<WarCwl?> _loadCwl(String clanTag, {String? preferredWarTag}) async {
    final encodedTag = Uri.encodeComponent(clanTag);
    final groupResponse = await _apiService.proxyGet(
      '/clans/$encodedTag/currentwar/leaguegroup',
    );
    final group = groupResponse.statusCode == 200
        ? _decodeNullableMap(groupResponse)
        : null;

    if (preferredWarTag != null && preferredWarTag.isNotEmpty) {
      final war = await _fetchCwlWar(preferredWarTag);
      if (war != null && _isFullWar(war)) {
        return WarCwl(
          tag: clanTag,
          isInWar: false,
          isInCwl: true,
          warInfo: WarInfo(state: 'notInWar'),
          leagueInfo: group == null ? null : CwlLeague.fromJson(group),
          warLeagueInfos: [war.reorderForClan(clanTag)],
        );
      }
    }
    if (group == null || group['rounds'] is! List) return null;

    final rounds = (group['rounds'] as List).whereType<Map>().toList();
    for (final round in rounds.reversed) {
      final tags = (round['warTags'] as List? ?? const [])
          .map((tag) => tag.toString())
          .where((tag) => tag.isNotEmpty && tag != '#0')
          .toList(growable: false);
      if (tags.isEmpty) continue;
      final wars = (await Future.wait(
        tags.map(_fetchCwlWar),
      )).whereType<WarInfo>().where(_isFullWar).toList(growable: false);
      final includesClan = wars.any(
        (war) =>
            _normalizeTag(war.clan?.tag) == clanTag ||
            _normalizeTag(war.opponent?.tag) == clanTag,
      );
      if (includesClan) {
        return WarCwl(
          tag: clanTag,
          isInWar: false,
          isInCwl: true,
          warInfo: WarInfo(state: 'notInWar'),
          leagueInfo: CwlLeague.fromJson(group),
          warLeagueInfos: wars,
        );
      }
    }
    return null;
  }

  Future<WarInfo?> _fetchCwlWar(String warTag) async {
    final encodedTag = Uri.encodeComponent(warTag);
    final response = await _apiService.proxyGet(
      '/clanwarleagues/wars/$encodedTag',
    );
    if (response.statusCode != 200) return null;
    final data = _decodeNullableMap(response);
    if (data == null) return null;
    data['war_tag'] = warTag;
    data['warType'] = 'cwl';
    return WarInfo.fromJson(data);
  }

  static bool _isFullWar(WarInfo war) =>
      war.state != 'notInWar' &&
      war.state != 'unknown' &&
      war.state != 'accessDenied' &&
      war.clan != null &&
      war.opponent != null;

  static WarCwl _regularResult(String clanTag, WarInfo war) => WarCwl(
    tag: clanTag,
    isInWar: true,
    isInCwl: false,
    warInfo: war,
    leagueInfo: null,
    warLeagueInfos: const [],
  );

  static WarCwl _notInWarResult(String clanTag) => WarCwl(
    tag: clanTag,
    isInWar: false,
    isInCwl: false,
    warInfo: WarInfo(state: 'notInWar'),
    leagueInfo: null,
    warLeagueInfos: const [],
  );

  static WarCwl _privateResult(String clanTag) => WarCwl(
    tag: clanTag,
    isInWar: false,
    isInCwl: false,
    warInfo: WarInfo(state: 'accessDenied'),
    leagueInfo: null,
    warLeagueInfos: const [],
  );

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

Map<String, dynamic>? _decodeNullableMap(http.Response response) {
  final decoded = jsonDecode(ApiService.decodeResponseBody(response));
  if (decoded is Map) return Map<String, dynamic>.from(decoded);
  return null;
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

WarCwl? _parseWarSummary(dynamic item, [Set<String>? requestedTags]) {
  if (item is! Map) return null;
  try {
    final json = Map<String, dynamic>.from(item);
    final tag = _normalizeTag(json['clan_tag']?.toString());
    if (tag == null ||
        (requestedTags != null && !requestedTags.contains(tag))) {
      return null;
    }
    if ((json['war_info'] != null && json['war_info'] is! Map) ||
        (json['war_league_infos'] != null &&
            json['war_league_infos'] is! List)) {
      return null;
    }
    json['clan_tag'] = tag;
    return WarCwl.fromJson(json, tag);
  } catch (error) {
    DebugUtils.debugError("Error parsing war summary item: $error");
    return null;
  }
}
