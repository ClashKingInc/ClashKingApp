import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-player card options stored locally on the device.
///
/// These are the toggles revealed under each player card (notifications,
/// show the to-do card on the home dashboard, show this account's clan
/// in the War tab).
class PlayerCardOptions {
  const PlayerCardOptions({
    this.notificationsEnabled = false,
    this.showTodoOnHome = false,
    this.showInWarTab = true,
  });

  final bool notificationsEnabled;
  final bool showTodoOnHome;
  final bool showInWarTab;

  bool get isDefault =>
      !notificationsEnabled && !showTodoOnHome && showInWarTab;

  PlayerCardOptions copyWith({
    bool? notificationsEnabled,
    bool? showTodoOnHome,
    bool? showInWarTab,
  }) {
    return PlayerCardOptions(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      showTodoOnHome: showTodoOnHome ?? this.showTodoOnHome,
      showInWarTab: showInWarTab ?? this.showInWarTab,
    );
  }

  Map<String, dynamic> toJson() => {
    'notifications': notificationsEnabled,
    'todoHome': showTodoOnHome,
    'warTab': showInWarTab,
  };

  factory PlayerCardOptions.fromJson(Map<String, dynamic> json) {
    return PlayerCardOptions(
      notificationsEnabled: json['notifications'] == true,
      showTodoOnHome: json['todoHome'] == true,
      showInWarTab: json['warTab'] != false,
    );
  }
}

/// Persists the per-player card options (keyed by the normalized player tag)
/// and notifies listeners so the players list and the home dashboard stay in
/// sync when a toggle changes.
class PlayerCardPreferencesService extends ChangeNotifier {
  static const String _prefsKey = 'player_card_options_v1';

  PlayerCardPreferencesService() {
    unawaited(load());
  }

  bool _loaded = false;
  final Map<String, PlayerCardOptions> _optionsByTag = {};

  bool get loaded => _loaded;

  static String _normalizeTag(String tag) =>
      tag.replaceAll('#', '').trim().toUpperCase();

  PlayerCardOptions optionsFor(String tag) =>
      _optionsByTag[_normalizeTag(tag)] ?? const PlayerCardOptions();

  bool isTodoOnHomeEnabled(String tag) => optionsFor(tag).showTodoOnHome;

  bool isShownInWarTab(String tag) => optionsFor(tag).showInWarTab;

  /// Normalized tags whose to-do card should be shown on the home dashboard.
  Set<String> get todoOnHomeTags => _optionsByTag.entries
      .where((entry) => entry.value.showTodoOnHome)
      .map((entry) => entry.key)
      .toSet();

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _optionsByTag.clear();
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          decoded.forEach((tag, value) {
            if (value is Map<String, dynamic>) {
              _optionsByTag[tag] = PlayerCardOptions.fromJson(value);
            }
          });
        }
      } catch (_) {
        // Ignore malformed stored preferences.
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(String tag, bool value) {
    return _update(
      tag,
      (options) => options.copyWith(notificationsEnabled: value),
    );
  }

  Future<void> setShowTodoOnHome(String tag, bool value) {
    return _update(tag, (options) => options.copyWith(showTodoOnHome: value));
  }

  Future<void> setShowInWarTab(String tag, bool value) {
    return _update(tag, (options) => options.copyWith(showInWarTab: value));
  }

  Future<void> _update(
    String tag,
    PlayerCardOptions Function(PlayerCardOptions options) transform,
  ) async {
    final key = _normalizeTag(tag);
    final updated = transform(_optionsByTag[key] ?? const PlayerCardOptions());
    if (updated.isDefault) {
      _optionsByTag.remove(key);
    } else {
      _optionsByTag[key] = updated;
    }
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      for (final entry in _optionsByTag.entries)
        entry.key: entry.value.toJson(),
    };
    await prefs.setString(_prefsKey, jsonEncode(map));
  }
}
