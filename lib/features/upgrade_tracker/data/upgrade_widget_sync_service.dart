import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/core/services/game_data_service.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';
import 'package:clashkingapp/l10n/app_localizations.dart';
import 'package:clashkingapp/l10n/game_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class UpgradeWidgetSyncService {
  const UpgradeWidgetSyncService();

  static const _appGroup = 'group.com.clashking.apps';

  static String? _appGroupForPlatform() {
    if (kIsWeb) return null;
    return Platform.isIOS ? _appGroup : null;
  }

  Future<void> sync(
    List<UpgradeTrackerSnapshot> linkedSnapshots, {
    required List<Map<String, Object?>> linkedAccounts,
    String? selectedTag,
  }) async {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(_appGroup);
    }

    final snapshotsByTag = {
      for (final snapshot in linkedSnapshots)
        _normalized(snapshot.tag): snapshot,
    };
    final accounts = _widgetAccounts(linkedSnapshots, linkedAccounts);

    await HomeWidget.saveWidgetData<String>(
      'upgradeWidgetAccounts',
      jsonEncode(accounts),
      appGroupId: _appGroupForPlatform(),
    );
    final normalizedSelectedTag = _normalized(selectedTag ?? '');
    String? selectedPayload;
    String? firstPayload;
    String? firstTag;
    for (final account in accounts) {
      final tag = account['tag']!.toString();
      final normalizedTag = _normalized(tag);
      final snapshot = snapshotsByTag[_normalized(tag)]!;
      final payload = jsonEncode(
        _widgetPayload(
          snapshot,
          canonicalTag: tag,
          canonicalName: account['name']!.toString(),
          townHallLevel: _int(account['townHallLevel']),
          builderHallLevel: _int(account['builderHallLevel']),
        ),
      );
      firstPayload ??= payload;
      firstTag ??= normalizedTag;
      if (normalizedTag == normalizedSelectedTag) {
        selectedPayload = payload;
      }
      await HomeWidget.saveWidgetData<String>(
        'upgradeWidget_$normalizedTag',
        payload,
        appGroupId: _appGroupForPlatform(),
      );
    }
    if (accounts.isEmpty) {
      await _clearCurrentWidgetSelection();
      await HomeWidget.updateWidget(
        name: 'UpgradeWidget',
        androidName: 'UpgradeAppWidgetProvider',
        iOSName: 'UpgradeWidget',
      );
      return;
    }
    if (Platform.isAndroid) {
      final resolvedSelectedTag = normalizedSelectedTag.isNotEmpty
          ? normalizedSelectedTag
          : firstTag ?? '';
      await HomeWidget.saveWidgetData<String>(
        'upgradeWidgetData',
        selectedPayload ??
            (normalizedSelectedTag.isEmpty ? firstPayload ?? '' : ''),
      );
      await HomeWidget.saveWidgetData<String>(
        'upgradeWidgetSelectedTag',
        resolvedSelectedTag,
      );
    }
    await HomeWidget.updateWidget(
      name: 'UpgradeWidget',
      androidName: 'UpgradeAppWidgetProvider',
      iOSName: 'UpgradeWidget',
    );
  }

  Future<void> syncSelectedTag(String? selectedTag) async {
    if (kIsWeb || !Platform.isAndroid) return;

    final accounts = await _cachedAccounts();
    final normalizedSelectedTag = _normalized(selectedTag ?? '');
    String? selectedPayload;
    String? firstPayload;
    String? firstTag;

    for (final account in accounts) {
      final normalizedTag = _normalized(account['tag']?.toString() ?? '');
      if (normalizedTag.isEmpty) continue;
      final payload = await HomeWidget.getWidgetData<String>(
        'upgradeWidget_$normalizedTag',
      );
      if (payload == null || payload.isEmpty) continue;
      firstPayload ??= payload;
      firstTag ??= normalizedTag;
      if (normalizedTag == normalizedSelectedTag) {
        selectedPayload = payload;
        break;
      }
    }

    final resolvedSelectedTag = normalizedSelectedTag.isNotEmpty
        ? normalizedSelectedTag
        : firstTag ?? '';
    await HomeWidget.saveWidgetData<String>(
      'upgradeWidgetData',
      selectedPayload ??
          (normalizedSelectedTag.isEmpty ? firstPayload ?? '' : ''),
    );
    await HomeWidget.saveWidgetData<String>(
      'upgradeWidgetSelectedTag',
      resolvedSelectedTag,
    );
    await HomeWidget.updateWidget(
      name: 'UpgradeWidget',
      androidName: 'UpgradeAppWidgetProvider',
      iOSName: 'UpgradeWidget',
    );
  }

  Future<void> clear() async {
    if (kIsWeb || !(Platform.isIOS || Platform.isAndroid)) return;
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(_appGroup);
    }
    await HomeWidget.saveWidgetData<String>(
      'upgradeWidgetAccounts',
      jsonEncode(const []),
      appGroupId: _appGroupForPlatform(),
    );
    await _clearCurrentWidgetSelection();
    await HomeWidget.updateWidget(
      name: 'UpgradeWidget',
      androidName: 'UpgradeAppWidgetProvider',
      iOSName: 'UpgradeWidget',
    );
  }

  Future<void> _clearCurrentWidgetSelection() async {
    if (!Platform.isAndroid) return;
    await HomeWidget.saveWidgetData<String>('upgradeWidgetData', '');
    await HomeWidget.saveWidgetData<String>('upgradeWidgetSelectedTag', '');
  }

  Future<List<Map<String, Object?>>> _cachedAccounts() async {
    final raw = await HomeWidget.getWidgetData<String>(
      'upgradeWidgetAccounts',
      appGroupId: _appGroupForPlatform(),
    );
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, Object?>.from(item))
        .toList(growable: false);
  }

  Map<String, dynamic> _widgetPayload(
    UpgradeTrackerSnapshot snapshot, {
    required String canonicalTag,
    required String canonicalName,
    required int townHallLevel,
    required int builderHallLevel,
  }) {
    final now = DateTime.now();
    final l10n = lookupAppLocalizations(_supportedWidgetLocale());
    final hasStaleData = snapshot.items.any((item) {
      return !item.isComplete &&
          (item.activeSeconds ?? 0) > 0 &&
          snapshot.remainingActiveSeconds(item, now: now) <= 0;
    });

    return {
      'tag': canonicalTag,
      'name': canonicalName,
      'townHallLevel': townHallLevel,
      'builderHallLevel': builderHallLevel,
      'hallImageUrl': townHallLevel > 0
          ? ImageAssets.townHall(townHallLevel)
          : ImageAssets.builderHall(builderHallLevel),
      'updatedAt': now.toUtc().toIso8601String(),
      'hasStaleData': hasStaleData,
      'labels': _labels(l10n),
      'boosts': _boostPayload(snapshot, now: now, l10n: l10n),
      'helpers': _helperPayload(snapshot, now: now, l10n: l10n),
      'homeBuilders': _widgetSection(
        snapshot,
        now: now,
        village: UpgradeVillage.home,
        queue: UpgradeQueue.builders,
        capacity: snapshot.homeBuilderCount,
        limit: 3,
      ),
      'laboratory': _widgetSection(
        snapshot,
        now: now,
        village: UpgradeVillage.home,
        queue: UpgradeQueue.laboratory,
        capacity: 1,
        limit: 2,
      ),
      'pets': _widgetSection(
        snapshot,
        now: now,
        village: UpgradeVillage.home,
        queue: UpgradeQueue.pets,
        capacity: 1,
        limit: 1,
      ),
      'builderBase': _widgetSection(
        snapshot,
        now: now,
        village: UpgradeVillage.builderBase,
        queue: UpgradeQueue.builders,
        capacity: snapshot.builderBaseBuilderCount,
        limit: 2,
      ),
    };
  }

  Locale _supportedWidgetLocale() {
    final deviceLocale = PlatformDispatcher.instance.locale;
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == deviceLocale.languageCode) return locale;
    }
    return const Locale('en');
  }

  List<Map<String, Object?>> _widgetAccounts(
    List<UpgradeTrackerSnapshot> linkedSnapshots,
    List<Map<String, Object?>> linkedAccounts,
  ) {
    final linkedAccountsByTag = {
      for (final account in linkedAccounts)
        _normalized(account['tag']?.toString() ?? ''): account,
    }..remove('');

    final accounts = <Map<String, Object?>>[];
    final seenTags = <String>{};
    for (final snapshot in linkedSnapshots) {
      final linkedAccount = linkedAccountsByTag[_normalized(snapshot.tag)];
      if (linkedAccount == null) continue;
      final account = _widgetAccount(snapshot, linkedAccount, seenTags);
      if (account != null) accounts.add(account);
    }
    return accounts;
  }

  Map<String, Object?>? _widgetAccount(
    UpgradeTrackerSnapshot snapshot,
    Map<String, Object?>? linkedAccount,
    Set<String> seenTags,
  ) {
    final normalizedTag = _normalized(snapshot.tag);
    if (normalizedTag.isEmpty || !seenTags.add(normalizedTag)) return null;

    final townHallLevel = _int(
      linkedAccount?['townHallLevel'],
    ).clamp(0, 99).toInt();
    final builderHallLevel = _int(
      linkedAccount?['builderHallLevel'],
    ).clamp(0, 99).toInt();
    return {
      'tag': _canonicalTag(normalizedTag),
      'name': _nonEmpty(linkedAccount?['name']) ?? snapshot.name,
      'townHallLevel': townHallLevel > 0
          ? townHallLevel
          : snapshot.townHallLevel,
      'builderHallLevel': builderHallLevel > 0
          ? builderHallLevel
          : snapshot.builderHallLevel,
    };
  }

  Map<String, dynamic> _widgetSection(
    UpgradeTrackerSnapshot snapshot, {
    required DateTime now,
    required UpgradeVillage village,
    required UpgradeQueue queue,
    required int capacity,
    required int limit,
  }) {
    final items = snapshot.itemsFor(village: village, queue: queue);
    final activeItems = items
        .where((item) => snapshot.remainingActiveSeconds(item, now: now) > 0)
        .toList(growable: false);
    final activeGroups = _widgetTaskGroups(snapshot, activeItems, now: now);
    final activeCount = activeItems.fold<int>(
      0,
      (sum, item) => sum + _activeInstanceCount(item),
    );
    final visibleGroups = activeGroups.take(limit).toList(growable: false);
    final hiddenGroups = activeGroups.skip(limit);
    DateTime? hiddenFinish;
    for (final group in hiddenGroups) {
      final finish = now.add(
        Duration(
          seconds: snapshot.remainingActiveSeconds(group.item, now: now),
        ),
      );
      if (hiddenFinish == null || finish.isBefore(hiddenFinish)) {
        hiddenFinish = finish;
      }
    }
    final hiddenFinishesAt = hiddenFinish?.toUtc().toIso8601String();
    final section = {
      'available': items.isNotEmpty,
      'capacity': capacity > activeCount ? capacity : activeCount,
      'activeCount': activeCount,
      'remainingCount': items
          .where((item) => !item.isComplete)
          .fold<int>(0, (sum, item) => sum + _instanceCount(item)),
      'tasks': visibleGroups
          .map((group) => _widgetTask(snapshot, group, now: now))
          .toList(growable: false),
    };
    if (hiddenFinishesAt != null) {
      section['hiddenFinishesAt'] = hiddenFinishesAt;
    }
    return section;
  }

  List<({UpgradeTrackerItem item, int count})> _widgetTaskGroups(
    UpgradeTrackerSnapshot snapshot,
    List<UpgradeTrackerItem> activeItems, {
    required DateTime now,
  }) {
    final groups = <({UpgradeTrackerItem item, int count})>[];
    for (final item in activeItems) {
      _addWidgetTaskGroup(snapshot, groups, item, now: now);
    }
    return groups;
  }

  void _addWidgetTaskGroup(
    UpgradeTrackerSnapshot snapshot,
    List<({UpgradeTrackerItem item, int count})> groups,
    UpgradeTrackerItem item, {
    required DateTime now,
  }) {
    final index = groups.indexWhere(
      (group) => _sameWidgetTask(snapshot, group.item, item, now: now),
    );
    if (index < 0) {
      groups.add((item: item, count: _activeInstanceCount(item)));
      return;
    }

    final group = groups[index];
    groups[index] = (
      item: group.item,
      count: group.count + _activeInstanceCount(item),
    );
  }

  Map<String, dynamic> _widgetTask(
    UpgradeTrackerSnapshot snapshot,
    ({UpgradeTrackerItem item, int count}) group, {
    required DateTime now,
  }) {
    final item = group.item;
    final remainingSeconds = snapshot.remainingActiveSeconds(item, now: now);
    final helperSeconds = snapshot.remainingHelperSeconds(item, now: now);
    return {
      'name': _localizedItemName(item),
      'imageUrl': item.imageUrl,
      'fromLevel': item.currentLevel,
      'toLevel': (item.currentLevel + 1).clamp(0, item.targetLevel),
      if (group.count > 1) 'count': group.count,
      'finishesAt': now
          .add(Duration(seconds: remainingSeconds))
          .toUtc()
          .toIso8601String(),
      if (helperSeconds > 0) 'helperName': snapshot.helperNameFor(item),
      if (helperSeconds > 0)
        'helperFinishesAt': now
            .add(Duration(seconds: helperSeconds))
            .toUtc()
            .toIso8601String(),
    };
  }

  bool _sameWidgetTask(
    UpgradeTrackerSnapshot snapshot,
    UpgradeTrackerItem first,
    UpgradeTrackerItem second, {
    required DateTime now,
  }) {
    return first.id == second.id &&
        first.name == second.name &&
        first.village == second.village &&
        first.queue == second.queue &&
        first.currentLevel == second.currentLevel &&
        first.targetLevel == second.targetLevel &&
        snapshot.remainingActiveSeconds(first, now: now) ==
            snapshot.remainingActiveSeconds(second, now: now) &&
        _activeHelperName(snapshot, first, now: now) ==
            _activeHelperName(snapshot, second, now: now);
  }

  String? _activeHelperName(
    UpgradeTrackerSnapshot snapshot,
    UpgradeTrackerItem item, {
    required DateTime now,
  }) {
    final helperSeconds = snapshot.remainingHelperSeconds(item, now: now);
    return helperSeconds > 0 ? snapshot.helperNameFor(item) : null;
  }

  static int _instanceCount(UpgradeTrackerItem item) =>
      item.count > 0 ? item.count : 1;

  static int _activeInstanceCount(UpgradeTrackerItem item) =>
      (item.activeSeconds ?? 0) > 0 ? 1 : _instanceCount(item);

  List<Map<String, dynamic>> _boostPayload(
    UpgradeTrackerSnapshot snapshot, {
    required DateTime now,
    required AppLocalizations l10n,
  }) {
    final boosts = snapshot.boosts;
    Map<String, dynamic> timed(
      String kind,
      String name,
      String shortName,
      int rawSeconds,
      String imageUrl,
    ) {
      final remaining = snapshot.remainingCapturedSeconds(rawSeconds);
      return {
        'kind': kind,
        'label': name,
        'shortLabel': shortName,
        'imageUrl': imageUrl,
        'expiresAt': now
            .add(Duration(seconds: remaining))
            .toUtc()
            .toIso8601String(),
      };
    }

    return [
      if (snapshot.remainingCapturedSeconds(boosts.builderConsumableSeconds) >
          0)
        timed(
          'builderPotion',
          l10n.gameName('TID_BOOSTER_BUILDERS', l10n.widgetBuilderPotion),
          l10n.widgetBuilderBoostShort,
          boosts.builderConsumableSeconds,
          ImageAssets.builderPotion,
        ),
      if (snapshot.remainingCapturedSeconds(boosts.labConsumableSeconds) > 0)
        timed(
          'researchPotion',
          l10n.gameName('TID_BOOSTER_LAB_POTION', l10n.widgetResearchPotion),
          l10n.widgetResearchBoostShort,
          boosts.labConsumableSeconds,
          ImageAssets.researchPotion,
        ),
      if (snapshot.remainingCapturedSeconds(boosts.petConsumableSeconds) > 0)
        timed(
          'petPotion',
          l10n.gameName('TID_BOOSTER_PET_POTION', l10n.widgetPetPotion),
          l10n.widgetPetBoostShort,
          boosts.petConsumableSeconds,
          ImageAssets.petPotion,
        ),
      if (snapshot.remainingCapturedSeconds(boosts.clockTowerBoostSeconds) > 0)
        timed(
          'clockTower',
          l10n.gameName('TID_BUILDING_CLOCK_TOWER', l10n.widgetClockTower),
          l10n.widgetClockBoostShort,
          boosts.clockTowerBoostSeconds,
          ImageAssets.clockTowerPotion,
        ),
      if (snapshot.remainingCapturedSeconds(boosts.builderBoostSeconds) > 0)
        timed(
          'townHallBuilder',
          l10n.widgetTownHallBuilderBoost,
          l10n.widgetBuilderBoostShort,
          boosts.builderBoostSeconds,
          ImageAssets.townHall(snapshot.townHallLevel),
        ),
      if (snapshot.remainingCapturedSeconds(boosts.labBoostSeconds) > 0)
        timed(
          'townHallLab',
          l10n.widgetTownHallLabBoost,
          l10n.widgetResearchBoostShort,
          boosts.labBoostSeconds,
          ImageAssets.townHall(snapshot.townHallLevel),
        ),
      if (boosts.builderCostReductionPercent > 0)
        {
          'kind': 'builderPerk',
          'label': l10n.widgetBuilderCostPerk(
            boosts.builderCostReductionPercent,
          ),
          'shortLabel': l10n.widgetBuilderBoostShort,
        },
      if (boosts.builderTimeReductionPercent > 0)
        {
          'kind': 'builderPerk',
          'label': l10n.widgetBuilderTimePerk(
            boosts.builderTimeReductionPercent,
          ),
          'shortLabel': l10n.widgetBuilderBoostShort,
        },
      if (boosts.labCostReductionPercent > 0)
        {
          'kind': 'labPerk',
          'label': l10n.widgetLabCostPerk(boosts.labCostReductionPercent),
          'shortLabel': l10n.widgetResearchBoostShort,
        },
      if (boosts.labTimeReductionPercent > 0)
        {
          'kind': 'labPerk',
          'label': l10n.widgetLabTimePerk(boosts.labTimeReductionPercent),
          'shortLabel': l10n.widgetResearchBoostShort,
        },
    ];
  }

  List<Map<String, dynamic>> _helperPayload(
    UpgradeTrackerSnapshot snapshot, {
    required DateTime now,
    required AppLocalizations l10n,
  }) {
    final helpers = snapshot.items.where((item) {
      if (item.category != UpgradeCategory.builders) return false;
      final name = item.name.toLowerCase();
      return name.contains('apprentice') ||
          name.contains('assistant') ||
          name.contains('alchemist');
    });
    return helpers
        .map((helper) {
          final assigned = snapshot.items.where((item) {
            return snapshot.helperNameFor(item) == helper.name &&
                snapshot.remainingHelperSeconds(item, now: now) > 0;
          }).firstOrNull;
          final cooldown = snapshot.remainingCooldownSeconds(helper, now: now);
          final activeSeconds = assigned == null
              ? 0
              : snapshot.remainingHelperSeconds(assigned, now: now);
          return {
            'name': _localizedItemName(helper),
            'shortName': _helperShortName(helper.name, l10n),
            'imageUrl': helper.imageUrl,
            'status': assigned != null
                ? l10n.widgetHelping
                : cooldown > 0
                ? l10n.widgetReadyIn
                : l10n.widgetReady,
            if (activeSeconds > 0)
              'statusUntil': now
                  .add(Duration(seconds: activeSeconds))
                  .toUtc()
                  .toIso8601String(),
            if (assigned == null && cooldown > 0)
              'statusUntil': now
                  .add(Duration(seconds: cooldown))
                  .toUtc()
                  .toIso8601String(),
          };
        })
        .toList(growable: false);
  }

  static Map<String, String> _labels(AppLocalizations l10n) => {
    'title': l10n.widgetUpgradeProgressTitle,
    'homeVillage': l10n.upgradeTrackerHomeVillage.toUpperCase(),
    'village': l10n.dashboardUpgradeTrackerVillage.toUpperCase(),
    'laboratory': l10n.widgetLaboratory,
    'pets': l10n.widgetPets,
    'builderBase': l10n.widgetBuilderBase,
    'research': l10n.widgetResearch,
    'active': l10n.widgetActive,
    'idle': l10n.widgetIdle,
    'locked': l10n.widgetLocked,
    'maxed': l10n.widgetMaxed,
    'notUnlocked': l10n.widgetNotUnlocked,
    'fullyUpgraded': l10n.widgetFullyUpgraded,
    'noActiveUpgrades': l10n.widgetNoActiveUpgrades,
    'noActiveResearch': l10n.widgetNoActiveResearch,
    'staleData': l10n.widgetDataStale,
    'moreUpgrade': l10n.widgetMoreUpgrade,
    'moreUpgrades': l10n.widgetMoreUpgrades,
    'level': l10n.widgetLevelShort,
    'ready': l10n.widgetReady,
  };

  static String _localizedItemName(UpgradeTrackerItem item) {
    final localized = GameDataService.localizedNameForItem(item.meta);
    return localized.trim().isNotEmpty ? localized : item.name;
  }

  static String _helperShortName(String name, AppLocalizations l10n) {
    final lower = name.toLowerCase();
    if (lower.contains('apprentice')) return l10n.widgetApprenticeShort;
    if (lower.contains('assistant')) return l10n.widgetAssistantShort;
    if (lower.contains('alchemist')) {
      return l10n.gameName(
        'TID_ALCHEMIST_APPRENTICE',
        l10n.widgetAlchemistShort,
      );
    }
    return name;
  }

  static String? _nonEmpty(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _int(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _normalized(String tag) =>
      tag.replaceAll('#', '').trim().toUpperCase();

  static String _canonicalTag(String normalizedTag) =>
      normalizedTag.isEmpty ? '' : '#$normalizedTag';
}
