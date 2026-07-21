class HomeActivityItem {
  const HomeActivityItem({
    required this.type,
    required this.timestamp,
    required this.eventType,
    required this.playerTag,
    required this.data,
    this.clanTag,
    this.playerName,
    this.clanName,
    this.townHallLevel,
    this.season,
    this.value,
  });

  final String type;
  final DateTime timestamp;
  final String eventType;
  final String playerTag;
  final String? clanTag;
  final String? playerName;
  final String? clanName;
  final int? townHallLevel;
  final String? season;
  final int? value;
  final Map<String, dynamic> data;

  bool isNewSince(DateTime? priorLogin) =>
      priorLogin != null && timestamp.isAfter(priorLogin);

  factory HomeActivityItem.fromJson(Map<String, dynamic> json) {
    final type = _requiredString(json, 'type');
    if (type != 'join_leave' && type != 'player_history') {
      throw FormatException('Unsupported Home activity type: $type');
    }
    final timestampText = _requiredString(json, 'timestamp');
    final timestamp = DateTime.tryParse(timestampText);
    if (timestamp == null) {
      throw const FormatException('Home activity timestamp is invalid');
    }
    final rawData = json['data'];
    if (rawData is! Map) {
      throw const FormatException('Home activity data must be an object');
    }

    return HomeActivityItem(
      type: type,
      timestamp: timestamp.toUtc(),
      eventType: _requiredString(json, 'event_type'),
      playerTag: _requiredString(json, 'player_tag'),
      clanTag: _optionalString(json['clan_tag']),
      playerName: _optionalString(json['player_name']),
      clanName: _optionalString(json['clan_name']),
      townHallLevel: _optionalInt(json['townhall_level']),
      season: _optionalString(json['season']),
      value: _optionalInt(json['value']),
      data: Map<String, dynamic>.from(rawData),
    );
  }
}

class HomeActivityResponse {
  const HomeActivityResponse({required this.items});

  final List<HomeActivityItem> items;

  factory HomeActivityResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const FormatException('Home activity items must be a list');
    }
    return HomeActivityResponse(
      items: rawItems
          .map((raw) {
            if (raw is! Map) {
              throw const FormatException(
                'Home activity item must be an object',
              );
            }
            return HomeActivityItem.fromJson(Map<String, dynamic>.from(raw));
          })
          .toList(growable: false),
    );
  }
}

class HomeUpgradeRecord {
  const HomeUpgradeRecord({
    required this.playerTag,
    required this.data,
    required this.updatedAt,
  });

  final String playerTag;
  final Map<String, dynamic> data;
  final DateTime? updatedAt;

  factory HomeUpgradeRecord.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    if (rawData is! Map) {
      throw const FormatException('Upgrade data must be an object');
    }
    return HomeUpgradeRecord(
      playerTag: _requiredString(json, 'player_tag'),
      data: Map<String, dynamic>.from(rawData),
      updatedAt: _optionalDateTime(json['updated_at']),
    );
  }

  List<HomeUpgradeTimer> timers() {
    final rawTimestamp = _optionalInt(data['timestamp']);
    final capturedAt = rawTimestamp == null
        ? updatedAt
        : DateTime.fromMillisecondsSinceEpoch(rawTimestamp * 1000, isUtc: true);
    if (capturedAt == null) return const [];
    final result = <HomeUpgradeTimer>[];
    _collectTimers(
      data,
      inheritedName: null,
      capturedAt: capturedAt,
      result: result,
    );
    result.sort((a, b) => a.finishesAt.compareTo(b.finishesAt));
    return result;
  }

  static void _collectTimers(
    Object? value, {
    required String? inheritedName,
    required DateTime capturedAt,
    required List<HomeUpgradeTimer> result,
  }) {
    if (value is List) {
      for (final child in value) {
        _collectTimers(
          child,
          inheritedName: inheritedName,
          capturedAt: capturedAt,
          result: result,
        );
      }
      return;
    }
    if (value is! Map) return;

    final map = Map<String, dynamic>.from(value);
    final ownName = _optionalString(map['name']) ?? inheritedName;
    for (final key in const [
      'timer',
      'upgrade_timer',
      'remaining_seconds',
      'time_left',
    ]) {
      final seconds = _optionalInt(map[key]);
      if (seconds != null && seconds > 0) {
        result.add(
          HomeUpgradeTimer(
            name: ownName ?? 'Upgrade',
            finishesAt: capturedAt.add(Duration(seconds: seconds)),
          ),
        );
        break;
      }
    }
    for (final entry in map.entries) {
      if (const {
        'timer',
        'upgrade_timer',
        'remaining_seconds',
        'time_left',
      }.contains(entry.key)) {
        continue;
      }
      _collectTimers(
        entry.value,
        inheritedName: ownName,
        capturedAt: capturedAt,
        result: result,
      );
    }
  }
}

class HomeUpgradeTimer {
  const HomeUpgradeTimer({required this.name, required this.finishesAt});

  final String name;
  final DateTime finishesAt;

  bool isRecentlyCompleted(DateTime now) =>
      !finishesAt.isAfter(now) &&
      now.difference(finishesAt) <= const Duration(minutes: 15);
}

class HomeUpgradePreferences {
  const HomeUpgradePreferences({
    required this.playerTag,
    required this.preferences,
    this.updatedAt,
  });

  final String playerTag;
  final Map<String, dynamic> preferences;
  final DateTime? updatedAt;

  factory HomeUpgradePreferences.fromJson(Map<String, dynamic> json) {
    final rawPreferences = json['preferences'];
    if (rawPreferences is! Map) {
      throw const FormatException('Upgrade preferences must be an object');
    }
    return HomeUpgradePreferences(
      playerTag: _requiredString(json, 'player_tag'),
      preferences: Map<String, dynamic>.from(rawPreferences),
      updatedAt: _optionalDateTime(json['updated_at']),
    );
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key must be a non-empty string');
  }
  return value;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _optionalInt(Object? value) => switch (value) {
  final int number => number,
  final num number => number.toInt(),
  final String text => int.tryParse(text),
  _ => null,
};

DateTime? _optionalDateTime(Object? value) {
  final text = _optionalString(value);
  return text == null ? null : DateTime.tryParse(text)?.toUtc();
}
