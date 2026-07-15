import 'dart:convert';
import 'dart:io';

import 'package:clashkingapp/core/constants/image_assets.dart';
import 'package:clashkingapp/features/upgrade_tracker/models/upgrade_tracker_models.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class UpgradeWidgetSyncService {
  const UpgradeWidgetSyncService();

  static const _appGroup = 'group.com.clashking.apps';

  Future<void> sync(
    List<UpgradeTrackerSnapshot> linkedSnapshots, {
    required List<Map<String, Object?>> linkedAccounts,
  }) async {
    if (kIsWeb || !Platform.isIOS) return;
    await HomeWidget.setAppGroupId(_appGroup);

    final snapshotsByTag = {
      for (final snapshot in linkedSnapshots)
        _normalized(snapshot.tag): snapshot,
    };
    final accounts = <Map<String, Object?>>[];
    final seenTags = <String>{};
    for (final account in linkedAccounts) {
      final tag = account['tag']?.toString() ?? '';
      final normalizedTag = _normalized(tag);
      final snapshot = snapshotsByTag[normalizedTag];
      if (normalizedTag.isEmpty ||
          snapshot == null ||
          !seenTags.add(normalizedTag)) {
        continue;
      }
      final name = _nonEmpty(account['name']) ?? snapshot.name;
      final townHallLevel = _int(account['townHallLevel']).clamp(0, 99).toInt();
      final builderHallLevel = _int(
        account['builderHallLevel'],
      ).clamp(0, 99).toInt();
      accounts.add({
        'tag': _canonicalTag(normalizedTag),
        'name': name,
        'townHallLevel': townHallLevel > 0
            ? townHallLevel
            : snapshot.townHallLevel,
        'builderHallLevel': builderHallLevel > 0
            ? builderHallLevel
            : snapshot.builderHallLevel,
      });
    }

    await HomeWidget.saveWidgetData<String>(
      'upgradeWidgetAccounts',
      jsonEncode(accounts),
      appGroupId: _appGroup,
    );
    for (final account in accounts) {
      final tag = account['tag']!.toString();
      final snapshot = snapshotsByTag[_normalized(tag)]!;
      await HomeWidget.saveWidgetData<String>(
        'upgradeWidget_${_normalized(tag)}',
        jsonEncode(
          _widgetPayload(
            snapshot,
            canonicalTag: tag,
            canonicalName: account['name']!.toString(),
            townHallLevel: _int(account['townHallLevel']),
            builderHallLevel: _int(account['builderHallLevel']),
          ),
        ),
        appGroupId: _appGroup,
      );
    }
    await HomeWidget.updateWidget(
      name: 'UpgradeWidget',
      iOSName: 'UpgradeWidget',
    );
  }

  Map<String, dynamic> _widgetPayload(
    UpgradeTrackerSnapshot snapshot, {
    required String canonicalTag,
    required String canonicalName,
    required int townHallLevel,
    required int builderHallLevel,
  }) {
    final now = DateTime.now();

    Map<String, dynamic> section({
      required UpgradeVillage village,
      required UpgradeQueue queue,
      required int capacity,
      required int limit,
    }) {
      final items = snapshot.itemsFor(village: village, queue: queue);
      final remaining = items.where((item) => !item.isComplete).toList();
      final activeItems = items
          .where((item) => snapshot.remainingActiveSeconds(item, now: now) > 0)
          .take(limit)
          .toList(growable: false);
      return {
        'available': items.isNotEmpty,
        'capacity': capacity > activeItems.length
            ? capacity
            : activeItems.length,
        'remainingCount': remaining.length,
        'tasks': activeItems
            .map((item) {
              final remainingSeconds = snapshot.remainingActiveSeconds(
                item,
                now: now,
              );
              final helperSeconds = snapshot.remainingHelperSeconds(
                item,
                now: now,
              );
              return {
                'name': item.name,
                'imageUrl': item.imageUrl,
                'fromLevel': item.currentLevel,
                'toLevel': (item.currentLevel + 1).clamp(0, item.targetLevel),
                'finishesAt': now
                    .add(Duration(seconds: remainingSeconds))
                    .toUtc()
                    .toIso8601String(),
                if (helperSeconds > 0)
                  'helperName': snapshot.helperNameFor(item),
                if (helperSeconds > 0)
                  'helperFinishesAt': now
                      .add(Duration(seconds: helperSeconds))
                      .toUtc()
                      .toIso8601String(),
              };
            })
            .toList(growable: false),
      };
    }

    return {
      'tag': canonicalTag,
      'name': canonicalName,
      'townHallLevel': townHallLevel,
      'builderHallLevel': builderHallLevel,
      'hallImageUrl': townHallLevel > 0
          ? ImageAssets.townHall(townHallLevel)
          : ImageAssets.builderHall(builderHallLevel),
      'updatedAt': now.toUtc().toIso8601String(),
      'boosts': _boostPayload(snapshot, now: now),
      'helpers': _helperPayload(snapshot, now: now),
      'homeBuilders': section(
        village: UpgradeVillage.home,
        queue: UpgradeQueue.builders,
        capacity: snapshot.homeBuilderCount,
        limit: 3,
      ),
      'laboratory': section(
        village: UpgradeVillage.home,
        queue: UpgradeQueue.laboratory,
        capacity: 1,
        limit: 2,
      ),
      'pets': section(
        village: UpgradeVillage.home,
        queue: UpgradeQueue.pets,
        capacity: 1,
        limit: 1,
      ),
      'builderBase': section(
        village: UpgradeVillage.builderBase,
        queue: UpgradeQueue.builders,
        capacity: snapshot.builderBaseBuilderCount,
        limit: 2,
      ),
    };
  }

  List<Map<String, dynamic>> _boostPayload(
    UpgradeTrackerSnapshot snapshot, {
    required DateTime now,
  }) {
    final boosts = snapshot.boosts;
    Map<String, dynamic> timed(
      String kind,
      String name,
      int rawSeconds,
      String imageUrl,
    ) {
      final remaining = snapshot.remainingCapturedSeconds(rawSeconds);
      return {
        'kind': kind,
        'label': name,
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
          'Builder Potion',
          boosts.builderConsumableSeconds,
          ImageAssets.builderPotion,
        ),
      if (snapshot.remainingCapturedSeconds(boosts.labConsumableSeconds) > 0)
        timed(
          'researchPotion',
          'Research Potion',
          boosts.labConsumableSeconds,
          ImageAssets.researchPotion,
        ),
      if (snapshot.remainingCapturedSeconds(boosts.petConsumableSeconds) > 0)
        timed(
          'petPotion',
          'Pet Potion',
          boosts.petConsumableSeconds,
          ImageAssets.petPotion,
        ),
      if (snapshot.remainingCapturedSeconds(boosts.clockTowerBoostSeconds) > 0)
        timed(
          'clockTower',
          'Clock Tower',
          boosts.clockTowerBoostSeconds,
          ImageAssets.clockTowerPotion,
        ),
      if (snapshot.remainingCapturedSeconds(boosts.builderBoostSeconds) > 0)
        timed(
          'townHallBuilder',
          'Town Hall builder boost',
          boosts.builderBoostSeconds,
          ImageAssets.townHall(snapshot.townHallLevel),
        ),
      if (snapshot.remainingCapturedSeconds(boosts.labBoostSeconds) > 0)
        timed(
          'townHallLab',
          'Town Hall lab boost',
          boosts.labBoostSeconds,
          ImageAssets.townHall(snapshot.townHallLevel),
        ),
      if (boosts.builderCostReductionPercent > 0)
        {
          'kind': 'builderPerk',
          'label': '${boosts.builderCostReductionPercent}% builder cost perk',
        },
      if (boosts.builderTimeReductionPercent > 0)
        {
          'kind': 'builderPerk',
          'label': '${boosts.builderTimeReductionPercent}% builder time perk',
        },
      if (boosts.labCostReductionPercent > 0)
        {
          'kind': 'labPerk',
          'label': '${boosts.labCostReductionPercent}% lab cost perk',
        },
      if (boosts.labTimeReductionPercent > 0)
        {
          'kind': 'labPerk',
          'label': '${boosts.labTimeReductionPercent}% lab time perk',
        },
    ];
  }

  List<Map<String, dynamic>> _helperPayload(
    UpgradeTrackerSnapshot snapshot, {
    required DateTime now,
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
            'name': helper.name,
            'imageUrl': helper.imageUrl,
            'status': assigned != null
                ? 'Helping'
                : cooldown > 0
                ? 'Ready in'
                : 'Ready',
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
