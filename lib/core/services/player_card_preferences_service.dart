import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Per-player card options stored locally on the device.
///
/// These are the toggles revealed under each player card (notifications,
/// show this account's clan in the War tab, and show this account in the full
/// to-do page).
class PlayerCardOptions {
  const PlayerCardOptions({
    this.notificationsEnabled = false,
    this.showInWarTab = true,
    this.showInTodoPage = true,
    this.showUpgradeTrackerOnHome = true,
    this.showRankedOnHome = true,
  });

  final bool notificationsEnabled;
  final bool showInWarTab;
  final bool showInTodoPage;
  final bool showUpgradeTrackerOnHome;
  final bool showRankedOnHome;

  bool get isDefault =>
      !notificationsEnabled &&
      showInWarTab &&
      showInTodoPage &&
      showUpgradeTrackerOnHome &&
      showRankedOnHome;

  PlayerCardOptions copyWith({
    bool? notificationsEnabled,
    bool? showInWarTab,
    bool? showInTodoPage,
    bool? showUpgradeTrackerOnHome,
    bool? showRankedOnHome,
  }) {
    return PlayerCardOptions(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      showInWarTab: showInWarTab ?? this.showInWarTab,
      showInTodoPage: showInTodoPage ?? this.showInTodoPage,
      showUpgradeTrackerOnHome:
          showUpgradeTrackerOnHome ?? this.showUpgradeTrackerOnHome,
      showRankedOnHome: showRankedOnHome ?? this.showRankedOnHome,
    );
  }

  Map<String, dynamic> toJson() => {
    'notifications': notificationsEnabled,
    'warTab': showInWarTab,
    'todoPage': showInTodoPage,
    'upgradeTrackerHome': showUpgradeTrackerOnHome,
    'rankedHome': showRankedOnHome,
  };

  factory PlayerCardOptions.fromJson(Map<String, dynamic> json) {
    return PlayerCardOptions(
      notificationsEnabled: json['notifications'] == true,
      showInWarTab: json['warTab'] != false,
      showInTodoPage: json['todoPage'] != false,
      showUpgradeTrackerOnHome: json['upgradeTrackerHome'] != false,
      showRankedOnHome: json['rankedHome'] != false,
    );
  }
}

/// Persists the per-player card options (keyed by the normalized player tag)
/// and notifies listeners so account-scoped views stay in sync.
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

  bool isShownInWarTab(String tag) => optionsFor(tag).showInWarTab;

  bool isShownInTodoPage(String tag) => optionsFor(tag).showInTodoPage;

  bool isUpgradeTrackerShownOnHome(String tag) =>
      optionsFor(tag).showUpgradeTrackerOnHome;

  bool isRankedShownOnHome(String tag) => optionsFor(tag).showRankedOnHome;

  /// Drops the in-memory per-tag options — called on sign-out so a shared
  /// device's next signed-in account never inherits the previous account's
  /// "hidden from Home" choices for a tag it also happens to verify, even
  /// though the persisted preferences were already cleared.
  void clear() {
    _optionsByTag.clear();
    notifyListeners();
  }

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

  Future<void> setShowInWarTab(String tag, bool value) {
    return _update(tag, (options) => options.copyWith(showInWarTab: value));
  }

  Future<void> setShowInTodoPage(String tag, bool value) {
    return _update(tag, (options) => options.copyWith(showInTodoPage: value));
  }

  Future<void> setShowUpgradeTrackerOnHome(String tag, bool value) {
    return _update(
      tag,
      (options) => options.copyWith(showUpgradeTrackerOnHome: value),
    );
  }

  Future<void> setShowRankedOnHome(String tag, bool value) {
    return _update(tag, (options) => options.copyWith(showRankedOnHome: value));
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
